# DECISIONS.md — Journal des décisions

Format : date · question · choix · raison. Toute dépendance ajoutée est justifiée ici.

## État d'avancement

- Palier 1 (Fondations) : réalisé. `flutter analyze` sans erreur, `flutter test` vert (8 tests),
  `flutter build apk --debug` réussi (`app-debug.apk` généré), pool de disque libéré (24 Go).
- Palier 2 (Exercices) : réalisé. `flutter analyze` sans erreur, `flutter test` vert (33 tests).
- Palier 3 (Programmes) : codé, en attente de commit. `flutter analyze` sans erreur,
  `flutter test` vert (63 tests : règles, repository transactionnel, duplication préservant
  l'historique, widgets liste/détail).
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

### 2026-10-09 · Identifiants UUID des exercices personnels (palier 2)

- **Question** : comment générer les UUID v4 des exercices créés par l'utilisateur ?
- **Choix** : dépendance `uuid` (^4.6.0) ajoutée.
- **Raison** : bibliothèque Dart pure, aucun accès réseau à l'exécution ; conforme à la
  convention « IDs UUID v4 (texte) » de la section 5 sans réinventer un générateur fragile.

### 2026-10-09 · Nom de la copie d'un exercice (palier 2)

- **Question** : que faire si « … (copie) » existe déjà, ou si le nom source est trop long ?
- **Choix** : la copie s'appelle « nom (copie) » ; si c'est déjà pris, suffixe numérique
  « nom (copie 2) », etc. Si la longueur dépasse 60 caractères, le nom source est tronqué.
- **Raison** : la colonne `name` est UNIQUE (RM-01) ; ces règles évitent tout conflit et
  respectent la limite 2–60 caractères.

### 2026-10-09 · Suppression d'un exercice archivé (palier 3)

- **Question** : un exercice archivé peut-il être supprimé plus tard ?
- **Choix** : **non** — l'archivage est définitif, aucune action de suppression sur un
  exercice archivé. Validation utilisateur du plan de palier 2.
- **Raison** : conserve l'intégrité de l'historique affiché ; l'archivé reste dans les
  graphiques et records mais masqué des sélecteurs.

### 2026-10-09 · Repos par défaut des lignes prévues (palier 3)

- **Question** : quel repos initial pour une ligne prévue ajoutée dans un programme ?
- **Choix** : lu dans `app_settings.default_rest_seconds` au moment de l'ajout (90 s par défaut).
- **Raison** : le réglage « Repos par défaut » de la section 7 doit s'appliquer ; pattern déjà en
  place pour le secteur séance (RM-15).

### 2026-10-09 · Bouton « Démarrer cette séance » (palier 4)

- **Question** : l'écran Détail programme doit afficher au palier 3 un bouton par séance.
- **Choix** : différé au palier 4 (Séance) qui introduit le mécanisme de démarrage et la copie RM-04.
- **Raison** : lancer une séance sans le parcours de copie serait incomplet ; le palier 3 valide la
  persistance et l'édition des programmes.

## Points ouverts

- **Polices exactes** : Rajdhani et Inter retenues (cf. décision ci-dessus).
- Hypothèses retenues (section 12) sauf avis contraire : rappel d'abonnement mensuel, charges en
  kg uniquement, série de jours calculée sur le planning de salle, pas de « programme actif »,
  Android API 29 minimum, interface en français.
