# DECISIONS.md — Journal des décisions

Format : date · question · choix · raison. Toute dépendance ajoutée est justifiée ici.

## État d'avancement

- Palier 1 (Fondations) : réalisé. `flutter analyze` sans erreur, `flutter test` vert (8 tests),
  `flutter build apk --debug` réussi (`app-debug.apk` généré), pool de disque libéré (24 Go).
- Un commit Git par fonctionnalité terminée.

## Décisions

### 2026-10-09 · Stack et périmètre

- **Question** : quelle stack et quel périmètre pour la v1 ?
- **Choix** : Flutter (Dart) seul, Android uniquement, 100 % hors ligne, nom de l'app **GymF**.
- **Raison** : imposé par le cahier des charges (sections 1 et 3). Aucun serveur, aucune API.

### 2026-10-09 · Fichiers de gouvernance

- **Question** : où consigner conventions, tokens et décisions ?
- **Choix** : `AGENTS.md`, `DESIGN.md`, `DECISIONS.md` créés dès le palier 1.
- **Raison** : exigé par la règle de travail 8.

### 2026-10-09 · Polices embarquées (palier 1)

- **Question** : quelle version des polices Rajdhani et Inter embarquer ?
- **Choix** : versions libres de droits sous licence OFL, téléchargées et versionnées dans
  `assets/fonts/` (Rajdhani 400/500/600/700, Inter 400/500/600/700), jamais `google_fonts`.
- **Raison** : exigé par la section 3 (hors ligne) ; polices confirmées libres de droits
  (section 12). Licences conservées à côté des fichiers.

### 2026-10-09 · minSdkVersion (palier 1)

- **Question** : quelle valeur de `minSdkVersion` ?
- **Choix** : `minSdk = 29` explicite dans `android/app/build.gradle.kts` (au lieu de
  `flutter.minSdkVersion`).
- **Raison** : imposé par la section 3.

### 2026-10-09 · Identifiants des données prédéfinies (palier 1)

- **Question** : quels identifiants pour les exercices et programmes de la section 9 ?
- **Choix** : identifiants stables de type `seed_ex_...`, `seed_prog_...`, `seed_pse_...`.
- **Raison** : permet un seed idempotent (`INSERT OR IGNORE`) sans créer de doublons lors des
  mises à jour, et des références croisées déterministes entre programmes et exercices.

### 2026-10-09 · Schéma de base dès la v1 (palier 1)

- **Question** : créer tout le schéma de la section 5 dès la version 1, ou l'étendre palier par
  palier ?
- **Choix** : créer les 11 tables dès la migration v1 ; les migrations suivantes ajouteront des
  données ou des colonnes sans altérer l'existant.
- **Raison** : évite des migrations destructrices ; respecte la règle « ne jamais modifier le
  schéma sans migration versionnée conservant les données ».

### 2026-10-09 · Seed et test de la base (palier 1)

- **Question** : comment insérer et tester les données prédéfinies ?
- **Choix** : insertion dans `onCreate` (idempotente), rejouable ; tests sur une base `sqflite`
  en mémoire via `sqflite_common_ffi` (dépendance de développement uniquement).
- **Raison** : le cahier des charges exige un test automatisé prouvant la présence des 4
  programmes et de tous les exercices. Aucune dépendance d'exécution ajoutée.

## Points ouverts

- **Polices exactes** : Rajdhani et Inter retenues (cf. décision ci-dessus).
- Hypothèses retenues (section 12) sauf avis contraire : rappel d'abonnement mensuel, charges en
  kg uniquement, série de jours calculée sur le planning de salle, pas de « programme actif »,
  Android API 29 minimum, interface en français.
