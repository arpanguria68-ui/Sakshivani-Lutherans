/// Text normalization, tokenization, and Hindi phonetic folding for search.
///
/// Two token streams are produced per field:
///  - "exact"    : NFC-normalized, lower-cased, punctuation-stripped words.
///  - "phonetic" : a folded consonant/vowel skeleton that makes near-homophones
///                 collide (sibilants, retroflex/dental, vowel length, nasals).
///
/// The phonetic stream is a *secondary* signal (lower weight) so that genuine
/// spellings still rank above fuzzy homophone matches.
library;

class TextUtils {
  const TextUtils._();

  /// A word is a run of ASCII alphanumerics or Devanagari code points; anything
  /// else (whitespace, danda, punctuation, symbols) separates words. Latin
  /// diacritics are folded to ASCII by [normalize] before tokenizing.
  static final RegExp _nonWord = RegExp(r'[^0-9a-zA-Zऀ-ॿ]+');

  /// Latin diacritic folding (é -> e, etc.).
  static const Map<String, String> _latinFold = <String, String>{
    'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', 'ã': 'a', 'å': 'a',
    'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e',
    'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i',
    'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', 'õ': 'o',
    'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u',
    'ñ': 'n', 'ç': 'c',
  };

  /// Normalize a whole string: lower-case, fold Latin diacritics.
  static String normalize(String input) {
    final StringBuffer sb = StringBuffer();
    for (final int rune in input.toLowerCase().runes) {
      final String ch = String.fromCharCode(rune);
      sb.write(_latinFold[ch] ?? ch);
    }
    return sb.toString();
  }

  /// Split normalized text into word tokens (empty tokens removed).
  static List<String> tokenize(String input) {
    final String norm = normalize(input);
    return norm
        .split(_nonWord)
        .where((String t) => t.isNotEmpty)
        .toList(growable: false);
  }

  /// True if the token contains any Devanagari code point.
  static bool isDevanagari(String token) {
    for (final int r in token.runes) {
      if (r >= 0x0900 && r <= 0x097F) {
        return true;
      }
    }
    return false;
  }

  // ─── Hindi phonetic folding ────────────────────────────────────────────────

  /// Nukta-composed letters folded to their base form.
  static const Map<int, int> _nuktaFold = <int, int>{
    0x0958: 0x0915, // क़ -> क
    0x0959: 0x0916, // ख़ -> ख
    0x095A: 0x0917, // ग़ -> ग
    0x095B: 0x091C, // ज़ -> ज
    0x095C: 0x0921, // ड़ -> ड
    0x095D: 0x0922, // ढ़ -> ढ
    0x095E: 0x092B, // फ़ -> फ
    0x095F: 0x092F, // य़ -> य
  };

  /// Consonant/vowel folds that collapse common Hindi near-homophones.
  static const Map<int, int> _phoneticFold = <int, int>{
    // Sibilants -> स
    0x0936: 0x0938, // श -> स
    0x0937: 0x0938, // ष -> स
    // Retroflex nasal/liquids -> dental equivalents
    0x0923: 0x0928, // ण -> न
    0x0933: 0x0932, // ळ -> ल
    0x0931: 0x0930, // ऱ -> र
    // Independent long vowels -> short
    0x0906: 0x0905, // आ -> अ
    0x0908: 0x0907, // ई -> इ
    0x090A: 0x0909, // ऊ -> उ
    0x0910: 0x090F, // ऐ -> ए
    0x0914: 0x0913, // औ -> ओ
    // Dependent vowel signs (matras): long -> short
    0x0940: 0x093F, // ी -> ि
    0x0942: 0x0941, // ू -> ु
    0x0948: 0x0947, // ै -> े
    0x094C: 0x094B, // ौ -> ो
  };

  /// Combining marks dropped for the phonetic key (nasalization, visarga).
  static const Set<int> _phoneticDrop = <int>{
    0x0900, // ऀ
    0x0901, // ँ chandrabindu
    0x0902, // ं anusvara
    0x0903, // ः visarga
    0x093C, // ़ nukta (bare)
  };

  /// Produce a phonetic-folded skeleton of a single token.
  static String phoneticFold(String token) {
    final String norm = normalize(token);
    final StringBuffer sb = StringBuffer();
    for (final int r in norm.runes) {
      int c = _nuktaFold[r] ?? r;
      if (_phoneticDrop.contains(c)) {
        continue;
      }
      c = _phoneticFold[c] ?? c;
      sb.writeCharCode(c);
    }
    return sb.toString();
  }

  /// Bounded Levenshtein edit distance; returns [maxDistance]+1 if it exceeds it.
  static int boundedEditDistance(String a, String b, int maxDistance) {
    final int la = a.length;
    final int lb = b.length;
    if ((la - lb).abs() > maxDistance) {
      return maxDistance + 1;
    }
    if (la == 0) return lb;
    if (lb == 0) return la;

    List<int> prev = List<int>.generate(lb + 1, (int i) => i);
    List<int> curr = List<int>.filled(lb + 1, 0);

    for (int i = 1; i <= la; i++) {
      curr[0] = i;
      int rowMin = curr[0];
      final int ca = a.codeUnitAt(i - 1);
      for (int j = 1; j <= lb; j++) {
        final int cost = ca == b.codeUnitAt(j - 1) ? 0 : 1;
        int v = prev[j] + 1;
        final int del = curr[j - 1] + 1;
        final int sub = prev[j - 1] + cost;
        if (del < v) v = del;
        if (sub < v) v = sub;
        curr[j] = v;
        if (v < rowMin) rowMin = v;
      }
      if (rowMin > maxDistance) {
        return maxDistance + 1;
      }
      final List<int> tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[lb];
  }
}
