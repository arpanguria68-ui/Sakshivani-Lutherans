/// Curated synonym groups for the Hindi worship domain.
///
/// This is the "semantic-lite" layer: when a query token belongs to a group,
/// the other members are added as lower-weighted OR-terms so that searching
/// "प्रभु" also surfaces hymns that say "यीशु" or "मसीह", etc.
///
/// Groups are bidirectional. Latin forms are included so roman queries expand
/// too (they are also transliterated separately).
library;

class Synonyms {
  const Synonyms._();

  /// Each inner list is a set of mutually-synonymous terms.
  static const List<List<String>> groups = <List<String>>[
    <String>['यीशु', 'प्रभु', 'मसीह', 'उद्धारकर्ता', 'yeeshu', 'prabhu', 'masih'],
    <String>['परमेश्वर', 'ईश्वर', 'पिता', 'प्रभु', 'खुदा', 'parmeshwar', 'ishwar'],
    <String>['आत्मा', 'रूह', 'पवित्रआत्मा', 'aatma', 'ruh'],
    <String>['स्तुति', 'आराधना', 'महिमा', 'गुणगान', 'stuti', 'aaradhana', 'mahima'],
    <String>['धन्यवाद', 'शुक्र', 'आभार', 'dhanyavad'],
    <String>['प्रार्थना', 'विनती', 'दुआ', 'prarthana', 'dua'],
    <String>['प्रेम', 'प्यार', 'स्नेह', 'करुणा', 'prem', 'pyar'],
    <String>['शांति', 'चैन', 'सुख', 'shanti'],
    <String>['पाप', 'अपराध', 'दोष', 'paap'],
    <String>['उद्धार', 'मुक्ति', 'छुटकारा', 'बचाव', 'uddhar', 'mukti'],
    <String>['स्वर्ग', 'बैकुण्ठ', 'परमधाम', 'swarg'],
    <String>['क्रूस', 'सलीब', 'kruz', 'cross'],
    <String>['लहू', 'रक्त', 'खून', 'lahu', 'rakt'],
    <String>['जीवन', 'ज़िंदगी', 'प्राण', 'jeevan', 'jivan'],
    <String>['ज्योति', 'प्रकाश', 'रोशनी', 'उजियाला', 'jyoti', 'prakash'],
    <String>['राजा', 'प्रभु', 'स्वामी', 'raja'],
    <String>['विश्वास', 'आस्था', 'भरोसा', 'vishwas'],
    <String>['आशा', 'उम्मीद', 'aasha', 'asha'],
    <String>['कृपा', 'अनुग्रह', 'दया', 'kripa', 'daya'],
    <String>['वचन', 'शब्द', 'बात', 'vachan'],
    <String>['चरवाहा', 'गड़रिया', 'रखवाला', 'charwaha'],
    <String>['हल्लिलूयाह', 'जयजयकार', 'hallelujah'],
    <String>['आमीन', 'amen', 'aamin'],
  ];

  static Map<String, List<String>>? _index;

  /// term -> list of synonymous terms (excluding the term itself).
  static Map<String, List<String>> get _map {
    final Map<String, List<String>>? cached = _index;
    if (cached != null) return cached;
    final Map<String, List<String>> m = <String, List<String>>{};
    for (final List<String> group in groups) {
      for (final String term in group) {
        final List<String> others =
            group.where((String t) => t != term).toList(growable: false);
        (m[term] ??= <String>[]).addAll(others);
      }
    }
    _index = m;
    return m;
  }

  /// Returns synonyms for [term] (lower-cased match), or an empty list.
  static List<String> expand(String term) {
    return _map[term.toLowerCase()] ?? const <String>[];
  }
}
