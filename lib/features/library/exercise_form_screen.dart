import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/image_providers.dart';
import '../../data/models/exercise.dart';
import '../../data/models/muscle_groups.dart';
import '../../domain/exercise_errors.dart';
import '../../domain/exercise_rules.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/pick_image.dart';
import '../../widgets/stored_image.dart';
import 'exercise_providers.dart';
import 'muscle_group_labels.dart';

class ExerciseFormScreen extends ConsumerStatefulWidget {
  const ExerciseFormScreen({super.key, this.exercise});

  final Exercise? exercise;

  bool get isEditing => exercise != null;

  @override
  ConsumerState<ExerciseFormScreen> createState() =>
      _ExerciseFormScreenState();
}

class _ExerciseFormScreenState extends ConsumerState<ExerciseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late String _muscleGroup;
  String? _nameTakenError;
  bool _saving = false;
  Uint8List? _pickedBytes;
  String _pickedExtension = 'jpg';
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.exercise?.description ?? '');
    _muscleGroup = widget.exercise?.muscleGroup ?? MuscleGroups.chest;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final error = ExerciseRules.validateName(value ?? '');
    if (error != null) return error;
    if (_nameTakenError != null) return _nameTakenError;
    return null;
  }

  Future<void> _pickImage() async {
    final file = await pickImage(context);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _pickedBytes = bytes;
      _pickedExtension = _extensionOf(file.name);
      _removeImage = false;
    });
  }

  void _clearImage() {
    setState(() {
      _pickedBytes = null;
      _removeImage = true;
    });
  }

  Future<void> _save() async {
    setState(() => _nameTakenError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final store = ref.read(imageStoreProvider);
    final previousPath = widget.exercise?.imagePath;

    String? imagePath = previousPath;
    String? createdPath;
    if (_pickedBytes != null) {
      try {
        createdPath = await store.saveBytes(
          _pickedBytes!,
          extension: _pickedExtension,
        );
        imagePath = createdPath;
      } on Exception {
        if (mounted) setState(() => _saving = false);
        messenger.showSnackBar(
          const SnackBar(content: Text("Impossible d'enregistrer l'image.")),
        );
        return;
      }
    } else if (_removeImage) {
      imagePath = null;
    }

    final description = _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim();
    try {
      final repository = ref.read(exerciseRepositoryProvider);
      if (widget.isEditing) {
        await repository.update(
          widget.exercise!.id,
          name: _nameController.text,
          muscleGroup: _muscleGroup,
          description: description,
          imagePath: imagePath,
        );
      } else {
        await repository.create(
          name: _nameController.text,
          muscleGroup: _muscleGroup,
          description: description,
          imagePath: imagePath,
        );
      }
      if (createdPath != null || _removeImage) {
        await store.delete(previousPath);
      }
      if (widget.isEditing) {
        ref.invalidate(exerciseProvider(widget.exercise!.id));
      }
      if (mounted) navigator.pop();
    } on ExerciseNameTakenException {
      if (createdPath != null) await store.delete(createdPath);
      setState(() {
        _nameTakenError = 'Un exercice porte déjà ce nom.';
        _saving = false;
      });
      _formKey.currentState?.validate();
    } on ExercisePredefinedException {
      if (createdPath != null) await store.delete(createdPath);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Un exercice prédéfini ne peut être modifié.'),
        ),
      );
      setState(() => _saving = false);
    } on ArgumentError catch (error) {
      if (createdPath != null) await store.delete(createdPath);
      setState(() => _saving = false);
      if (error.message is String) {
        messenger.showSnackBar(
          SnackBar(content: Text(error.message.toString())),
        );
      }
    }
  }

  Widget _buildImageSection() {
    final existing = widget.exercise?.imagePath;
    final hasImage = _pickedBytes != null || (!_removeImage && existing != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_pickedBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(
              _pickedBytes!,
              height: 200,
              fit: BoxFit.cover,
            ),
          )
        else if (!_removeImage && existing != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: StoredImage(relativePath: existing, height: 200),
          )
        else
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(Icons.image_outlined, color: AppColors.textMuted),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: _saving ? null : _pickImage,
          icon: const Icon(Icons.photo_camera_outlined),
          label: Text(hasImage ? 'Remplacer la photo' : 'Ajouter une photo'),
        ),
        if (hasImage) ...[
          const SizedBox(height: AppSpacing.xs),
          TextButton(
            onPressed: _saving ? null : _clearImage,
            child: const Text("Supprimer l'image"),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Modifier l\'exercice' : 'Nouvel exercice'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _buildImageSection(),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              maxLength: 60,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: _validateName,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: _muscleGroup,
              decoration: const InputDecoration(labelText: 'Groupe musculaire'),
              items: [
                for (final (value, label) in muscleGroupOptions)
                  DropdownMenuItem<String>(value: value, child: Text(label)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _muscleGroup = value);
              },
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descriptionController,
              maxLength: 1000,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Description (optionnel)'),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(widget.isEditing ? 'Enregistrer' : 'Créer'),
            ),
          ],
        ),
      ),
    );
  }
}

String _extensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot == -1 || dot == fileName.length - 1) return 'jpg';
  return fileName.substring(dot + 1).toLowerCase();
}