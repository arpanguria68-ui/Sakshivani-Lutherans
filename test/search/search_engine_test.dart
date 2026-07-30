import 'package:flutter_test/flutter_test.dart';
import 'package:sakshi_vani/data/search/search_engine.dart';
import 'package:sakshi_vani/data/search/text_utils.dart';

// Fields: [title, lyrics]
SearchEngine<String> _engine(List<List<String>> docs) {
  return SearchEngine<String>.build(
    docs
        .asMap()
        .entries
        .map((e) => SearchDoc<String>('doc${e.key}', e.value))
        .toList(),
    const <SearchField>[SearchField('title', 5.0), SearchField('lyrics', 1.0)],
  );
}

void main() {
  group('BM25F field weighting', () {
    test('title match ranks above lyrics-only match', () {
      final engine = _engine(<List<String>>[
        <String>['यीशु मेरा उद्धारकर्ता', 'हे प्रभु मुझे थाम ले'], // title has यीशु
        <String>['आराधना गीत', 'यीशु यीशु यीशु नाम में शक्ति'], // lyrics has यीशु x3
      ]);
      final hits = engine.search('यीशु');
      expect(hits.isNotEmpty, true);
      expect(hits.first.ref, 'doc0', reason: 'title hit should win over lyric hits');
    });
  });

  group('Hindi phonetic folding', () {
    test('sibilant variant श matches स-indexed word', () {
      // Index uses शांति (with श); query uses सांति (with स).
      final engine = _engine(<List<String>>[
        <String>['शांति का गीत', 'मन में शांति'],
        <String>['क्रोध', 'अशांत मन'],
      ]);
      final hits = engine.search('सांति');
      expect(hits.isNotEmpty, true);
      expect(hits.first.ref, 'doc0');
    });

    test('phoneticFold collapses long/short and sibilants', () {
      expect(TextUtils.phoneticFold('शांति'), TextUtils.phoneticFold('सांति'));
      expect(TextUtils.phoneticFold('यीशू'), TextUtils.phoneticFold('यिशु'));
    });
  });

  group('Transliteration query expansion', () {
    test('roman "yeeshu" finds Devanagari यीशु', () {
      final engine = _engine(<List<String>>[
        <String>['यीशु मसीह', 'महिमा हो'],
        <String>['भजन', 'धन्यवाद'],
      ]);
      final hits = engine.search('yeeshu');
      expect(hits.isNotEmpty, true);
      expect(hits.first.ref, 'doc0');
    });
  });

  group('Synonym expansion', () {
    test('query प्रभु surfaces a यीशु-only document', () {
      final engine = _engine(<List<String>>[
        <String>['यीशु राजा', 'यीशु का नाम ऊँचा'],
        <String>['संसार', 'दुनिया की बातें'],
      ]);
      final hits = engine.search('प्रभु');
      expect(hits.isNotEmpty, true);
      expect(hits.first.ref, 'doc0');
    });
  });

  group('Typo tolerance', () {
    test('misspelling within edit distance still matches', () {
      final engine = _engine(<List<String>>[
        <String>['aaradhana', 'praise song'],
        <String>['random', 'other text'],
      ]);
      final hits = engine.search('aaradhna'); // dropped an 'a'
      expect(hits.isNotEmpty, true);
      expect(hits.first.ref, 'doc0');
    });
  });

  group('Edge cases', () {
    test('empty query returns nothing', () {
      final engine = _engine(<List<String>>[
        <String>['title', 'body'],
      ]);
      expect(engine.search('').isEmpty, true);
      expect(engine.search('   ').isEmpty, true);
    });

    test('no match returns empty list', () {
      final engine = _engine(<List<String>>[
        <String>['यीशु', 'मसीह'],
      ]);
      expect(engine.search('zxqwvb').isEmpty, true);
    });
  });
}
