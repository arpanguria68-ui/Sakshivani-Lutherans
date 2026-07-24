import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bible/presentation/bible_tab.dart';
import '../../home/presentation/home_tab.dart';
import '../../journey/presentation/journey_tab.dart';
import '../../songs/presentation/songs_tab.dart';

final Provider<List<Widget>> shellTabsProvider = Provider<List<Widget>>((ProviderRef<List<Widget>> ref) {
  return const <Widget>[
    HomeTab(),
    SongsTab(),
    BibleTab(),
    JourneyTab(),
  ];
});
