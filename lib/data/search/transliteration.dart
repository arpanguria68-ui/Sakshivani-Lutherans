/// Roman -> Devanagari transliteration for query expansion.
///
/// Lets an English-keyboard user find Hindi hymns/verses by typing e.g.
/// "yeeshu", "prabhu", "aatma". Two layers:
///  1. A curated dictionary of frequent worship terms (highest quality).
///  2. A lightweight syllabic mapper as a fallback for anything else.
///
/// Output is a *candidate* Devanagari spelling used only to widen the search;
/// it does not need to be orthographically perfect.
library;

class Transliteration {
  const Transliteration._();

  /// High-frequency worship vocabulary. Keys are lower-cased roman forms;
  /// values are Devanagari. Multiple roman spellings map to the same word.
  static const Map<String, String> dictionary = <String, String>{
    'yeeshu': 'यीशु', 'yeshu': 'यीशु', 'yishu': 'यीशु', 'jesus': 'यीशु',
    'prabhu': 'प्रभु', 'parmeshwar': 'परमेश्वर',
    'parameshwar': 'परमेश्वर', 'ishwar': 'ईश्वर', 'god': 'परमेश्वर',
    'masih': 'मसीह', 'maseeh': 'मसीह', 'christ': 'मसीह',
    'aatma': 'आत्मा', 'atma': 'आत्मा', 'pavitra': 'पवित्र', 'pavitraatma': 'पवित्रआत्मा',
    'vachan': 'वचन', 'vakya': 'वाक्य', 'baibil': 'बाइबिल', 'bible': 'बाइबिल',
    'geet': 'गीत', 'bhajan': 'भजन', 'stuti': 'स्तुति', 'aaradhana': 'आराधना',
    'aradhana': 'आराधना', 'mahima': 'महिमा', 'dhanyavad': 'धन्यवाद',
    'dhanyawad': 'धन्यवाद', 'prarthana': 'प्रार्थना', 'prathna': 'प्रार्थना',
    'jeevan': 'जीवन', 'jivan': 'जीवन', 'prem': 'प्रेम', 'pyar': 'प्यार',
    'shanti': 'शांति', 'anand': 'आनंद', 'aashish': 'आशीष', 'ashish': 'आशीष',
    'kripa': 'कृपा', 'daya': 'दया', 'paap': 'पाप', 'pap': 'पाप',
    'uddhar': 'उद्धार', 'mukti': 'मुक्ति', 'swarg': 'स्वर्ग',
    'raja': 'राजा', 'prabhuta': 'प्रभुता', 'vishwas': 'विश्वास', 'viswas': 'विश्वास',
    'aasha': 'आशा', 'asha': 'आशा', 'jyoti': 'ज्योति', 'prakash': 'प्रकाश',
    'charwaha': 'चरवाहा', 'mendha': 'मेंढा', 'krus': 'क्रूस', 'kruz': 'क्रूस',
    'cross': 'क्रूस', 'lahu': 'लहू', 'rakt': 'रक्त', 'balidan': 'बलिदान',
    'punarutthan': 'पुनरुत्थान', 'jaymay': 'जयमय', 'halleluya': 'हल्लिलूयाह',
    'hallelujah': 'हल्लिलूयाह', 'aamin': 'आमीन', 'amen': 'आमीन',
    'pita': 'पिता', 'putra': 'पुत्र', 'nam': 'नाम', 'naam': 'नाम',
    'raksha': 'रक्षा', 'shakti': 'शक्ति', 'sacchai': 'सच्चाई', 'satya': 'सत्य',
    'dua': 'दुआ', 'aaradhna': 'आराधना', 'yeshua': 'यीशु',
  };

  static const Map<String, String> _twoChar = <String, String>{
    'kh': 'ख', 'gh': 'घ', 'ch': 'च', 'jh': 'झ', 'th': 'थ', 'dh': 'ध',
    'ph': 'फ', 'bh': 'भ', 'sh': 'श', 'ng': 'ंग', 'ny': 'ञ',
    'aa': 'ा', 'ee': 'ी', 'ii': 'ी', 'oo': 'ू', 'uu': 'ू', 'ai': 'ै',
    'au': 'ौ', 'ri': 'ृ',
  };

  // Independent vowels (word-initial) vs. matras (after a consonant).
  static const Map<String, String> _vowelIndependent = <String, String>{
    'a': 'अ', 'aa': 'आ', 'i': 'इ', 'ee': 'ई', 'ii': 'ई', 'u': 'उ',
    'oo': 'ऊ', 'uu': 'ऊ', 'e': 'ए', 'ai': 'ऐ', 'o': 'ओ', 'au': 'औ',
  };
  static const Map<String, String> _vowelMatra = <String, String>{
    'a': '', 'aa': 'ा', 'i': 'ि', 'ee': 'ी', 'ii': 'ी', 'u': 'ु',
    'oo': 'ू', 'uu': 'ू', 'e': 'े', 'ai': 'ै', 'o': 'ो', 'au': 'ौ',
  };

  static const Map<String, String> _consonant = <String, String>{
    'k': 'क', 'g': 'ग', 'c': 'च', 'j': 'ज', 't': 'त', 'd': 'द',
    'n': 'न', 'p': 'प', 'b': 'ब', 'm': 'म', 'y': 'य', 'r': 'र',
    'l': 'ल', 'v': 'व', 'w': 'व', 's': 'स', 'h': 'ह', 'f': 'फ',
    'z': 'ज', 'q': 'क', 'x': 'क्स',
  };

  static bool _isVowelStart(String s, int i) {
    if (i >= s.length) return false;
    const String v = 'aeiou';
    return v.contains(s[i]);
  }

  /// Transliterate a single roman token to a candidate Devanagari spelling.
  /// Returns null if the input already contains Devanagari or is empty.
  static String? transliterateToken(String token) {
    final String t = token.toLowerCase().trim();
    if (t.isEmpty) return null;
    // Skip if it's already Devanagari.
    for (final int r in t.runes) {
      if (r >= 0x0900 && r <= 0x097F) return null;
    }
    final String? dict = dictionary[t];
    if (dict != null) return dict;

    final StringBuffer sb = StringBuffer();
    int i = 0;
    bool prevWasConsonant = false;
    while (i < t.length) {
      // Try two-char consonant/vowel digraphs first.
      final String? two = i + 1 < t.length ? _twoChar[t.substring(i, i + 2)] : null;
      final String pair = i + 1 < t.length ? t.substring(i, i + 2) : '';

      // Vowel handling (digraph then single).
      final bool pairIsVowel = _vowelIndependent.containsKey(pair);
      if (pairIsVowel) {
        sb.write(prevWasConsonant ? _vowelMatra[pair] : _vowelIndependent[pair]);
        prevWasConsonant = false;
        i += 2;
        continue;
      }
      if (two != null && !_isVowelStart(t, i)) {
        // consonant digraph (kh, gh, sh, ...)
        if (prevWasConsonant) sb.write('्');
        sb.write(two);
        prevWasConsonant = true;
        i += 2;
        continue;
      }

      final String ch = t[i];
      final String? vowel = _vowelIndependent.containsKey(ch) ? ch : null;
      if (vowel != null) {
        sb.write(prevWasConsonant ? _vowelMatra[vowel] : _vowelIndependent[vowel]);
        prevWasConsonant = false;
        i += 1;
        continue;
      }
      final String? cons = _consonant[ch];
      if (cons != null) {
        if (prevWasConsonant) sb.write('्');
        sb.write(cons);
        prevWasConsonant = true;
        i += 1;
        continue;
      }
      // Unknown char: skip.
      i += 1;
    }
    final String out = sb.toString();
    return out.isEmpty ? null : out;
  }
}
