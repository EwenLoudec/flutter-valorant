import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/lineup_media.dart';

/// Keeps the pictures and clips of a spot next to the app's own data, so they
/// survive the gallery being cleaned up.
class LineupMediaStore {
  LineupMediaStore({ImagePicker? picker}) : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// The web build has no application directory to copy files into.
  bool get isSupported => !kIsWeb;

  /// Returns the stored media, or null when the user cancelled the picker.
  Future<LineupMedia?> pick({
    required String lineupId,
    required LineupMediaRole role,
    required LineupMediaKind kind,
  }) async {
    if (!isSupported) return null;

    final picked = kind == LineupMediaKind.video
        ? await _picker.pickVideo(source: ImageSource.gallery)
        : await _picker.pickImage(source: ImageSource.gallery, imageQuality: 88);
    if (picked == null) return null;

    final directory = Directory('${(await getApplicationDocumentsDirectory()).path}/lineups');
    await directory.create(recursive: true);

    final extension = picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : 'bin';
    final destination = File('${directory.path}/$lineupId-${role.code}.$extension');
    await destination.writeAsBytes(await picked.readAsBytes());

    return LineupMedia(role: role, kind: kind, path: destination.path);
  }

  Future<void> deleteAll(Iterable<LineupMedia> media) async {
    if (!isSupported) return;

    for (final entry in media) {
      final file = File(entry.path);
      if (file.existsSync()) await file.delete();
    }
  }
}
