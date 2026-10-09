import 'models/muscle_groups.dart';

const String seedCreatedAt = '2026-10-09T00:00:00.000Z';

class SeedExercise {
  const SeedExercise({
    required this.id,
    required this.name,
    required this.muscleGroup,
  });

  final String id;
  final String name;
  final String muscleGroup;
}

class SeedSessionExercise {
  const SeedSessionExercise({
    required this.exerciseId,
    required this.targetSets,
    this.repsMin,
    this.repsMax,
    this.restSeconds = 90,
  });

  final String exerciseId;
  final int targetSets;
  final int? repsMin;
  final int? repsMax;
  final int restSeconds;
}

class SeedSession {
  const SeedSession({
    required this.id,
    required this.name,
    required this.exercises,
  });

  final String id;
  final String name;
  final List<SeedSessionExercise> exercises;
}

class SeedProgram {
  const SeedProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.sessions,
  });

  final String id;
  final String name;
  final String description;
  final List<SeedSession> sessions;
}

abstract final class SeedExerciseIds {
  static const developpeCouche = 'seed_ex_developpe_couche';
  static const developpeInclineHalteres = 'seed_ex_developpe_incline_halteres';
  static const ecartesPoulie = 'seed_ex_ecartes_poulie';
  static const pompes = 'seed_ex_pompes';
  static const tractions = 'seed_ex_tractions';
  static const tirageVertical = 'seed_ex_tirage_vertical';
  static const rowingBarre = 'seed_ex_rowing_barre';
  static const rowingHaltere = 'seed_ex_rowing_haltere';
  static const souleveDeTerre = 'seed_ex_souleve_de_terre';
  static const developpeMilitaire = 'seed_ex_developpe_militaire';
  static const elevationsLaterales = 'seed_ex_elevations_laterales';
  static const oiseauHalteres = 'seed_ex_oiseau_halteres';
  static const curlBarre = 'seed_ex_curl_barre';
  static const curlHalteres = 'seed_ex_curl_halteres';
  static const curlMarteau = 'seed_ex_curl_marteau';
  static const dips = 'seed_ex_dips';
  static const extensionsTricepsPoulie = 'seed_ex_extensions_triceps_poulie';
  static const barreAuFront = 'seed_ex_barre_au_front';
  static const squat = 'seed_ex_squat';
  static const presseACuisses = 'seed_ex_presse_a_cuisses';
  static const fentes = 'seed_ex_fentes';
  static const legExtension = 'seed_ex_leg_extension';
  static const legCurl = 'seed_ex_leg_curl';
  static const souleveDeTerreRoumain = 'seed_ex_souleve_de_terre_roumain';
  static const hipThrust = 'seed_ex_hip_thrust';
  static const molletsDebout = 'seed_ex_mollets_debout';
  static const crunch = 'seed_ex_crunch';
  static const releveDeJambes = 'seed_ex_releve_de_jambes';
}

const List<SeedExercise> seedExercises = [
  SeedExercise(
    id: SeedExerciseIds.developpeCouche,
    name: 'Développé couché',
    muscleGroup: MuscleGroups.chest,
  ),
  SeedExercise(
    id: SeedExerciseIds.developpeInclineHalteres,
    name: 'Développé incliné haltères',
    muscleGroup: MuscleGroups.chest,
  ),
  SeedExercise(
    id: SeedExerciseIds.ecartesPoulie,
    name: 'Écartés poulie',
    muscleGroup: MuscleGroups.chest,
  ),
  SeedExercise(
    id: SeedExerciseIds.pompes,
    name: 'Pompes',
    muscleGroup: MuscleGroups.chest,
  ),
  SeedExercise(
    id: SeedExerciseIds.tractions,
    name: 'Tractions',
    muscleGroup: MuscleGroups.back,
  ),
  SeedExercise(
    id: SeedExerciseIds.tirageVertical,
    name: 'Tirage vertical',
    muscleGroup: MuscleGroups.back,
  ),
  SeedExercise(
    id: SeedExerciseIds.rowingBarre,
    name: 'Rowing barre',
    muscleGroup: MuscleGroups.back,
  ),
  SeedExercise(
    id: SeedExerciseIds.rowingHaltere,
    name: 'Rowing haltère',
    muscleGroup: MuscleGroups.back,
  ),
  SeedExercise(
    id: SeedExerciseIds.souleveDeTerre,
    name: 'Soulevé de terre',
    muscleGroup: MuscleGroups.back,
  ),
  SeedExercise(
    id: SeedExerciseIds.developpeMilitaire,
    name: 'Développé militaire',
    muscleGroup: MuscleGroups.shoulders,
  ),
  SeedExercise(
    id: SeedExerciseIds.elevationsLaterales,
    name: 'Élévations latérales',
    muscleGroup: MuscleGroups.shoulders,
  ),
  SeedExercise(
    id: SeedExerciseIds.oiseauHalteres,
    name: 'Oiseau haltères',
    muscleGroup: MuscleGroups.shoulders,
  ),
  SeedExercise(
    id: SeedExerciseIds.curlBarre,
    name: 'Curl barre',
    muscleGroup: MuscleGroups.biceps,
  ),
  SeedExercise(
    id: SeedExerciseIds.curlHalteres,
    name: 'Curl haltères',
    muscleGroup: MuscleGroups.biceps,
  ),
  SeedExercise(
    id: SeedExerciseIds.curlMarteau,
    name: 'Curl marteau',
    muscleGroup: MuscleGroups.biceps,
  ),
  SeedExercise(
    id: SeedExerciseIds.dips,
    name: 'Dips',
    muscleGroup: MuscleGroups.triceps,
  ),
  SeedExercise(
    id: SeedExerciseIds.extensionsTricepsPoulie,
    name: 'Extensions triceps poulie',
    muscleGroup: MuscleGroups.triceps,
  ),
  SeedExercise(
    id: SeedExerciseIds.barreAuFront,
    name: 'Barre au front',
    muscleGroup: MuscleGroups.triceps,
  ),
  SeedExercise(
    id: SeedExerciseIds.squat,
    name: 'Squat',
    muscleGroup: MuscleGroups.legs,
  ),
  SeedExercise(
    id: SeedExerciseIds.presseACuisses,
    name: 'Presse à cuisses',
    muscleGroup: MuscleGroups.legs,
  ),
  SeedExercise(
    id: SeedExerciseIds.fentes,
    name: 'Fentes',
    muscleGroup: MuscleGroups.legs,
  ),
  SeedExercise(
    id: SeedExerciseIds.legExtension,
    name: 'Leg extension',
    muscleGroup: MuscleGroups.legs,
  ),
  SeedExercise(
    id: SeedExerciseIds.legCurl,
    name: 'Leg curl',
    muscleGroup: MuscleGroups.legs,
  ),
  SeedExercise(
    id: SeedExerciseIds.souleveDeTerreRoumain,
    name: 'Soulevé de terre roumain',
    muscleGroup: MuscleGroups.legs,
  ),
  SeedExercise(
    id: SeedExerciseIds.hipThrust,
    name: 'Hip thrust',
    muscleGroup: MuscleGroups.glutes,
  ),
  SeedExercise(
    id: SeedExerciseIds.molletsDebout,
    name: 'Mollets debout',
    muscleGroup: MuscleGroups.calves,
  ),
  SeedExercise(
    id: SeedExerciseIds.crunch,
    name: 'Crunch',
    muscleGroup: MuscleGroups.abs,
  ),
  SeedExercise(
    id: SeedExerciseIds.releveDeJambes,
    name: 'Relevé de jambes',
    muscleGroup: MuscleGroups.abs,
  ),
];

const List<SeedProgram> seedPrograms = [
  SeedProgram(
    id: 'seed_prog_full_body',
    name: 'Full Body (A/B)',
    description:
        'Corps entier réparti sur deux séances alternées. Un modèle équilibré pour progresser sur tous les groupes.',
    sessions: [
      SeedSession(
        id: 'seed_prog_full_body_a',
        name: 'A',
        exercises: [
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.squat,
            targetSets: 3,
            repsMin: 5,
            repsMax: 8,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.developpeCouche,
            targetSets: 3,
            repsMin: 6,
            repsMax: 10,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.rowingBarre,
            targetSets: 3,
            repsMin: 6,
            repsMax: 10,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.developpeMilitaire,
            targetSets: 2,
            repsMin: 8,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.curlBarre,
            targetSets: 2,
            repsMin: 10,
            repsMax: 12,
          ),
        ],
      ),
      SeedSession(
        id: 'seed_prog_full_body_b',
        name: 'B',
        exercises: [
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.souleveDeTerreRoumain,
            targetSets: 3,
            repsMin: 6,
            repsMax: 10,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.developpeInclineHalteres,
            targetSets: 3,
            repsMin: 8,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.tirageVertical,
            targetSets: 3,
            repsMin: 8,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.fentes,
            targetSets: 2,
            repsMin: 10,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.extensionsTricepsPoulie,
            targetSets: 2,
            repsMin: 10,
            repsMax: 12,
          ),
        ],
      ),
    ],
  ),
  SeedProgram(
    id: 'seed_prog_push_pull_legs',
    name: 'Push / Pull / Legs',
    description:
        'Découpage en trois séances par famille de mouvements. Pratique pour répartir le volume sur la semaine.',
    sessions: [
      SeedSession(
        id: 'seed_prog_push_pull_legs_push',
        name: 'Push',
        exercises: [
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.developpeCouche,
            targetSets: 4,
            repsMin: 6,
            repsMax: 10,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.developpeMilitaire,
            targetSets: 3,
            repsMin: 8,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.developpeInclineHalteres,
            targetSets: 3,
            repsMin: 8,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.elevationsLaterales,
            targetSets: 3,
            repsMin: 12,
            repsMax: 15,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.extensionsTricepsPoulie,
            targetSets: 3,
            repsMin: 10,
            repsMax: 15,
          ),
        ],
      ),
      SeedSession(
        id: 'seed_prog_push_pull_legs_pull',
        name: 'Pull',
        exercises: [
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.tractions,
            targetSets: 4,
            repsMin: 6,
            repsMax: 10,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.rowingBarre,
            targetSets: 3,
            repsMin: 8,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.tirageVertical,
            targetSets: 3,
            repsMin: 8,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.oiseauHalteres,
            targetSets: 3,
            repsMin: 12,
            repsMax: 15,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.curlHalteres,
            targetSets: 3,
            repsMin: 10,
            repsMax: 12,
          ),
        ],
      ),
      SeedSession(
        id: 'seed_prog_push_pull_legs_legs',
        name: 'Legs',
        exercises: [
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.squat,
            targetSets: 4,
            repsMin: 6,
            repsMax: 10,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.presseACuisses,
            targetSets: 3,
            repsMin: 10,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.souleveDeTerreRoumain,
            targetSets: 3,
            repsMin: 8,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.legCurl,
            targetSets: 3,
            repsMin: 10,
            repsMax: 15,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.molletsDebout,
            targetSets: 4,
            repsMin: 12,
            repsMax: 15,
          ),
        ],
      ),
    ],
  ),
  SeedProgram(
    id: 'seed_prog_upper_lower',
    name: 'Upper / Lower',
    description:
        'Alternance haut et bas du corps sur deux séances types. Simple à suivre et à répéter.',
    sessions: [
      SeedSession(
        id: 'seed_prog_upper_lower_upper',
        name: 'Upper',
        exercises: [
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.developpeCouche,
            targetSets: 4,
            repsMin: 6,
            repsMax: 10,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.rowingBarre,
            targetSets: 4,
            repsMin: 6,
            repsMax: 10,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.developpeMilitaire,
            targetSets: 3,
            repsMin: 8,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.tirageVertical,
            targetSets: 3,
            repsMin: 8,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.curlBarre,
            targetSets: 2,
            repsMin: 10,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.extensionsTricepsPoulie,
            targetSets: 2,
            repsMin: 10,
            repsMax: 12,
          ),
        ],
      ),
      SeedSession(
        id: 'seed_prog_upper_lower_lower',
        name: 'Lower',
        exercises: [
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.squat,
            targetSets: 4,
            repsMin: 6,
            repsMax: 10,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.souleveDeTerreRoumain,
            targetSets: 3,
            repsMin: 8,
            repsMax: 10,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.presseACuisses,
            targetSets: 3,
            repsMin: 10,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.legCurl,
            targetSets: 3,
            repsMin: 10,
            repsMax: 12,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.molletsDebout,
            targetSets: 4,
            repsMin: 12,
            repsMax: 15,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.crunch,
            targetSets: 3,
            repsMin: 12,
            repsMax: 15,
          ),
        ],
      ),
    ],
  ),
  SeedProgram(
    id: 'seed_prog_5x5',
    name: '5×5 (A/B)',
    description:
        'Programme de force en séries courtes de cinq répétitions, avec repos longs. Deux séances alternées.',
    sessions: [
      SeedSession(
        id: 'seed_prog_5x5_a',
        name: 'A',
        exercises: [
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.squat,
            targetSets: 5,
            repsMin: 5,
            repsMax: 5,
            restSeconds: 180,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.developpeCouche,
            targetSets: 5,
            repsMin: 5,
            repsMax: 5,
            restSeconds: 180,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.rowingBarre,
            targetSets: 5,
            repsMin: 5,
            repsMax: 5,
            restSeconds: 180,
          ),
        ],
      ),
      SeedSession(
        id: 'seed_prog_5x5_b',
        name: 'B',
        exercises: [
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.squat,
            targetSets: 5,
            repsMin: 5,
            repsMax: 5,
            restSeconds: 180,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.developpeMilitaire,
            targetSets: 5,
            repsMin: 5,
            repsMax: 5,
            restSeconds: 180,
          ),
          SeedSessionExercise(
            exerciseId: SeedExerciseIds.souleveDeTerre,
            targetSets: 1,
            repsMin: 5,
            repsMax: 5,
            restSeconds: 180,
          ),
        ],
      ),
    ],
  ),
];
