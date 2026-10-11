import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/image_providers.dart';
import '../../data/models/progress_photo.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pick_image.dart';
import '../../widgets/stored_image.dart';
import 'tracking_providers.dart';

class ProgressPhotosView extends ConsumerStatefulWidget {
  const ProgressPhotosView({super.key});

  @override
  ConsumerState<ProgressPhotosView> createState() => _ProgressPhotosViewState();
}

class _ProgressPhotosViewState extends ConsumerState<ProgressPhotosView> {
  bool _busy = false;

  Future<void> _addPhoto() async {
    final file = await pickImage(context);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    await _persist(bytes, _extensionOf(file.name));
  }

  Future<void> _persist(Uint8List bytes, String extension) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final store = ref.read(imageStoreProvider);
    String path;
    try {
      path = await store.saveBytes(bytes, extension: extension);
    } on Exception {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(content: Text("Impossible d'enregistrer la photo.")),
      );
      return;
    }
    try {
      await ref
          .read(progressPhotoRepositoryProvider)
          .add(imagePath: path, takenOn: DateTime.now());
    } on Exception {
      await store.delete(path);
      messenger.showSnackBar(
        const SnackBar(content: Text('Impossible d\'ajouter la photo.')),
      );
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _openViewer(ProgressPhoto photo) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _PhotoViewer(photo: photo),
      ),
    );
  }

  void _openCompare(List<ProgressPhoto> photos) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CompareView(photos: photos),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(progressPhotosProvider);
    return photosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const EmptyState(
        icon: Icons.broken_image_outlined,
        message: 'Impossible de charger les photos.',
      ),
      data: (photos) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _addPhoto,
                    icon: const Icon(Icons.add_a_photo_outlined),
                    label: const Text('Ajouter une photo'),
                  ),
                ),
                if (photos.length >= 2) ...[
                  const SizedBox(width: AppSpacing.sm),
                  OutlinedButton.icon(
                    onPressed: () => _openCompare(photos),
                    icon: const Icon(Icons.compare_outlined),
                    label: const Text('Comparer'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: photos.isEmpty
                ? const EmptyState(
                    icon: Icons.photo_library_outlined,
                    message: 'Aucune photo pour le moment.',
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      0,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: AppSpacing.sm,
                      mainAxisSpacing: AppSpacing.sm,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return InkWell(
                        onTap: () => _openViewer(photo),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: StoredImage(relativePath: photo.imagePath),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PhotoViewer extends ConsumerWidget {
  const _PhotoViewer({required this.photo});

  final ProgressPhoto photo;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la photo ?'),
        content: const Text('La photo sera supprimée définitivement.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final navigator = Navigator.of(context);
    final store = ref.read(imageStoreProvider);
    await ref.read(progressPhotoRepositoryProvider).delete(photo.id);
    await store.delete(photo.imagePath);
    navigator.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(photo.takenOn)),
        actions: [
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _delete(context, ref),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: StoredImage(
                relativePath: photo.imagePath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          if (photo.note?.isNotEmpty ?? false)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(photo.note!),
            ),
        ],
      ),
    );
  }
}

class _CompareView extends StatefulWidget {
  const _CompareView({required this.photos});

  final List<ProgressPhoto> photos;

  @override
  State<_CompareView> createState() => _CompareViewState();
}

class _CompareViewState extends State<_CompareView> {
  late ProgressPhoto _before;
  late ProgressPhoto _after;

  @override
  void initState() {
    super.initState();
    _before = widget.photos.last;
    _after = widget.photos.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comparer')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _selector(
                    label: 'Avant',
                    value: _before,
                    onChanged: (photo) => setState(() => _before = photo),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _selector(
                    label: 'Après',
                    value: _after,
                    onChanged: (photo) => setState(() => _after = photo),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: StoredImage(
                      relativePath: _before.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: StoredImage(
                      relativePath: _after.imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _selector({
    required String label,
    required ProgressPhoto value,
    required ValueChanged<ProgressPhoto> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted)),
        const SizedBox(height: AppSpacing.xs),
        DropdownButton<ProgressPhoto>(
          value: value,
          isExpanded: true,
          items: [
            for (final photo in widget.photos)
              DropdownMenuItem(
                value: photo,
                child: Text(_formatDate(photo.takenOn)),
              ),
          ],
          onChanged: (photo) {
            if (photo != null) onChanged(photo);
          },
        ),
      ],
    );
  }
}

String _formatDate(String key) {
  final parts = key.split('-');
  if (parts.length != 3) return key;
  return '${parts[2]}/${parts[1]}/${parts[0]}';
}

String _extensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot == -1 || dot == fileName.length - 1) return 'jpg';
  return fileName.substring(dot + 1).toLowerCase();
}