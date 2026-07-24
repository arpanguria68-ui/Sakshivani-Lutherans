import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../core/constants/app_constants.dart';
import '../models/bible_verse.dart';

class BibleRepository {
  final Map<String, String> _assetCache = <String, String>{};
  final Map<String, Map<String, dynamic>> _cache = <String, Map<String, dynamic>>{};

  static const List<String> _hindiBooks = <String>[
    'उत्पत्ति',
    'निर्गमन',
    'लैव्यवस्था',
    'गिनती',
    'व्यवस्थाविवरण',
    'यहोशू',
    'न्यायियों',
    'रूत',
    '1 शमूएल',
    '2 शमूएल',
    '1 राजा',
    '2 राजा',
    '1 इतिहास',
    '2 इतिहास',
    'एज्रा',
    'नहेमायाह',
    'एस्तेर',
    'अय्यूब',
    'भजन संहिता',
    'नीतिवचन',
    'सभोपदेशक',
    'श्रेष्ठगीत',
    'यशायाह',
    'यिर्मयाह',
    'विलापगीत',
    'यहेजकेल',
    'दानिय्येल',
    'होशे',
    'योएल',
    'आमोस',
    'ओबद्दाह',
    'योना',
    'मीका',
    'नहूम',
    'हबक्कूक',
    'सपन्याह',
    'हाग्गै',
    'जकर्याह',
    'मलाकी',
    'मत्ती',
    'मरकुस',
    'लूका',
    'यूहन्ना',
    'प्रेरितों के काम',
    'रोमियो',
    '1 कुरिन्थियों',
    '2 कुरिन्थियों',
    'गलातियों',
    'इफिसियों',
    'फिलिप्पियों',
    'कुलुस्सियों',
    '1 थिस्सलुनीकियों',
    '2 थिस्सलुनीकियों',
    '1 तीमुथियुस',
    '2 तीमुथियुस',
    'तीतुस',
    'फिलेमोन',
    'इब्रानियों',
    'याकूब',
    '1 पतरस',
    '2 पतरस',
    '1 यूहन्ना',
    '2 यूहन्ना',
    '3 यूहन्ना',
    'यहूदा',
    'प्रकाशित वाक्य',
  ];

  static const List<String> _englishBooks = <String>[
    'Genesis',
    'Exodus',
    'Leviticus',
    'Numbers',
    'Deuteronomy',
    'Joshua',
    'Judges',
    'Ruth',
    '1 Samuel',
    '2 Samuel',
    '1 Kings',
    '2 Kings',
    '1 Chronicles',
    '2 Chronicles',
    'Ezra',
    'Nehemiah',
    'Esther',
    'Job',
    'Psalms',
    'Proverbs',
    'Ecclesiastes',
    'Song of Solomon',
    'Isaiah',
    'Jeremiah',
    'Lamentations',
    'Ezekiel',
    'Daniel',
    'Hosea',
    'Joel',
    'Amos',
    'Obadiah',
    'Jonah',
    'Micah',
    'Nahum',
    'Habakkuk',
    'Zephaniah',
    'Haggai',
    'Zechariah',
    'Malachi',
    'Matthew',
    'Mark',
    'Luke',
    'John',
    'Acts',
    'Romans',
    '1 Corinthians',
    '2 Corinthians',
    'Galatians',
    'Ephesians',
    'Philippians',
    'Colossians',
    '1 Thessalonians',
    '2 Thessalonians',
    '1 Timothy',
    '2 Timothy',
    'Titus',
    'Philemon',
    'Hebrews',
    'James',
    '1 Peter',
    '2 Peter',
    '1 John',
    '2 John',
    '3 John',
    'Jude',
    'Revelation',
  ];

  Future<List<String>> getBooks(String language) async {
    await _ensureLoaded(language);
    return language == 'en' ? _englishBooks : _hindiBooks;
  }

  Future<int> getChapterCount({required String language, required int bookIndex}) async {
    final Map<String, dynamic> map = await _ensureLoaded(language);
    final List<dynamic> books = map['Book'] as List<dynamic>;
    if (bookIndex < 0 || bookIndex >= books.length) {
      return 0;
    }
    final Map<String, dynamic> book = (books[bookIndex] as Map<dynamic, dynamic>).cast<String, dynamic>();
    final List<dynamic> chapters = book['Chapter'] as List<dynamic>;
    return chapters.length;
  }

  Future<List<BibleVerse>> getVerses({
    required String language,
    required int bookIndex,
    required int chapterIndex,
  }) async {
    final Map<String, dynamic> map = await _ensureLoaded(language);
    final List<dynamic> books = map['Book'] as List<dynamic>;
    if (bookIndex < 0 || bookIndex >= books.length) {
      return const <BibleVerse>[];
    }
    final Map<String, dynamic> book = (books[bookIndex] as Map<dynamic, dynamic>).cast<String, dynamic>();
    final List<dynamic> chapters = book['Chapter'] as List<dynamic>;
    if (chapterIndex < 0 || chapterIndex >= chapters.length) {
      return const <BibleVerse>[];
    }
    final Map<String, dynamic> chapter =
        (chapters[chapterIndex] as Map<dynamic, dynamic>).cast<String, dynamic>();
    final List<dynamic> verses = chapter['Verse'] as List<dynamic>;
    final List<String> names = language == 'en' ? _englishBooks : _hindiBooks;

    return List<BibleVerse>.generate(verses.length, (int index) {
      final Map<String, dynamic> verse =
          (verses[index] as Map<dynamic, dynamic>).cast<String, dynamic>();
      final int verseNumber = index + 1;
      return BibleVerse(
        id: '$language-${bookIndex + 1}-${chapterIndex + 1}-$verseNumber',
        book: names[bookIndex],
        chapter: chapterIndex + 1,
        verse: verseNumber,
        text: verse['Verse'] as String? ?? '',
        language: language,
      );
    });
  }

  Future<BibleVerse?> getVerseByReference({
    required String language,
    required int book,
    required int chapter,
    required int verse,
  }) async {
    final List<BibleVerse> verses = await getVerses(
      language: language,
      bookIndex: book - 1,
      chapterIndex: chapter - 1,
    );
    if (verse < 1 || verse > verses.length) {
      return null;
    }
    return verses[verse - 1];
  }

  /// Flatten every verse of [language] into a single list (used to build the
  /// in-memory search index). Cached parse means this is a one-time O(verses).
  Future<List<BibleVerse>> getAllVerses(String language) async {
    final Map<String, dynamic> map = await _ensureLoaded(language);
    final List<dynamic> books = map['Book'] as List<dynamic>;
    final List<String> names = language == 'en' ? _englishBooks : _hindiBooks;
    final List<BibleVerse> result = <BibleVerse>[];

    for (int b = 0; b < books.length; b++) {
      final Map<String, dynamic> book = (books[b] as Map<dynamic, dynamic>).cast<String, dynamic>();
      final List<dynamic> chapters = book['Chapter'] as List<dynamic>;
      for (int c = 0; c < chapters.length; c++) {
        final Map<String, dynamic> chapter =
            (chapters[c] as Map<dynamic, dynamic>).cast<String, dynamic>();
        final List<dynamic> verses = chapter['Verse'] as List<dynamic>;
        for (int v = 0; v < verses.length; v++) {
          final Map<String, dynamic> verse =
              (verses[v] as Map<dynamic, dynamic>).cast<String, dynamic>();
          result.add(BibleVerse(
            id: '$language-${b + 1}-${c + 1}-${v + 1}',
            book: names[b],
            chapter: c + 1,
            verse: v + 1,
            text: verse['Verse'] as String? ?? '',
            language: language,
          ));
        }
      }
    }
    return result;
  }

  Future<List<BibleVerse>> search({
    required String language,
    required String query,
    int limit = 80,
  }) async {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return const <BibleVerse>[];
    }

    final Map<String, dynamic> map = await _ensureLoaded(language);
    final List<dynamic> books = map['Book'] as List<dynamic>;
    final List<String> names = language == 'en' ? _englishBooks : _hindiBooks;
    final List<BibleVerse> result = <BibleVerse>[];

    for (int b = 0; b < books.length; b++) {
      final Map<String, dynamic> book = (books[b] as Map<dynamic, dynamic>).cast<String, dynamic>();
      final List<dynamic> chapters = book['Chapter'] as List<dynamic>;
      for (int c = 0; c < chapters.length; c++) {
        final Map<String, dynamic> chapter =
            (chapters[c] as Map<dynamic, dynamic>).cast<String, dynamic>();
        final List<dynamic> verses = chapter['Verse'] as List<dynamic>;
        for (int v = 0; v < verses.length; v++) {
          final Map<String, dynamic> verse =
              (verses[v] as Map<dynamic, dynamic>).cast<String, dynamic>();
          final String text = verse['Verse'] as String? ?? '';
          if (text.toLowerCase().contains(needle)) {
            result.add(BibleVerse(
              id: '$language-${b + 1}-${c + 1}-${v + 1}',
              book: names[b],
              chapter: c + 1,
              verse: v + 1,
              text: text,
              language: language,
            ));
            if (result.length >= limit) {
              return result;
            }
          }
        }
      }
    }

    return result;
  }

  Future<BibleVerse?> getDailyVerse({required String language}) async {
    final DateTime now = DateTime.now();
    final int dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final int bookIndex = (dayOfYear * 3) % 66;
    final int chapterCount = await getChapterCount(language: language, bookIndex: bookIndex);
    final int chapterIndex = (dayOfYear * 7) % chapterCount;
    final List<BibleVerse> verses =
        await getVerses(language: language, bookIndex: bookIndex, chapterIndex: chapterIndex);
    if (verses.isEmpty) {
      return null;
    }
    final int verseIndex = (dayOfYear * 11) % verses.length;
    return verses[verseIndex];
  }

  Future<Map<String, dynamic>> _ensureLoaded(String language) async {
    final Map<String, dynamic>? cached = _cache[language];
    if (cached != null) {
      return cached;
    }

    final String raw = await _loadBibleJson(language);
    final Map<String, dynamic> map = json.decode(raw) as Map<String, dynamic>;
    _cache[language] = map;
    return map;
  }

  Future<String> _loadBibleJson(String language) async {
    final String? cached = _assetCache[language];
    if (cached != null) {
      return cached;
    }

    final String entryPath =
        language == 'en' ? AppConstants.englishBibleEntryPath : AppConstants.hindiBibleEntryPath;

    String? raw;
    try {
      raw = await rootBundle.loadString(entryPath);
    } catch (_) {
      raw = null;
    }

    if (raw == null || raw.isEmpty) {
      raw = await _extractFromZip(entryPath);
    }

    _assetCache[language] = raw;
    return raw;
  }

  Future<String> _extractFromZip(String entryPath) async {
    final ByteData data = await rootBundle.load(AppConstants.bibleZipAssetPath);
    final Uint8List bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    const List<int> signature = <int>[0x50, 0x4B, 0x03, 0x04];
    final List<int> sig = signature;

    for (int i = 0; i <= bytes.length - sig.length; i++) {
      if (bytes[i] != sig[0] || bytes[i + 1] != sig[1] || bytes[i + 2] != sig[2] || bytes[i + 3] != sig[3]) {
        continue;
      }

      if (i + 30 > bytes.length) {
        continue;
      }

      final int compression = bytes[i + 8] | (bytes[i + 9] << 8);
      final int compressedSize =
          bytes[i + 18] | (bytes[i + 19] << 8) | (bytes[i + 20] << 16) | (bytes[i + 21] << 24);
      final int fileNameLength = bytes[i + 26] | (bytes[i + 27] << 8);
      final int extraLength = bytes[i + 28] | (bytes[i + 29] << 8);

      final int nameStart = i + 30;
      final int nameEnd = nameStart + fileNameLength;
      if (nameEnd > bytes.length) {
        continue;
      }

      final String name = utf8.decode(bytes.sublist(nameStart, nameEnd), allowMalformed: true);
      final int dataStart = nameEnd + extraLength;
      final int dataEnd = dataStart + compressedSize;
      if (dataEnd > bytes.length) {
        continue;
      }

      if (name != entryPath) {
        continue;
      }

      if (compression == 0) {
        return utf8.decode(bytes.sublist(dataStart, dataEnd), allowMalformed: true);
      }
      if (compression == 8) {
        final List<int> compressed = bytes.sublist(dataStart, dataEnd);
        final List<int> decoded = ZLibDecoder(raw: true).convert(compressed);
        return utf8.decode(decoded, allowMalformed: true);
      }
      throw StateError('Unsupported ZIP compression $compression for $entryPath.');
    }

    throw StateError('Could not locate $entryPath in ${AppConstants.bibleZipAssetPath}');
  }
}
