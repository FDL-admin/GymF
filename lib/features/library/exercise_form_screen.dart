import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/exercise.dart';
import '../../data/models/muscle_groups.dart';
import '../../domain/exercise_errors.dart';
import '../../domain/exercise_rules.dart';
import '../../theme/spacing.dart';
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

  Future<void> _save() async {
    setState(() => _nameTakenError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final repository = ref.read(exerciseRepositoryProvider);
      if (widget.isEditing) {
        await repository.update(
          widget.exercise!.id,
          name: _nameController.text,
          muscleGroup: _muscleGroup,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      } else {
        await repository.create(
          name: _nameController.text,
          muscleGroup: _muscleGroup,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
        );
      }
      if (mounted) navigator.pop();
    } on ExerciseNameTakenException {
      setState(() {
        _nameTakenError = 'Un exercice porte déjà ce nom.';
        _saving = false;
      });
      _formKey.currentState?.validate();
    } on ExercisePredefinedException {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Un exercice prédéfini ne peut être modifié.'),
        ),
      );
      setState(() => _saving = false);
    } on ArgumentError catch (error) {
      setState(() => _saving = false);
      if (error.message is String) {
        messenger.showSnackBar(
          SnackBar(content: Text(error.message.toString())),
        );
      }
    }
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