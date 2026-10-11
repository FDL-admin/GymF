import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gymf/data/image_store.dart';

void main() {
  late Directory base;

  setUp(() async {
    base = await Directory.systemTemp.createTemp('gymf_images');
  });

  tearDown(() async {
    if (await base.exists()) await base.delete(recursive: true);
  });

  test('saveBytes écrit le fichier et renvoie un chemin relatif', () async {
    final store = ImageStore(baseDir: base);

    final relative = await store.saveBytes([1, 2, 3], extension: 'png');

    expect(relative, startsWith('${ImageStore.folder}/'));
    expect(relative, endsWith('.png'));
    final file = await store.resolve(relative);
    expect(await file.exists(), isTrue);
    expect(await file.readAsBytes(), [1, 2, 3]);
  });

  test('deux sauvegardes génèrent des chemins distincts', () async {
    final store = ImageStore(baseDir: base);

    final first = await store.saveBytes([1]);
    final second = await store.saveBytes([2]);

    expect(first, isNot(second));
  });

  test('copy duplique le contenu dans un nouveau fichier', () async {
    final store = ImageStore(baseDir: base);
    final source = await store.saveBytes([9, 8, 7], extension: 'jpg');

    final copy = await store.copy(source);

    expect(copy, isNot(source));
    final copied = await store.resolve(copy);
    expect(await copied.readAsBytes(), [9, 8, 7]);
  });

  test('delete supprime le fichier et ignore un chemin nul', () async {
    final store = ImageStore(baseDir: base);
    final relative = await store.saveBytes([4]);

    await store.delete(relative);
    await store.delete(null);

    final file = await store.resolve(relative);
    expect(await file.exists(), isFalse);
  });
}