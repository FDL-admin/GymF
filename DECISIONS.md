# DECISIONS.md — Journal des décisions

Format : date · question · choix · raison. Toute dépendance ajoutée est justifiée ici.

## État d'avancement

- Palier 1 (Fondations) : réalisé. `flutter analyze` sans erreur, `flutter test` vert (8 tests),
  `flutter build apk --debug` réussi (`app-debug.apk` généré), pool de disque libéré (24 Go).
- Palier 2 (Exercices) : réalisé. `flutter analyze` sans erreur, `flutter test` vert (33 tests).
- Palier 3 (Programmes) : réalisé. `flutter analyze` sans erreur, `flutter test` vert (63 tests :
  règles, repository transactionnel, duplication préservant l'historique, widgets liste/détail).
  Commit `dfcd798`.
- Palier 4 (Séance) : réalisé. `flutter analyze` sans erreur, `flutter test` vert (95 tests :
  RM-04 à RM-13, règles pures, repository, bandeau widget). Commit `a8a3f47`.
- Palier 5 (Chrono de repos) : réalisé. Migration v2 (`rest_end_at`, `rest_total_seconds`),
  `RestTimer` pur, service de notifications (`flutter_local_notifications` + `timezone` +
  `flutter_timezone`), canal « chrono », config Android (desugaring, permissions, receivers,
  icône). `flutter analyze` sans erreur, `flutter test` vert (101 tests). Commit `04a5e5e`.
- Palier 6 (Historique et records) : réalisé. `HistoryRepository` (liste, calendrier, détail,
  suppression, records), RM-14 par exercice (badge récapitulatif + historique, record actuel
  dans le détail d'exercice), écrans Liste/Calendrier et détail. `flutter analyze` sans erreur,
  `flutter test` vert (121 tests).
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

### 2026-10-09 · Démarrage de séance : accès depuis l'Accueil (palier 4)

- **Question** : où placer l'action « Démarrer une séance » (scénario 6.2) ?
- **Choix** : bouton sur l'écran Accueil, avec une feuille de démarrage « Séance libre » ou
  « Depuis un programme » (choix programme puis séance type).
- **Raison** : le scénario nominal part de l'Accueil ; chaque séance type reste démarrable depuis
  son détail aux paliers ultérieurs sans changement de mécanique.

### 2026-10-09 · Séries créées pour un exercice ajouté en cours (palier 4)

- **Question** : combien de séries à la création quand on ajoute un exercice en séance (RM-05) ?
- **Choix** : une série vide (mais pré-remplie selon RM-09 si un historique existe) ; l'utilisateur
  ajoute ensuite des séries avec « ＋ Série ».
- **Raison** : RM-06 dit « ajouter ou supprimer une série » ; partir d'une seule ligne donne une
  saisie immédiate sans imposer un nombre arbitraire.

### 2026-10-09 · Pré-remplissage des séries ajoutées en cours (palier 4)

- **Question** : les séries ajoutées pendant la séance sont-elles pré-remplies aussi (RM-09) ?
- **Choix** : oui — toute nouvelle série suit la règle RM-09 (série k du précédent, sinon
  dernière série). Validation utilisateur du plan de palier 4.
- **Raison** : cohérent avec le pré-remplissage présenté à la création de la séance.

### 2026-10-09 · Durée affichée pendant la séance (palier 4)

- **Question** : RM-11 affiche la durée en minutes en fin de séance, mais pendant la séance ?
- **Choix** : compteur « mm:ss » (ou « h:mm:ss » au-delà d'une heure) pendant la séance ; le
  récapitulatif garde la durée en minutes. Validation utilisateur du plan de palier 4.
- **Raison** : un chrono au format temps convient à l'écran en cours ; le cahier ne le précise pas.

### 2026-10-09 · Dépendances du chrono de repos (palier 5)

- **Question** : comment sonner/vibrer écran verrouillé et programmer l'alerte à une heure exacte ?
- **Choix** : `flutter_local_notifications` (^19), `timezone` (^0.10) et `flutter_timezone` (^4)
  ajoutés ; programmation dans le fuseau local via `zonedSchedule` en mode inexact.
- **Raison** : seuls moyens hors ligne d'émettre une notification sonore/vibrante à échéance ;
  `timezone` + `flutter_timezone` fournissent le fuseau « heure d'été » correct sans réseau.
  Desugaring Android activé (`desugar_jdk_libs`) comme exigé par le greffon.

### 2026-10-09 · Séances abandonnées dans l'historique (palier 6)

- **Question** : l'historique et les records incluent-ils les séances abandonnées ?
- **Choix** : non — seules les séances **terminées** apparaissent et comptent pour RM-14 ;
  les abandonnées restent en base mais sont masquées.
- **Raison** : la section 7 décrit l'historique comme « liste des séances terminées » et RM-14
  compare aux « séances terminées ».

### 2026-10-09 · Portée du badge RECORD (palier 6)

- **Question** : le badge RECORD est-il par série ou par exercice ?
- **Choix** : **par exercice et par séance** — la charge max de la séance pour un exercice doit
  être strictement supérieure à toutes ses charges max précédentes, et au moins une séance
  antérieure avec cet exercice doit exister. Affiché dans le récapitulatif, l'historique, et le
  détail d'exercice montre le record actuel.
- **Raison** : texte exact de RM-14 (« sa charge max de la séance »), section 7 (badges RECORD) et
  section 8 (badge en accent secondaire).

### 2026-10-10 · Fenêtre de programmation des rappels (palier 7)

- **Question** : comment garantir les rappels RM-17/RM-18 sans service d'arrière-plan ni réseau ?
- **Choix** : programmer à l'avance les 14 prochains jours pour les rappels de séance et 45 jours
  pour l'abonnement, avec des identifiants déterministes (`pre_AAAA-MM-JJ`, `post_AAAA-MM-JJ`,
  `sub_AAAA-MM-JJ`) et une fonction idempotente `resynchroniserNotifications()` appelée au
  lancement, à la reprise, et à chaque modification (créneaux, abonnement, début/fin de séance).
- **Raison** : RM-18 l'impose explicitement ; limitation acceptée par le cahier : si l'application
  n'est pas ouverte pendant 14 jours, les rappels s'arrêtent.

### 2026-10-10 · Resynchronisation par annulation globale (palier 7)

- **Question** : comment rendre `resynchroniserNotifications()` idempotente avec des identifiants
  pseudo-aléatoires en entier ?
- **Choix** : annuler toutes les notifications puis reprogrammer la fenêtre complète ; l'identifiant
  entier est dérivé de façon stable (FNV-1a) de l'identifiant textuel.
- **Raison** : garantit l'absence de doublons ou de rappels obsolètes sans suivre l'ensemble des
  identifiants précédents entre deux lancements. Le chrono de repos, transitoire, est reprogrammé
  au besoin.

### 2026-10-10 · Accès aux réglages système sans dépendance (palier 7)

- **Question** : RM-20 demande un bouton vers les réglages système ; quelle dépendance utiliser ?
- **Choix** : aucun paquet ajouté — un `MethodChannel` (`gymf/app_settings`) ouvre
  `ACTION_APPLICATION_DETAILS_SETTINGS` depuis `MainActivity`.
- **Raison** : évite une dépendance supplémentaire (le greffon `permission_handler` exigeait une
  plateforme SDK non disponible) tout en conservant un fonctionnement 100 % hors ligne.

### 2026-10-10 · Bibliothèque de graphiques (palier 8)

- **Question** : comment tracer la progression (RM-22) hors ligne ?
- **Choix** : `fl_chart` (^1.2) ajouté ; courbe pour la charge max par séance, barres pour le
  volume par séance ; période par défaut 3 mois ; axage sobre aux couleurs des tokens.
- **Raison** : paquet imposé par la section 3, pur Flutter, aucun réseau. Les séries sont
  calculées en SQL puis filtrées selon la période choisie (`TrackingPeriod.startFrom`).

### 2026-10-10 · Axe des graphiques en index (palier 8)

- **Question** : comment positionner des points dont l'axe est une date ?
- **Choix** : l'abscisse est l'index du point (0..n-1) ; les dates réelles servent aux libellés et
  aux infobulles.
- **Raison** : évite les très grands nombres d'un horodatage en millisecondes dans `fl_chart` et
  aligne simplement courbe et barres.

### 2026-10-10 · Stockage et cycle de vie des images (palier 9)

- **Question** : où stocker les images (RM-23) et comment garantir qu'aucun fichier ne fuit ?
- **Choix** : `image_picker` (^1.2) ajouté (`maxWidth`/`maxHeight` 1280, `imageQuality` 80) ;
  les fichiers sont copiés dans un dossier privé `images/` sous le répertoire de documents de
  l'app, et la base ne stocke qu'un **chemin relatif**. Un `ImageStore` (répertoire de base
  injectable) expose `saveBytes`/`copy`/`delete`. Les repositories n'écrivent que le chemin ;
  l'enregistrement/suppression des fichiers se fait côté écran, après validation du formulaire.
- **Raison** : respecte la section 3 (dépendance et permission caméra imposées) et RM-23
  (chemin relatif, redimensionnement). Créer le fichier seulement après validation évite les
  orphelins si l'utilisateur annule ; les fichiers sont supprimés au remplacement, à la
  suppression de l'élément parent ou à la duplication (copie dédiée).

### 2026-10-10 · Provider ImageStore sans accès disque au démarrage (palier 9)

- **Question** : comment fournir `ImageStore` aux écrans sans casser les tests widget existants ?
- **Choix** : `ImageStore` résout son répertoire de base **paresseusement** ; le provider le
  construit sans appel `path_provider`. Les écrans ne touchent au disque qu'en présence d'une
  image ou lors d'une action utilisateur.
- **Raison** : les écrans de création sans image ne déclenchent aucun accès disque ; les tests
  qui n'exercent pas les images n'ont pas à surcharger le provider.

## Points ouverts

- **Polices exactes** : Rajdhani et Inter retenues (cf. décision ci-dessus).
- Hypothèses retenues (section 12) sauf avis contraire : rappel d'abonnement mensuel, charges en
  kg uniquement, série de jours calculée sur le planning de salle, pas de « programme actif »,
  Android API 29 minimum, interface en français.
