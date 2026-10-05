import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

/// A response body kept from an earlier request, with the moment it was saved.
class CachedResponse {
  const CachedResponse({required this.body, required this.savedAt});

  final String body;
  final DateTime savedAt;

  Duration get age => DateTime.now().difference(savedAt);
}

/// Somewhere to keep API responses between launches, so the catalogue shows
/// up at once and still works without a connection.
abstract class ResponseCache {
  Future<CachedResponse?> read(String key);
  Future<void> write(String key, String body);
}

/// Keeps each response as a file in the app's cache directory. Every failure
/// is swallowed: a cache that cannot be read is simply a cache miss.
class FileResponseCache implements ResponseCache {
  FileResponseCache({Future<Directory> Function()? directory}) : _directory = directory ?? _defaultDirectory;

  final Future<Directory> Function() _directory;

  /// The web build has no file system: the browser's own HTTP cache covers it.
  static ResponseCache? platformDefault() => kIsWeb ? null : FileResponseCache();

  static Future<Directory> _defaultDirectory() async {
    final base = await getApplicationCacheDirectory();
    return Directory('${base.path}${Platform.pathSeparator}valorant_api');
  }

  Future<File> _fileFor(String key) async {
    final directory = await _directory();
    final name = base64Url.encode(utf8.encode(key)).replaceAll('=', '');
    return File('${directory.path}${Platform.pathSeparator}$name.json');
  }

  @override
  Future<CachedResponse?> read(String key) async {
    try {
      final file = await _fileFor(key);
      if (!await file.exists()) return null;
      return CachedResponse(body: await file.readAsString(), savedAt: await file.lastModified());
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String key, String body) async {
    try {
      final file = await _fileFor(key);
      await file.parent.create(recursive: true);
      await file.writeAsString(body, flush: true);
    } on Object {
      // Nothing to do: the next launch will just download again.
    }
  }
}

/// Keeps responses in memory only — for tests.
class MemoryResponseCache implements ResponseCache {
  final entries = <String, CachedResponse>{};

  @override
  Future<CachedResponse?> read(String key) async => entries[key];

  @override
  Future<void> write(String key, String body) async {
    entries[key] = CachedResponse(body: body, savedAt: DateTime.now());
  }
}
