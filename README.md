# GymF

Application mobile de suivi de musculation, 100 % hors ligne, Android uniquement, à usage
personnel. Un seul utilisateur par installation : pas de compte, pas de serveur, pas de
synchronisation.

Document de référence : `docs/Application mobile de suivi d'entraînement.md`.
Gouvernance : `AGENTS.md`, `DESIGN.md` (tokens du skin), `DECISIONS.md` (journal des décisions).

## Fonctionnalités

- Bibliothèque d'exercices et de programmes (prédéfinis + personnels, textes et images).
- Séance avec chrono de repos, pré-remplissage et récapitulatif.
- Historique avec calendrier et records personnels.
- Suivi : graphiques de progression et de volume, photos de progression.
- Planning de salle, rappels locaux et série de jours.
- Sauvegarde JSON (export/import) sans images ni éléments prédéfinis.

## Développement

```bash
flutter pub get                 # dépendances
flutter analyze                 # lint / analyse statique
flutter test                    # tests automatisés
flutter run -d <device>         # exécution sur Android réel
flutter build apk --debug       # build de test
```

## Stack

Flutter (Dart) seul · `sqflite` + `path_provider` (SQL brut, migrations versionnées) ·
`flutter_riverpod` · `flutter_local_notifications` + `timezone` + `flutter_timezone` ·
`image_picker` · `fl_chart` · `share_plus` + `file_picker` · polices embarquées Rajdhani/Inter.