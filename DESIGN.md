# DESIGN.md — Tokens et thème GymF

Thème sombre unique, skin inspiré de Solo Leveling (habillage visuel seulement, aucune mécanique
de jeu). Aucune couleur codée en dur : utiliser exclusivement les tokens ci-dessous, regroupés
dans un fichier de thème central.

## Couleurs

| Token | Valeur | Usage |
|---|---|---|
| `background` | `#0A0E1A` | Fond général |
| `surface` | `#0F1830` | Panneaux |
| `surfaceElevated` | `#162247` | Surface élevée |
| `border` | `#2E6BFF` | Bordure / accent principal |
| `accentPrimary` | `#4DD0FF` | Accent principal |
| `accentSecondary` | `#7B4DFF` | Accent secondaire (badge RECORD) |
| `success` | `#3DDC97` | Série validée |
| `danger` | `#FF3B5C` | Danger |
| `text` | `#E6F0FF` | Texte principal |
| `textMuted` | `#8EA2C8` | Texte atténué |

## Lueur (glow)

- `glow` : `0 0 12px rgba(46,107,255,0.45)`.
- **Aucun effet de lueur sur les champs de saisie** (lisibilité en salle).

## Espacements

`4 / 8 / 12 / 16 / 24` (dp).

## Rayons

`4 px` — angles nets.

## Typographie

- Titres : **Rajdhani** (graisses 600 / 700).
- Texte et chiffres : **Inter** (chiffres tabulaires ; champ de saisie ≥ 20 sp).
- Polices embarquées localement dans `assets/` et déclarées dans `pubspec.yaml` (hors ligne).

## Composants

- **Panneau « fenêtre système »** : fond `surface`, bordure 1 px `border` à 60 %, légère lueur,
  titre en majuscules espacées.
- **Boutons** : primaire (fond accent, texte sombre, majuscules), secondaire (contour), danger.
- **Série validée** : coche `success` et ligne légèrement lumineuse.
- **Badge RECORD** : `accentSecondary`.

## Animations

- Durée ≤ 300 ms ; désactivées si le système demande de réduire les animations.
- Lancement façon « démarrage du système » d'au plus 1,2 s, passable au toucher.
- Apparition des panneaux en fondu avec 8 px de translation.
- Flash discret à la fin de séance.

## Accessibilité (prioritaire sur l'esthétique)

- Cibles tactiles ≥ 48 dp.
- Contraste AA minimum.
- Pas de lueur sur les champs de saisie.

## Ton

Sobre et direct. Le préfixe « [Système] » est réservé aux notifications.

## Interdits

Aucune illustration, logo, police, nom ou citation de l'œuvre originale. Icônes issues d'une
bibliothèque libre de droits.
