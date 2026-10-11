import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class ImageStore {
  ImageStore({Directory? baseDir}) : _explicitBase = baseDir;

  static const String folder = 'images';

  final Directory? _explicitBase;
  Directory? _resolvedBase;
  final Uuid _uuid = const Uuid();

  Future<Directory> _base() async {
    if (_explicitBase != null) return _explicitBase;
    return _resolvedBase ??= await getApplicationDocumentsDirectory();
  }

  Future<String> saveBytes(List<int> bytes, {String extension = 'jpg'}) async {
    final base = await _base();
    final relative = '$folder/${_uuid.v4()}.$extension';
    final file = File('${base.path}/$relative');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return relative;
  }

  Future<String> copy(String relativePath) async {
    final source = await resolve(relativePath);
    final bytes = await source.readAsBytes();
    final dot = relativePath.lastIndexOf('.');
    final extension = dot == -1 ? 'jpg' : relativePath.substring(dot + 1);
    return saveBytes(bytes, extension: extension);
  }

  Future<void> delete(String? relativePath) async {
    if (relativePath == null || relativePath.isEmpty) return;
    final file = await resolve(relativePath);
    if (await file.exists()) await file.delete();
  }

  Future<File> resolve(String relativePath) async {
    final base = await _base();
    return File('${base.path}/$relativePath');
  }
}