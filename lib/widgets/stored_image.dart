import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/image_providers.dart';
import '../theme/colors.dart';

class StoredImage extends ConsumerWidget {
  const StoredImage({
    super.key,
    required this.relativePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String relativePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(imageStoreProvider);
    return FutureBuilder<File>(
      future: store.resolve(relativePath),
      builder: (context, snapshot) {
        final file = snapshot.data;
        if (file == null) {
          return SizedBox(
            width: width,
            height: height,
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (_, _, _) => Container(
            width: width,
            height: height,
            color: AppColors.surfaceElevated,
            child: const Icon(Icons.broken_image_outlined),
          ),
        );
      },
    );
  }
}