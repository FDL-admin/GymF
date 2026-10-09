# Cahier des charges — GymF, application mobile de suivi d'entraînement

*Version 1.0 · 9 octobre 2026 · Document de référence pour l'agent OpenCode (défi de comparaison de rendus)*

## 0. Règles de travail pour l'agent

1. Lis tout le document avant d'écrire du code. Il fait foi : en cas de doute, applique ce qui est écrit ici.
2. Travaille par paliers (section 10), dans l'ordre. Ne commence un palier que lorsque les critères d'acceptation du précédent sont remplis et testés.
3. N'ajoute aucune fonctionnalité absente de ce document (voir section 2). Si une information manque, choisis l'option la plus simple et note-la dans `DECISIONS.md` (date, question, choix, raison) au lieu d'improviser en silence.
4. Un commit Git par fonctionnalité terminée, message en français à l'impératif (ex. « Ajoute la création d'exercice »). Dépôt propre avant chaque palier.
5. Écris des tests automatisés pour toute la logique métier (règles RM-xx, calculs, planification des notifications). Les écrans se vérifient à la main sur un appareil Android réel.
6. Tous les textes visibles par l'utilisateur sont en français. Les identifiants de code sont en anglais.
7. Chaque dépendance ajoutée est justifiée dans `DECISIONS.md`. Aucune dépendance ne doit exiger Internet à l'exécution.
8. Crée dès le palier 1 et tiens à jour : `AGENTS.md` (résumé du projet, commandes, conventions), `DESIGN.md` (tokens de la section 8), `DECISIONS.md`.
9. Ne modifie jamais le schéma de la base sans migration versionnée qui conserve les données existantes.

## 1. Vision et périmètre

Application mobile **100 % hors ligne** de suivi de musculation, à usage personnel, nommée GymF. Elle est installée directement sur les smartphones de ses deux auteurs : un seul utilisateur par installation, **pas de compte, pas de serveur, pas de synchronisation, pas de déploiement**. Plateforme de test : **Android** (appareils réels).

Trois piliers :

- **Bibliothèque** : exercices et programmes (prédéfinis + créés par l'utilisateur, avec texte et images).
- **Séance** : enregistrement d'une séance selon **un seul scénario nominal** (section 6.2), avec ou sans programme.
- **Suivi** : historique, records, série de jours, graphiques, photos de progression, rappels.

Les exercices se mesurent uniquement en **répétitions × charge (kg)**. L'habillage visuel s'inspire de l'univers Solo Leveling : **skin uniquement**, aucune mécanique de jeu.

## 2. Hors périmètre (interdit en v1)

Comptes et connexion · serveur, cloud, synchronisation, appels réseau · paiement ou abonnement à l'app · social (partage, fil, amis, guildes, classements) · IA ou génération de programmes · montres, Health Connect, Apple Health · nutrition · exercices chronométrés et cardio · unités en livres · plusieurs langues · mode clair · tablette · **mécanique de jeu (XP, niveaux, rangs, quêtes, pénalités, donjons, classes)** · réordonner par glisser-déposer · supersets, séries d'échauffement distinctes, RPE · calculateur de disques · export CSV · modification d'une séance terminée · notifications push distantes.

## 3. Contraintes techniques

**Stack décidée : Flutter (Dart) seul, Android uniquement. Aucun serveur, aucun Django, aucune API.** Création du projet : `flutter create --platforms=android --org com.gymf --project-name gymf .` (nom de l'application : **GymF**). Paquets imposés, à justifier dans `DECISIONS.md` s'ils changent :

- Stockage : `sqflite` + `path_provider`, SQL brut, migrations via `onUpgrade` (pas de génération de code).
- Gestion d'état : `flutter_riverpod`.
- Notifications : `flutter_local_notifications` + `timezone` + `flutter_timezone`, programmation avec `zonedSchedule`, deux canaux Android à importance haute (« rappels » et « chrono »).
- Images : `image_picker` (caméra et galerie) avec `maxWidth` et `maxHeight` à 1280 et `imageQuality` à 80, ce qui applique RM-23 sans autre paquet.
- Graphiques : `fl_chart`.
- Export et import : `share_plus` et `file_picker`.
- Polices : Rajdhani et Inter déclarées comme assets dans `pubspec.yaml` (jamais de `google_fonts` à l'exécution).
- Fin du chrono : toujours afficher la notification locale du canal « chrono » (son + vibration), y compris au premier plan ; pas de paquet audio supplémentaire.
- Architecture : la logique métier (règles RM-xx, calculs, planification des notifications) est écrite en Dart pur, sans dépendance à Flutter, et testée avec `flutter_test` ; les écrans ne contiennent aucune règle métier.
- `minSdkVersion` à 29 ; `pubspec.lock` versionné.

Exigences à respecter :

- Android récent (API 29 minimum).
- Base relationnelle locale (SQLite) avec migrations versionnées.
- Notifications locales programmées, y compris application fermée.
- Aucun appel réseau. Permissions autorisées : notifications, caméra, accès aux photos. Rien d'autre, hormis les permissions techniques nécessaires à des rappels fiables : alarmes exactes et reprogrammation après redémarrage.
- Le chrono se calcule à partir d'une **heure de fin** enregistrée, jamais en comptant des ticks.

Points Android à valider sur appareil réel au palier 7 : permission de notification (Android 13+), alarmes exactes (Android 12+), retards possibles dus aux économiseurs de batterie. Tolérance acceptée : ± 2 minutes. Documente le comportement observé dans `DECISIONS.md`.

Dans `AndroidManifest.xml`, déclarer les permissions `POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`, `RECEIVE_BOOT_COMPLETED` et `CAMERA`, ainsi que les récepteurs de `flutter_local_notifications` décrits dans la documentation du paquet, pour que les rappels survivent à un redémarrage. Selon la version d'Android, l'autorisation des alarmes exactes se donne dans les réglages système : prévoir un bouton qui y mène depuis Réglages.

## 4. Glossaire (vocabulaire à respecter partout)

- **Exercice** (`Exercise`) : mouvement de la bibliothèque (ex. Squat).
- **Programme** (`Program`) : ensemble nommé de séances types (ex. Push / Pull / Legs).
- **Séance type** (`ProgramSession`) : modèle de séance dans un programme (ex. Push).
- **Ligne prévue** (`ProgramSessionExercise`) : exercice d'une séance type, avec séries cibles, plage de répétitions et repos.
- **Séance** (`WorkoutSession`) : séance effectuée ou en cours. C'est toujours une **copie** (RM-04).
- **Série** (`WorkoutSet`) : une série effectuée = répétitions + charge.
- **Séance libre** : séance sans programme.
- **Volume** : somme de répétitions × charge des séries validées.
- **Jour d'entraînement** : jour local comptant au moins une séance terminée.
- **Créneau de salle** (`GymSlot`) : un jour de semaine + une heure habituelle.

## 5. Modèle de données

Conventions : identifiants UUID v4 (texte) · dates `created_at` en ISO 8601 UTC · « jour » calendaire calculé en heure locale de l'appareil · charges en kg avec une décimale maximale · `position` entier commençant à 0 · tous les champs listés sont obligatoires sauf mention « nullable ».

- **Exercise** : `id` · `name` (2–60 caractères, unique) · `muscle_group` (pectoraux, dos, epaules, biceps, triceps, jambes, fessiers, abdominaux, mollets, avant\_bras, corps\_entier) · `description` (nullable, ≤ 1000) · `image_path` (nullable) · `is_predefined` · `is_archived` (défaut faux) · `created_at`.
- **Program** : `id` · `name` (2–60, unique) · `description` (nullable) · `image_path` (nullable) · `is_predefined` · `created_at`.
- **ProgramSession** : `id` · `program_id` · `name` · `position`. Suppression en cascade avec le programme.
- **ProgramSessionExercise** : `id` · `program_session_id` · `exercise_id` · `position` · `target_sets` (1–10, défaut 3) · `target_reps_min` et `target_reps_max` (nullable, 1–100, min ≤ max) · `rest_seconds` (15–600, défaut 90).
- **WorkoutSession** : `id` · `program_id` (nullable, mis à NULL si le programme est supprimé) · `name` (copie du nom de la séance type, ou « Séance libre ») · `status` (`in_progress`, `completed`, `abandoned`) · `started_at` · `ended_at` (nullable) · `note` (nullable).
- **WorkoutExercise** : `id` · `workout_session_id` · `exercise_id` · `exercise_name` (copie du nom) · `position` · `rest_seconds`.
- **WorkoutSet** : `id` · `workout_exercise_id` · `position` · `reps` (entier 0–999, nullable) · `weight_kg` (0–999.9, nullable) · `is_done` · `completed_at` (nullable).
- **GymSlot** : `id` · `weekday` (1 = lundi … 7 = dimanche, un seul créneau par jour) · `time` (HH:mm) · `enabled`.
- **SubscriptionReminder** (une seule ligne) : `enabled` · `day_of_month` (1–31) · `time` (HH:mm, défaut 09:00).
- **ProgressPhoto** : `id` · `taken_on` (date locale) · `image_path` · `note` (nullable) · `created_at`.
- **AppSettings** : `default_rest_seconds` (défaut 90) · `schema_version`.

## 6. Règles métier

### 6.1 Règles numérotées

**Bibliothèque**

- **RM-01** Les noms d'exercices (et de programmes) sont uniques, sans tenir compte de la casse ni des espaces de bord. Le message d'erreur s'affiche sous le champ.
- **RM-02** Les exercices et programmes prédéfinis ne sont ni modifiables ni supprimables. L'action « Dupliquer » crée une copie personnelle modifiable nommée « … (copie) ».
- **RM-03** Supprimer un exercice personnel : s'il n'a jamais servi dans une séance, suppression définitive après confirmation ; sinon, **archivage** (masqué des sélecteurs, conservé dans l'historique et les graphiques). Supprimer un programme : suppression définitive après confirmation, les séances passées ne sont pas touchées.

**Séance**

- **RM-04** Démarrer depuis une séance type crée une **copie** : un `WorkoutExercise` par ligne prévue, avec `target_sets` séries vides et non validées. Modifier le programme ensuite ne change jamais une séance existante.
- **RM-05** Une séance libre démarre vide ; l'utilisateur ajoute des exercices depuis la bibliothèque.
- **RM-06** À tout moment pendant la séance, l'utilisateur peut : ajouter un exercice (refusé s'il est déjà dans la séance), retirer un exercice (confirmation si des séries sont validées), ajouter ou supprimer une série. Suivre le programme n'est jamais obligatoire.
- **RM-07** Une seule séance `in_progress` à la fois. Chaque action est sauvegardée immédiatement. Si l'app est fermée ou tuée, la séance est restaurée à l'identique à la réouverture. Un bandeau « Séance en cours » reste visible sur tous les onglets.
- **RM-08** Valider une série exige `reps` ≥ 1 ; une charge vide vaut 0 (poids du corps). Valider met `is_done` à vrai, enregistre `completed_at` et démarre le chrono (RM-15). La dé-validation est possible et arrête le chrono.
- **RM-09** **Pré-remplissage.** La série n° k d'un exercice est pré-remplie avec les répétitions et la charge de la série n° k de la dernière séance terminée contenant cet exercice ; s'il n'y a pas de série k, avec la dernière série de cette séance ; sinon elle reste vide. Chaque ligne affiche « Précédent : 8 × 60 kg » (ou « — »). Les valeurs pré-remplies sont modifiables et ne comptent que lorsque la série est validée.
- **RM-10** Terminer exige au moins une série validée. À la fin, les séries non validées et les exercices sans série validée sont supprimés de la séance, le statut passe à `completed` et `ended_at` est renseigné. Sans série validée, seule l'action « Abandonner » est proposée : statut `abandoned`, séance exclue de l'historique, des graphiques, des records et de la série de jours.
- **RM-11** Durée d'une séance = `ended_at` − `started_at`, affichée en minutes.

**Calculs**

- **RM-12** Volume d'une séance (ou d'un exercice) = Σ `reps` × `weight_kg` des séries validées.
- **RM-13** Charge max d'un exercice dans une séance = plus grande `weight_kg` de ses séries validées.
- **RM-14** **Record personnel.** À la fin d'une séance, un exercice établit un record si sa charge max de la séance est **strictement supérieure** à toutes ses charges max précédentes (séances terminées) **et** s'il existait au moins une séance antérieure avec cet exercice. Première fois = pas de record. Égalité = pas de record. Charge max à 0 = pas de record. Badge « RECORD » dans le récapitulatif et dans l'historique. Le détail d'un exercice affiche son record actuel.

**Chrono de repos**

- **RM-15** Durée = `rest_seconds` de l'exercice. Démarre à la validation d'une série. Affiche un compte à rebours avec les boutons −15 s, +15 s, Passer, Redémarrer. L'état est stocké sous forme d'**heure de fin** et se recalcule à la réouverture. À zéro : vibration + son, et notification locale si l'app est en arrière-plan ou l'écran verrouillé. Valider une autre série pendant un chrono le redémarre. Terminer ou abandonner la séance l'annule.

**Planning, rappels, série**

- **RM-16** Planning de salle : au plus un créneau par jour de semaine, activable ou non.
- **RM-17** Rappel avant : pour chaque créneau activé, notification à heure − 10 min. Texte : « \[Système\] Ta séance commence dans 10 minutes. »
- **RM-18** Rappel après : notification à heure + 60 min, **uniquement** si aucune séance (en cours ou terminée) n'a son `started_at` ce jour-là en heure locale. Texte : « \[Système\] Aucune séance enregistrée aujourd'hui. Mets ton journal à jour. » **Mécanisme obligatoire** (les notifications locales ne peuvent pas tester une condition au déclenchement) : programmer des notifications ponctuelles pour les **14 prochains jours**, avec identifiants déterministes (`pre_AAAA-MM-JJ`, `post_AAAA-MM-JJ`, `sub_AAAA-MM-JJ`), via une fonction idempotente `resynchroniserNotifications()` appelée au lancement de l'app, à chaque modification des créneaux ou de l'abonnement, et à chaque démarrage ou fin de séance. Dès qu'une séance démarre, la notification `post_` du jour est annulée. Ne pas programmer une occurrence déjà passée. Si l'app n'est pas ouverte pendant 14 jours, les rappels s'arrêtent : limitation acceptée.
- **RM-19** Abonnement : si activé, notification le jour `day_of_month` à l'heure choisie ; si le mois est plus court, le dernier jour du mois (fenêtre de programmation : 45 jours). Texte : « \[Système\] Rappel : paiement de l'abonnement de la salle aujourd'hui. »
- **RM-20** La permission de notification est demandée à l'activation du premier rappel. Si elle est refusée, un bandeau permanent « Notifications désactivées » apparaît dans Réglages, avec un bouton vers les réglages système.
- **RM-21** **Série de jours.** On parcourt en arrière les jours **planifiés** (ceux dont le jour de semaine a un créneau activé) à partir d'aujourd'hui. Aujourd'hui, s'il est planifié et sans séance terminée, est « en attente » et ignoré. Chaque jour planifié passé avec au moins une séance terminée ajoute 1 ; le premier jour planifié passé sans séance terminée arrête le comptage. Les jours non planifiés sont ignorés. Sans créneau défini, aucune série n'est affichée et un message invite à définir le planning.

**Graphiques**

- **RM-22** Graphique A, « Progression par exercice » : sélecteur d'exercice (uniquement ceux ayant au moins une séance terminée) ; courbe avec x = date de la séance et y = charge max (RM-13) ; un point touché affiche valeur et date. Graphique B, « Volume par séance » : barres avec x = date et y = volume total (RM-12). Filtre de période : 1 mois, 3 mois, 6 mois, Tout (défaut : 3 mois). Moins de 2 points : message « Pas encore assez de données ». Bibliothèque de graphiques libre (ou SVG), mais hors ligne, couleurs des tokens, axes sobres.

**Images**

- **RM-23** Toute image choisie est **copiée** dans le stockage privé de l'app (jamais seulement référencée dans la galerie), redimensionnée à 1280 px maximum sur le grand côté, en JPEG qualité 80 ; seul un chemin relatif est stocké. Le fichier est supprimé quand l'élément parent est supprimé ou l'image remplacée. Photos de progression : prise caméra ou import galerie, plusieurs par jour autorisées ; comparaison avant/après en choisissant deux photos affichées côte à côte avec leur date.

**Sauvegarde**

- **RM-24** Export JSON complet depuis Réglages (champ `schema_version`, données personnelles et historique, **sans** images ni éléments prédéfinis), partagé via le menu de partage système. Import JSON : refus si `schema_version` inconnu ou supérieur, confirmation « Remplace toutes les données personnelles », exécution en **transaction** (tout ou rien).

### 6.2 Scénario nominal d'une séance (toujours le même)

1. Accueil → « Démarrer une séance ».
2. Choix : « Depuis un programme » (programme → séance type) ou « Séance libre ».
3. La séance est créée (RM-04 ou RM-05) et l'écran « Séance en cours » s'ouvre.
4. Pour chaque série : saisir répétitions et charge (pré-remplies selon RM-09), puis valider.
5. Le chrono de repos démarre (RM-15).
6. À tout moment : ajouter ou retirer un exercice, une série (RM-06).
7. « Terminer » → récapitulatif (durée, séries validées, volume, badges RECORD, note facultative) → « Enregistrer ».
8. La séance apparaît dans l'Historique.

Variantes : abandon (RM-10), app tuée en séance (RM-07), séance sans programme (RM-05).

## 7. Écrans et navigation

Barre d'onglets inférieure à 5 entrées : **Accueil · Bibliothèque · Historique · Suivi · Réglages**. Le bandeau « Séance en cours » se place au-dessus de la barre et ramène à la séance. Chaque liste a un état vide avec message et action.

- **Accueil** : prochain créneau de salle, série de jours (RM-21), résumé de la dernière séance (nom, date, volume), bouton « Démarrer une séance ». Il n'existe pas de notion de « programme actif ».
- **Bibliothèque** : bascule Exercices / Programmes.
  - *Exercices* : liste alphabétique, recherche, filtre par groupe musculaire, bouton +. Détail : nom, groupe, description, image, record actuel, actions Modifier / Dupliquer / Archiver ou Supprimer.
  - *Programmes* : liste ; détail avec séances types et bouton « Démarrer cette séance » ; création et édition (nom, description, image, séances types, lignes prévues avec exercice, séries cibles, plage de répétitions, repos) ; Dupliquer ; Supprimer.
- **Séance en cours** (plein écran) : nom, durée écoulée, bouton « Terminer ». Une carte par exercice avec un tableau de séries (n° · Précédent · kg · reps · case de validation), « + Série », « Retirer l'exercice ». En bas : « + Ajouter un exercice » et le panneau du chrono de repos. Saisie au clavier numérique ; la virgule décimale est acceptée et normalisée.
- **Historique** : bascule Liste / Calendrier. Liste des séances terminées, plus récentes d'abord (date, nom, durée, volume, badges RECORD). Calendrier mensuel avec jours d'entraînement marqués ; toucher un jour affiche ses séances. Détail d'une séance (exercices et séries) avec action « Supprimer la séance » (confirmation).
- **Suivi** : bascule Graphiques (RM-22) / Photos (grille par date, ajout, comparaison avant/après).
- **Réglages** : Planning de salle · Abonnement · Repos par défaut · Sauvegarde (export / import) · À propos.

## 8. Skin (thème Solo Leveling) et ton

Thème sombre unique. Tokens à placer dans `DESIGN.md` et à utiliser partout, sans couleur codée en dur :

- Fond `#0A0E1A` · surface (panneaux) `#0F1830` · surface élevée `#162247`
- Bordure et accent principal `#2E6BFF` / `#4DD0FF` · accent secondaire `#7B4DFF`
- Succès (série validée) `#3DDC97` · danger `#FF3B5C`
- Texte `#E6F0FF` · texte atténué `#8EA2C8`
- Lueur : `0 0 12px rgba(46,107,255,0.45)` · espacements 4 / 8 / 12 / 16 / 24 · rayons 4 px (angles nets).

Typographie : titres **Rajdhani** (600/700), texte et chiffres **Inter** (chiffres tabulaires, saisie ≥ 20 sp), polices embarquées localement (hors ligne).

Composants :

- **Panneau « fenêtre système »** : fond surface, bordure 1 px accent à 60 %, légère lueur, titre en majuscules espacées.
- Bouton primaire (fond accent, texte sombre, majuscules), secondaire (contour), danger.
- Série validée : coche verte et ligne légèrement lumineuse. Badge RECORD en accent secondaire.

Animations (≤ 300 ms, désactivées si le système demande de réduire les animations) : écran de lancement façon « démarrage du système » d'au plus 1,2 s, passable au toucher ; apparition des panneaux en fondu avec 8 px de translation ; flash discret à la fin de séance.

Lisibilité en salle (prioritaire sur l'esthétique) : cibles tactiles ≥ 48 dp, contraste AA minimum, **aucun effet de lueur sur les champs de saisie**.

Ton des textes : sobre et direct ; le préfixe « \[Système\] » est réservé aux notifications.

**Interdits** : aucune illustration, logo, police, nom ou citation de l'œuvre originale ; icônes issues d'une bibliothèque libre de droits.

## 9. Données prédéfinies (insérées au premier lancement)

Insertion par migration idempotente, identifiants stables (`seed_...`), `is_predefined` = vrai ; une mise à jour ne doit jamais créer de doublons. Rédige pour chaque programme une description de 1 à 2 phrases. Aucune image au départ.

**Exercices** (groupe) :

- pectoraux : Développé couché, Développé incliné haltères, Écartés poulie, Pompes
- dos : Tractions, Tirage vertical, Rowing barre, Rowing haltère, Soulevé de terre
- epaules : Développé militaire, Élévations latérales, Oiseau haltères
- biceps : Curl barre, Curl haltères, Curl marteau
- triceps : Dips, Extensions triceps poulie, Barre au front
- jambes : Squat, Presse à cuisses, Fentes, Leg extension, Leg curl, Soulevé de terre roumain
- fessiers : Hip thrust · mollets : Mollets debout · abdominaux : Crunch, Relevé de jambes

**Programmes** (séries × répétitions ; repos 90 s sauf mention) :

1. **Full Body (A/B)**. A : Squat 3×5-8 · Développé couché 3×6-10 · Rowing barre 3×6-10 · Développé militaire 2×8-12 · Curl barre 2×10-12. B : Soulevé de terre roumain 3×6-10 · Développé incliné haltères 3×8-12 · Tirage vertical 3×8-12 · Fentes 2×10-12 · Extensions triceps poulie 2×10-12.
2. **Push / Pull / Legs**. Push : Développé couché 4×6-10 · Développé militaire 3×8-12 · Développé incliné haltères 3×8-12 · Élévations latérales 3×12-15 · Extensions triceps poulie 3×10-15. Pull : Tractions 4×6-10 · Rowing barre 3×8-12 · Tirage vertical 3×8-12 · Oiseau haltères 3×12-15 · Curl haltères 3×10-12. Legs : Squat 4×6-10 · Presse à cuisses 3×10-12 · Soulevé de terre roumain 3×8-12 · Leg curl 3×10-15 · Mollets debout 4×12-15.
3. **Upper / Lower**. Upper : Développé couché 4×6-10 · Rowing barre 4×6-10 · Développé militaire 3×8-12 · Tirage vertical 3×8-12 · Curl barre 2×10-12 · Extensions triceps poulie 2×10-12. Lower : Squat 4×6-10 · Soulevé de terre roumain 3×8-10 · Presse à cuisses 3×10-12 · Leg curl 3×10-12 · Mollets debout 4×12-15 · Crunch 3×12-15.
4. **5×5 (A/B)**, repos 180 s. A : Squat 5×5 · Développé couché 5×5 · Rowing barre 5×5. B : Squat 5×5 · Développé militaire 5×5 · Soulevé de terre 1×5.

Ce sont des modèles génériques indicatifs, pas des conseils d'entraînement personnalisés.

## 10. Paliers d'itération et critères d'acceptation

1. **Fondations.** Projet lançable sur Android ; navigation à 5 onglets (écrans vides) ; tokens et polices ; SQLite avec migrations ; données de la section 9 ; `AGENTS.md`, `DESIGN.md`, `DECISIONS.md`. *Accepté si* : l'app s'ouvre hors ligne, les onglets se parcourent, les 4 programmes et tous les exercices existent en base (test automatisé).
2. **Exercices.** Liste, recherche, filtre, création, modification, duplication, archivage ou suppression (RM-01 à RM-03). *Accepté si* : tests RM-01/02/03 passent ; un doublon est refusé ; un exercice archivé disparaît des sélecteurs.
3. **Programmes.** Liste, détail, création et édition complètes, duplication, suppression. *Accepté si* : un programme de 2 séances types × 3 exercices est créé et survit à un redémarrage.
4. **Séance (cœur).** Démarrage programme ou libre, copie (RM-04), saisie, validation (RM-08), pré-remplissage (RM-09), ajout et retrait (RM-06), terminer ou abandonner (RM-10), restauration (RM-07), récapitulatif. *Accepté si* : le scénario nominal 6.2 se déroule de bout en bout ; tuer l'app en séance puis la rouvrir restaure tout ; tests RM-04 à RM-13 passent.
5. **Chrono.** RM-15. *Accepté si* : sur appareil réel, il sonne et vibre écran verrouillé, et le décompte reste exact après un retour d'arrière-plan.
6. **Historique et records.** Liste, calendrier, détail, suppression d'une séance, RM-14. *Accepté si* : tests de record (première fois = non, égalité = non, supérieur = oui).
7. **Planning, rappels, série, abonnement.** RM-16 à RM-21. *Accepté si* : rappels reçus à ± 2 min sur appareil réel ; le rappel « après » est annulé quand une séance démarre ; tests de `resynchroniserNotifications()` et de l'algorithme de série.
8. **Graphiques.** RM-22. *Accepté si* : les deux graphiques fonctionnent hors ligne avec les 4 périodes et l'état « pas assez de données ».
9. **Images et photos.** RM-23 sur exercices, programmes et photos de progression, avec comparaison. *Accepté si* : une image reste visible après suppression de l'original dans la galerie ; les fichiers sont supprimés avec leur élément.
10. **Sauvegarde et finition.** RM-24, états vides, messages d'erreur, revue des permissions, essai complet sur un second appareil Android. *Accepté si* : un export importé sur un autre appareil restitue toutes les données ; la checklist du scénario nominal passe.

## 11. Cas limites à gérer

- Changement d'heure ou de fuseau : les rappels sont recalculés au lancement (RM-18).
- Séance qui passe minuit : le jour d'entraînement est celui de `started_at`.
- Permissions refusées : tout fonctionne sauf rappels et photos, avec un message clair.
- Champs vides, négatifs ou non numériques : refusés avec message ; virgule décimale acceptée.
- Échec d'écriture d'une image (stockage plein) : message, pas de plantage, rien n'est créé.
- Deux séances le même jour : autorisées.
- Import invalide ou de version supérieure : refusé, données intactes.
- Programme sans séance type, ou séance type sans exercice : démarrage refusé avec message.
- Séance en cours depuis plus de 24 h au lancement : proposer « Reprendre » ou « Abandonner ».

## 12. Hypothèses retenues et points à confirmer

Hypothèses appliquées sauf avis contraire : rappel d'abonnement **mensuel** ; charges en **kg** uniquement ; série de jours calculée sur le **planning de salle** (une série quotidienne se casserait à chaque jour de repos) ; pas de « programme actif » ; Android API 29 minimum ; interface en français.

**Décisions prises :** stack **Flutter seul** (section 3) et nom de l'application **GymF**. Reste à confirmer : les polices exactes (Rajdhani et Inter sont des suggestions libres de droits).
