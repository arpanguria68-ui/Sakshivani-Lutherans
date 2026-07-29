import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/constants/app_constants.dart';

/// Ensures [bible_db.zip] is present on disk. The ~42 MB archive is no
/// longer bundled in the APK/AAB; it is downloaded once from GitHub on first
/// Bible use and cached under the app documents directory.
class BibleAssetService {
  static const String _zipFileName = 'bible_db.zip';

  /// Returns the cached zip path when [ensureDownloaded] has succeeded.
  Future<File> localZipFile() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _zipFileName));
  }

  Future<bool> isDownloaded() async {
    final File file = await localZipFile();
    if (!await file.exists()) {
      return false;
    }
    return await file.length() > 1024;
  }

  /// Downloads the Bible archive if missing. [onProgress] receives 0.0–1.0
  /// when the server returns a Content-Length header.
  Future<void> ensureDownloaded({void Function(double progress)? onProgress}) async {
    if (await isDownloaded()) {
      onProgress?.call(1);
      return;
    }

    final Uri uri = Uri.parse(AppConstants.bibleZipDownloadUrl);
    final http.Client client = http.Client();
    try {
      final http.Request request = http.Request('GET', uri);
      final http.StreamedResponse response = await client.send(request).timeout(
        const Duration(minutes: 10),
      );
      if (response.statusCode != 200) {
        throw StateError('Bible download failed (${response.statusCode}).');
      }

      final int? total = response.contentLength;
      final File dest = await localZipFile();
      final File temp = File('${dest.path}.part');
      final IOSink sink = temp.openWrite();
      int received = 0;

      await for (final List<int> chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total != null && total > 0) {
          onProgress?.call(received / total);
        }
      }
      await sink.close();

      if (total != null && received < total) {
        await temp.delete();
        throw StateError('Bible download incomplete ($received / $total bytes).');
      }

      if (await dest.exists()) {
        await dest.delete();
      }
      await temp.rename(dest.path);
      onProgress?.call(1);
    } finally {
      client.close();
    }
  }
}
