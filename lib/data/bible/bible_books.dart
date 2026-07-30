/// Canonical 66-book Protestant Bible metadata: book names (Hindi + English)
/// and per-book chapter counts. Used by the reading-plan generator without
/// having to parse the full Bible JSON.
library;

class BibleBooks {
  const BibleBooks._();

  static const List<String> hindi = <String>[
    'उत्पत्ति', 'निर्गमन', 'लैव्यवस्था', 'गिनती', 'व्यवस्थाविवरण', 'यहोशू',
    'न्यायियों', 'रूत', '1 शमूएल', '2 शमूएल', '1 राजा', '2 राजा', '1 इतिहास',
    '2 इतिहास', 'एज्रा', 'नहेमायाह', 'एस्तेर', 'अय्यूब', 'भजन संहिता',
    'नीतिवचन', 'सभोपदेशक', 'श्रेष्ठगीत', 'यशायाह', 'यिर्मयाह', 'विलापगीत',
    'यहेजकेल', 'दानिय्येल', 'होशे', 'योएल', 'आमोस', 'ओबद्दाह', 'योना', 'मीका',
    'नहूम', 'हबक्कूक', 'सपन्याह', 'हाग्गै', 'जकर्याह', 'मलाकी', 'मत्ती',
    'मरकुस', 'लूका', 'यूहन्ना', 'प्रेरितों के काम', 'रोमियो', '1 कुरिन्थियों',
    '2 कुरिन्थियों', 'गलातियों', 'इफिसियों', 'फिलिप्पियों', 'कुलुस्सियों',
    '1 थिस्सलुनीकियों', '2 थिस्सलुनीकियों', '1 तीमुथियुस', '2 तीमुथियुस',
    'तीतुस', 'फिलेमोन', 'इब्रानियों', 'याकूब', '1 पतरस', '2 पतरस', '1 यूहन्ना',
    '2 यूहन्ना', '3 यूहन्ना', 'यहूदा', 'प्रकाशित वाक्य',
  ];

  static const List<String> english = <String>[
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy', 'Joshua',
    'Judges', 'Ruth', '1 Samuel', '2 Samuel', '1 Kings', '2 Kings',
    '1 Chronicles', '2 Chronicles', 'Ezra', 'Nehemiah', 'Esther', 'Job',
    'Psalms', 'Proverbs', 'Ecclesiastes', 'Song of Solomon', 'Isaiah',
    'Jeremiah', 'Lamentations', 'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
    'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk', 'Zephaniah', 'Haggai',
    'Zechariah', 'Malachi', 'Matthew', 'Mark', 'Luke', 'John', 'Acts',
    'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
    'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians',
    '1 Timothy', '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
    '1 Peter', '2 Peter', '1 John', '2 John', '3 John', 'Jude', 'Revelation',
  ];

  /// Chapters per book, aligned by index with [hindi] / [english].
  static const List<int> chapterCounts = <int>[
    50, 40, 27, 36, 34, 24, 21, 4, 31, 24, 22, 25, 29, 36, 10, 13, 10, 42, 150,
    31, 12, 8, 66, 52, 5, 48, 12, 14, 3, 9, 1, 4, 7, 3, 3, 3, 2, 14, 4, 28, 16,
    24, 21, 28, 16, 16, 13, 6, 6, 4, 4, 5, 3, 6, 4, 3, 1, 13, 5, 5, 3, 5, 1, 1,
    1, 22,
  ];

  /// First index (inclusive) of the New Testament (Matthew).
  static const int ntStartIndex = 39;

  static String name(int bookIndex, String language) {
    final List<String> names = language == 'en' ? english : hindi;
    if (bookIndex < 0 || bookIndex >= names.length) return '';
    return names[bookIndex];
  }
}
