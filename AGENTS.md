# AGENTS.md — GymF

## Projet

GymF est une application mobile de suivi de musculation **100 % hors ligne**, Android uniquement,
à usage personnel. Un seul utilisateur par installation : pas de compte, pas de serveur, pas de
synchronisation, pas de déploiement.

Le document de référence est `docs/Application mobile de suivi d'entraînement.md`. Il fait foi :
en cas de doute, appliquer ce qui y est écrit. Ne rien ajouter hors périmètre (section 2).

## Stack

- Flutter (Dart) seul, cible Android, `minSdkVersion` 29.
- Stockage : `sqflite` + `path_provider`, SQL brut, migrations versionnées via `onUpgrade`.
- État : `flutter_riverpod`.
- Notifications : `flutter_local_notifications` + `timezone` + `flutter_timezone`.
- Images : `image_picker` (`maxWidth`/`maxHeight` 1280, `imageQuality` 80).
- Graphiques : `fl_chart`.
- Export/import : `share_plus`, `file_picker`.
- Polices embarquées : Rajdhani (titres) et Inter (texte) via assets, jamais `google_fonts`.

## Architecture

- Logique métier (règles RM-xx, calculs, planification des notifications) en **Dart pur**, sans
  dépendance Flutter, testée avec `flutter_test`.
- Les écrans ne contiennent **aucune** règle métier.
- Dates `created_at` en ISO 8601 UTC ; « jour » calendaire en heure locale de l'appareil.
- IDs UUID v4 (texte) ; `position` entier à partir de 0 ; charges en kg (1 décimale max).

## Commandes

```bash
flutter pub get                 # dépendances
flutter analyze                 # lint / analyse statique
flutter test                    # tests automatisés
flutter run -d <device>         # exécution sur Android réel
flutter build apk --debug       # build de test
```

## Conventions

- Identifiants de code en **anglais** ; tout texte visible par l'utilisateur en **français**.
- Un commit Git par fonctionnalité, message à l'impératif en français
  (ex. « Ajoute la création d'exercice »). Dépôt propre avant chaque palier.
- Toute dépendance ajoutée est justifiée dans `DECISIONS.md`. Aucune dépendance ne doit exiger
  Internet à l'exécution.
- Ne jamais modifier le schéma de la base sans migration versionnée conservant les données.
- Pas de commentaires dans le code (sauf demande explicite).
- Ne pas coder de fonctionnalité sans validation du plan de palier.

## Fichiers de gouvernance

- `AGENTS.md` : ce fichier (résumé, commandes, conventions).
- `DESIGN.md` : tokens de la section 8 du cahier des charges.
- `DECISIONS.md` : journal des décisions et hypothèses (date, question, choix, raison).

## Paliers

Travail par paliers dans l'ordre (section 10). Ne commencer un palier que lorsque les critères
d'acceptation du précédent sont remplis et testés. Voir `DECISIONS.md` pour l'état d'avancement.
