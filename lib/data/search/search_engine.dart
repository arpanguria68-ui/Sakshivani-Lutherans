/// A small, dependency-free BM25F search engine with Hindi-aware fuzzy layers.
///
/// Design (see PRODUCTION_PLAN.md §3):
///  - BM25F ranking across weighted fields (e.g. title >> lyrics).
///  - Exact token stream + phonetic-folded stream (near-homophone recall).
///  - Query expansion: roman->Devanagari transliteration + synonym groups.
///  - Typo tolerance: bounded edit-distance fallback over the vocabulary.
///
/// Everything runs in-memory; corpora here (353 hymns, ~31k verses) are tiny.
library;

import 'dart:math' as math;

import 'synonyms.dart';
import 'text_utils.dart';
import 'transliteration.dart';

/// One weighted field of a document (name is for reference/highlighting only).
class SearchField {
  const SearchField(this.name, this.weight);
  final String name;
  final double weight;
}

/// A document to index. [fields] must align by index with the engine's fields.
class SearchDoc<T> {
  const SearchDoc(this.ref, this.fields);
  final T ref;
  final List<String> fields;
}

/// A ranked result. [matchedTerms] are normalized terms for UI highlighting.
class SearchHit<T> {
  const SearchHit(this.ref, this.score, this.matchedTerms);
  final T ref;
  final double score;
  final Set<String> matchedTerms;
}

class _Posting {
  _Posting(this.docId, this.fieldId, this.tf);
  final int docId;
  final int fieldId;
  final int tf;
}

class _Variant {
  const _Variant(this.term, this.weight, this.phonetic);
  final String term;
  final double weight;
  final bool phonetic;
}

class SearchEngine<T> {
  SearchEngine._(
    this._docs,
    this._fieldWeights,
    this._exact,
    this._exactDf,
    this._phonetic,
    this._phoneticDf,
    this._fieldLen,
    this._avgFieldLen,
    this._vocab,
  );

  static const double _k1 = 1.2;
  static const double _b = 0.75;

  final List<SearchDoc<T>> _docs;
  final List<double> _fieldWeights;
  final Map<String, List<_Posting>> _exact;
  final Map<String, int> _exactDf;
  final Map<String, List<_Posting>> _phonetic;
  final Map<String, int> _phoneticDf;
  final List<List<int>> _fieldLen; // [docId][fieldId]
  final List<double> _avgFieldLen; // [fieldId]
  final List<String> _vocab; // distinct exact terms, for typo fallback

  int get length => _docs.length;

  /// Build an index from [docs] with per-field [fields] weights.
  factory SearchEngine.build(List<SearchDoc<T>> docs, List<SearchField> fields) {
    final int nFields = fields.length;
    final List<double> weights =
        fields.map((SearchField f) => f.weight).toList(growable: false);

    final Map<String, List<_Posting>> exact = <String, List<_Posting>>{};
    final Map<String, List<_Posting>> phonetic = <String, List<_Posting>>{};
    final List<List<int>> fieldLen =
        List<List<int>>.generate(docs.length, (_) => List<int>.filled(nFields, 0));
    final List<int> totalLen = List<int>.filled(nFields, 0);

    // Per-doc df tracking (a term counts once per doc).
    final Map<String, int> exactDf = <String, int>{};
    final Map<String, int> phoneticDf = <String, int>{};

    for (int docId = 0; docId < docs.length; docId++) {
      final SearchDoc<T> doc = docs[docId];
      final Set<String> docExactTerms = <String>{};
      final Set<String> docPhoneticTerms = <String>{};

      for (int fieldId = 0; fieldId < nFields; fieldId++) {
        final String text = fieldId < doc.fields.length ? doc.fields[fieldId] : '';
        final List<String> tokens = TextUtils.tokenize(text);
        fieldLen[docId][fieldId] = tokens.length;
        totalLen[fieldId] += tokens.length;

        final Map<String, int> exactTf = <String, int>{};
        final Map<String, int> phonTf = <String, int>{};
        for (final String tok in tokens) {
          exactTf[tok] = (exactTf[tok] ?? 0) + 1;
          final String ph = TextUtils.phoneticFold(tok);
          if (ph.isNotEmpty) phonTf[ph] = (phonTf[ph] ?? 0) + 1;
        }
        exactTf.forEach((String term, int tf) {
          (exact[term] ??= <_Posting>[]).add(_Posting(docId, fieldId, tf));
          docExactTerms.add(term);
        });
        phonTf.forEach((String term, int tf) {
          (phonetic[term] ??= <_Posting>[]).add(_Posting(docId, fieldId, tf));
          docPhoneticTerms.add(term);
        });
      }
      for (final String t in docExactTerms) {
        exactDf[t] = (exactDf[t] ?? 0) + 1;
      }
      for (final String t in docPhoneticTerms) {
        phoneticDf[t] = (phoneticDf[t] ?? 0) + 1;
      }
    }

    final List<double> avg = List<double>.generate(
      nFields,
      (int f) => docs.isEmpty ? 0.0 : totalLen[f] / docs.length,
    );

    return SearchEngine<T>._(
      docs,
      weights,
      exact,
      exactDf,
      phonetic,
      phoneticDf,
      fieldLen,
      avg,
      exact.keys.toList(growable: false),
    );
  }

  double _idf(int df) {
    final int n = _docs.length;
    final double ratio = ((n - df + 0.5) / (df + 0.5)) + 1;
    return math.log(ratio < 1e-9 ? 1e-9 : ratio);
  }

  /// Rank documents for [query]. Returns up to [limit] hits, best first.
  List<SearchHit<T>> search(String query, {int limit = 50}) {
    final List<String> queryTokens = TextUtils.tokenize(query);
    if (queryTokens.isEmpty) return const [];

    final List<_Variant> variants = _buildVariants(queryTokens);
    if (variants.isEmpty) return const [];

    // docId -> accumulated score; docId -> matched display terms.
    final Map<int, double> scores = <int, double>{};
    final Map<int, Set<String>> matched = <int, Set<String>>{};

    // Dedup variants keeping the highest weight per (stream, term).
    final Map<String, _Variant> best = <String, _Variant>{};
    for (final _Variant v in variants) {
      final String key = '${v.phonetic ? 'p' : 'e'}:${v.term}';
      final _Variant? cur = best[key];
      if (cur == null || v.weight > cur.weight) best[key] = v;
    }

    for (final _Variant v in best.values) {
      final Map<String, List<_Posting>> postings = v.phonetic ? _phonetic : _exact;
      final Map<String, int> dfMap = v.phonetic ? _phoneticDf : _exactDf;
      final List<_Posting>? plist = postings[v.term];
      if (plist == null) continue;
      final int df = dfMap[v.term] ?? plist.length;
      final double idf = _idf(df);

      // Accumulate BM25F tilde-tf per doc for this term (summed over fields).
      final Map<int, double> tildeTf = <int, double>{};
      for (final _Posting p in plist) {
        final double avg = _avgFieldLen[p.fieldId] == 0 ? 1.0 : _avgFieldLen[p.fieldId];
        final double norm = 1 - _b + _b * (_fieldLen[p.docId][p.fieldId] / avg);
        tildeTf[p.docId] =
            (tildeTf[p.docId] ?? 0) + _fieldWeights[p.fieldId] * p.tf / norm;
      }
      tildeTf.forEach((int docId, double v2) {
        final double contrib = v.weight * idf * (v2 / (_k1 + v2));
        scores[docId] = (scores[docId] ?? 0) + contrib;
        if (!v.phonetic) {
          (matched[docId] ??= <String>{}).add(v.term);
        }
      });
    }

    final List<int> docIds = scores.keys.toList(growable: false);
    docIds.sort((int a, int b) {
      final int c = scores[b]!.compareTo(scores[a]!);
      return c != 0 ? c : a.compareTo(b);
    });

    final int take = docIds.length < limit ? docIds.length : limit;
    return List<SearchHit<T>>.generate(take, (int i) {
      final int docId = docIds[i];
      return SearchHit<T>(
        _docs[docId].ref,
        scores[docId]!,
        matched[docId] ?? const <String>{},
      );
    });
  }

  /// Expand raw query tokens into weighted, streamed search variants.
  List<_Variant> _buildVariants(List<String> queryTokens) {
    final List<_Variant> out = <_Variant>[];
    for (final String tok in queryTokens) {
      // Exact + its phonetic fold.
      out.add(_Variant(tok, 1.0, false));
      final String ph = TextUtils.phoneticFold(tok);
      if (ph.isNotEmpty && ph != tok) out.add(_Variant(ph, 0.4, true));

      // Roman -> Devanagari transliteration.
      final String? tr = Transliteration.transliterateToken(tok);
      if (tr != null && tr != tok) {
        out.add(_Variant(tr, 0.9, false));
        final String trPh = TextUtils.phoneticFold(tr);
        if (trPh.isNotEmpty && trPh != tr) out.add(_Variant(trPh, 0.35, true));
      }

      // Synonyms (of the token and of its transliteration).
      for (final String syn in <String>[
        ...Synonyms.expand(tok),
        if (tr != null) ...Synonyms.expand(tr),
      ]) {
        out.add(_Variant(TextUtils.normalize(syn), 0.5, false));
      }

      // Typo tolerance: only if the exact token has no postings.
      if (!_exact.containsKey(tok) && tok.length >= 4) {
        final int maxD = tok.length >= 7 ? 2 : 1;
        String? bestTerm;
        int bestDist = maxD + 1;
        for (final String term in _vocab) {
          if ((term.length - tok.length).abs() > maxD) continue;
          final int d = TextUtils.boundedEditDistance(tok, term, maxD);
          if (d < bestDist) {
            bestDist = d;
            bestTerm = term;
            if (d == 1) break;
          }
        }
        if (bestTerm != null) {
          final double w = 0.6 * (1 - bestDist / (maxD + 1));
          out.add(_Variant(bestTerm, w, false));
        }
      }
    }
    return out;
  }
}
