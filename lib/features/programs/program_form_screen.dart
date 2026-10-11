import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/image_providers.dart';
import '../../data/models/exercise.dart';
import '../../domain/program_drafts.dart';
import '../../domain/program_errors.dart';
import '../../domain/program_rules.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';
import '../../widgets/pick_image.dart';
import '../../widgets/stored_image.dart';
import 'exercise_picker_dialog.dart';
import 'program_providers.dart';

class ProgramFormScreen extends ConsumerStatefulWidget {
  const ProgramFormScreen({super.key, this.programId});

  final String? programId;

  bool get isEditing => programId != null;

  @override
  ConsumerState<ProgramFormScreen> createState() => _ProgramFormScreenState();
}

class _PlannedDraft {
  _PlannedDraft({
    required this.exerciseId,
    required this.exerciseName,
    int sets = defaultTargetSets,
    int? repsMin,
    int? repsMax,
    int rest = defaultRestSeconds,
  }) {
    setsController.text = '$sets';
    repsMinController.text = repsMin?.toString() ?? '';
    repsMaxController.text = repsMax?.toString() ?? '';
    restController.text = '$rest';
  }

  final String exerciseId;
  final String exerciseName;
  final TextEditingController setsController = TextEditingController();
  final TextEditingController repsMinController = TextEditingController();
  final TextEditingController repsMaxController = TextEditingController();
  final TextEditingController restController = TextEditingController();

  void dispose() {
    setsController.dispose();
    repsMinController.dispose();
    repsMaxController.dispose();
    restController.dispose();
  }
}

class _SessionDraft {
  _SessionDraft({required this.nameController, required this.exercises});

  final TextEditingController nameController;
  final List<_PlannedDraft> exercises;

  void dispose() {
    nameController.dispose();
    for (final planned in exercises) {
      planned.dispose();
    }
  }
}

class _ProgramFormScreenState extends ConsumerState<ProgramFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<_SessionDraft> _sessions = [];
  String? _nameTakenError;
  bool _saving = false;
  int _defaultRest = defaultRestSeconds;
  String? _existingImagePath;
  Uint8List? _pickedBytes;
  String _pickedExtension = 'jpg';
  bool _removeImage = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final session in _sessions) {
      session.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final repository = ref.read(programRepositoryProvider);
    final rest = await repository.getDefaultRestSeconds();
    _defaultRest = rest;
    if (widget.isEditing) {
      final program = await repository.getById(widget.programId!);
      _nameController.text = program.name;
      _descriptionController.text = program.description ?? '';
      _existingImagePath = program.imagePath;
      for (final session in await repository.getSessions(program.id)) {
        final draft = _SessionDraft(
          nameController: TextEditingController(text: session.name),
          exercises: [],
        );
        for (final line in await repository.getSessionExercises(session.id)) {
          draft.exercises.add(
            _PlannedDraft(
              exerciseId: line.exerciseId,
              exerciseName: line.exerciseName,
              sets: line.targetSets,
              repsMin: line.repsMin,
              repsMax: line.repsMax,
              rest: line.restSeconds,
            ),
          );
        }
        _sessions.add(draft);
      }
    }
    if (mounted) setState(() {});
  }

  String? _validateName(String? value) {
    final error = ProgramRules.validateName(value ?? '');
    if (error != null) return error;
    if (_nameTakenError != null) return _nameTakenError;
    return null;
  }

  void _addSession() {
    setState(() {
      _sessions.add(
        _SessionDraft(
          nameController: TextEditingController(
            text: 'Séance ${_sessions.length + 1}',
          ),
          exercises: [],
        ),
      );
    });
  }

  Future<void> _removeSession(_SessionDraft session) async {
    if (session.exercises.isNotEmpty) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Supprimer la séance ?'),
          content: const Text('Les exercices prévus seront supprimés.'),
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
      if (confirmed != true) return;
    }
    setState(() => _sessions.remove(session));
    session.dispose();
  }

  void _removePlanned(_SessionDraft session, _PlannedDraft planned) {
    setState(() {
      session.exercises.remove(planned);
      planned.dispose();
    });
  }

  Future<void> _addExercise(_SessionDraft session) async {
    final exercise = await showDialog<Exercise>(
      context: context,
      builder: (_) => const ExercisePickerDialog(),
    );
    if (exercise == null) return;
    setState(() {
      session.exercises.add(
        _PlannedDraft(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          rest: _defaultRest,
        ),
      );
    });
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

    final sessions = <SessionDraft>[];
    for (final session in _sessions) {
      final lines = <PlannedExerciseDraft>[];
      for (final planned in session.exercises) {
        lines.add(
          PlannedExerciseDraft(
            exerciseId: planned.exerciseId,
            targetSets: int.tryParse(planned.setsController.text) ?? 0,
            repsMin: _parseReps(planned.repsMinController.text),
            repsMax: _parseReps(planned.repsMaxController.text),
            restSeconds: int.tryParse(planned.restController.text) ?? 0,
          ),
        );
      }
      sessions.add(
        SessionDraft(name: session.nameController.text, exercises: lines),
      );
    }
    final draft = ProgramDraft(
      name: _nameController.text,
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      sessions: sessions,
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final error = validateProgramDraft(draft);
    if (error != null) {
      messenger.showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    setState(() => _saving = true);
    final store = ref.read(imageStoreProvider);
    String? imagePath = _existingImagePath;
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
    final finalDraft = ProgramDraft(
      name: draft.name,
      description: draft.description,
      imagePath: imagePath,
      sessions: draft.sessions,
    );

    try {
      final repository = ref.read(programRepositoryProvider);
      if (widget.isEditing) {
        await repository.update(widget.programId!, finalDraft);
      } else {
        await repository.create(finalDraft);
      }
      if (createdPath != null || _removeImage) {
        await store.delete(_existingImagePath);
      }
      if (mounted) navigator.pop();
    } on ProgramNameTakenException {
      if (createdPath != null) await store.delete(createdPath);
      setState(() {
        _nameTakenError = 'Un programme porte déjà ce nom.';
        _saving = false;
      });
      _formKey.currentState?.validate();
    } on ProgramPredefinedException {
      if (createdPath != null) await store.delete(createdPath);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Un programme prédéfini ne peut être modifié.'),
        ),
      );
      setState(() => _saving = false);
    }
  }

  int? _parseReps(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  Widget _buildImageSection() {
    final hasImage =
        _pickedBytes != null || (!_removeImage && _existingImagePath != null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_pickedBytes != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.memory(_pickedBytes!, height: 200, fit: BoxFit.cover),
          )
        else if (!_removeImage && _existingImagePath != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: StoredImage(relativePath: _existingImagePath!, height: 200),
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
        title: Text(
          widget.isEditing ? 'Modifier le programme' : 'Nouveau programme',
        ),
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
              maxLength: programNameMaxLength,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: _validateName,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _descriptionController,
              maxLength: 1000,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optionnel)',
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Séances types', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            if (_sessions.isEmpty)
              const Text(
                'Ajoute au moins une séance type.',
                style: TextStyle(color: AppColors.textMuted),
              )
            else
              for (final session in _sessions)
                _buildSessionCard(session),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _addSession,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une séance'),
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

  Widget _buildSessionCard(_SessionDraft session) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.fitness_center, color: AppColors.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextFormField(
                  controller: session.nameController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Nom de la séance'),
                  validator: (value) =>
                      (value ?? '').trim().isEmpty ? 'Le nom est requis.' : null,
                ),
              ),
              IconButton(
                tooltip: 'Supprimer la séance',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _removeSession(session),
              ),
            ],
          ),
          for (final planned in session.exercises)
            _PlannedRow(
              planned: planned,
              onRemove: () => _removePlanned(session, planned),
            ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _addExercise(session),
              icon: const Icon(Icons.add),
              label: const Text('Ajouter un exercice'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannedRow extends StatelessWidget {
  const _PlannedRow({required this.planned, required this.onRemove});

  final _PlannedDraft planned;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  planned.exerciseName,
                  style: Theme.of(context).textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                tooltip: 'Retirer l\'exercice',
                icon: const Icon(Icons.close, size: 18),
                onPressed: onRemove,
              ),
            ],
          ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _numberField(
                controller: planned.setsController,
                label: 'Séries',
                validator: (text) =>
                    ProgramRules.validateSets(int.tryParse(text ?? '')),
              ),
              _numberField(
                controller: planned.repsMinController,
                label: 'Reps min',
                validator: (text) =>
                    ProgramRules.validateReps(int.tryParse(text ?? '')),
              ),
              _numberField(
                controller: planned.repsMaxController,
                label: 'Reps max',
                validator: (text) =>
                    ProgramRules.validateReps(int.tryParse(text ?? '')),
              ),
              _numberField(
                controller: planned.restController,
                label: 'Repos (s)',
                validator: (text) =>
                    ProgramRules.validateRest(int.tryParse(text ?? '')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
  }) {
    return SizedBox(
      width: 82,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }
}
String _extensionOf(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot == -1 || dot == fileName.length - 1) return 'jpg';
  return fileName.substring(dot + 1).toLowerCase();
}
