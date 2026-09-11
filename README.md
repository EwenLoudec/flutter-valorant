# Valorant Companion

Application mobile **Flutter** dédiée à Valorant : une encyclopédie complète du jeu
(agents, armes, cartes, rangs) doublée d'une page profil qui affiche vos statistiques
de joueur à partir de votre Riot ID.

Toutes les données de jeu (visuels, statistiques, traductions françaises) viennent de
[valorant-api.com](https://valorant-api.com) ; les données de compte viennent de
[api.henrikdev.xyz](https://docs.henrikdev.xyz).

> Le dossier du projet s'appelle encore `mybmw` (nom du template de départ), mais
> l'application elle-même s'appelle *Valorant Companion*.

---

## Aperçu

<table>
  <tr>
    <td align="center"><img src="docs/screenshots/agents.png" width="210"><br><sub><b>Agents</b> — filtre par rôle</sub></td>
    <td align="center"><img src="docs/screenshots/agent-detail.png" width="210"><br><sub><b>Fiche agent</b> — compétences</sub></td>
    <td align="center"><img src="docs/screenshots/weapons.png" width="210"><br><sub><b>Armes</b> — par catégorie</sub></td>
    <td align="center"><img src="docs/screenshots/weapon-detail.png" width="210"><br><sub><b>Fiche arme</b> — dégâts & skins</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/maps.png" width="210"><br><sub><b>Cartes</b> — pool compétitif</sub></td>
    <td align="center"><img src="docs/screenshots/map-detail.png" width="210"><br><sub><b>Minimap tactique</b> — callouts</sub></td>
    <td align="center"><img src="docs/screenshots/ranks.png" width="210"><br><sub><b>Rangs</b> — saison en cours</sub></td>
    <td align="center"><img src="docs/screenshots/profile.png" width="210"><br><sub><b>Profil</b> — connexion Riot ID</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="docs/screenshots/skins-picker.png" width="210"><br><sub><b>Collection</b> — cocher ses skins</sub></td>
    <td align="center"><img src="docs/screenshots/profile-skins.png" width="210"><br><sub><b>Mes skins</b> — par rareté</sub></td>
    <td colspan="2"></td>
  </tr>
</table>

---

## Fonctionnalités

L'app est organisée en 5 onglets.

### 🧑‍🚀 Agents
- Liste complète des agents jouables, filtrable par rôle (duelliste, initiateur, contrôleur, sentinelle).
- Fiche détaillée : portrait, description, dégradé de couleurs officiel, et les 4 compétences dépliables.
- Aperçu vidéo de chaque compétence (clips officiels de playvalorant.com, pré-collectés dans
  `assets/data/ability_videos.json` via `scripts/scrape_ability_videos.ps1`).

### 🔫 Armes
- Catalogue trié par prix, filtrable par catégorie.
- Fiche arme : prix, cadence de tir, chargeur, et **tableau des dégâts tête / corps / jambes par distance**.
- Carrousel des skins de l'arme, colorés selon leur rareté (Select → Ultra), avec les vidéos d'animation.

### 🗺️ Cartes
- Toutes les cartes classées, avec un badge « compétitif actif » sur celles du pool en cours.
- **Minimap tactique** générée à partir des coordonnées Riot : sites A/B/C et callouts positionnés sur le plan.
- Liste des callouts regroupés par zone + composition méta conseillée avec son win rate
  (données communautaires maintenues à la main dans `map_meta_data.dart`, à rafraîchir selon la meta).

### 🏅 Rangs
- Tous les paliers du plus haut au plus bas, aux couleurs officielles, avec l'épisode / acte en cours.

### 👤 Profil
Saisissez votre Riot ID (`Pseudo#TAG`) et votre région pour afficher :
- **Rang compétitif** : palier, RR avec barre de progression, dernier gain/perte de points, elo, pic de carrière.
- **Historique** : les 10 dernières parties (agent, carte, mode, score en rounds, K/D/A, % de têtes, victoire/défaite).
- **Précision arme par arme** : répartition tête / corps / jambes, globale puis pour chaque arme.
- **Mes skins** : votre collection, cochée depuis le catalogue et conservée sur l'appareil.

Le Riot ID, la région et la clé API sont mémorisés localement — un tirer-pour-rafraîchir met tout à jour.

---

## Démarrage

Prérequis : [Flutter](https://docs.flutter.dev/get-started/install) sur le canal stable (Dart 3.13 ou plus).

```bash
flutter pub get
```

```bash
flutter run
```

L'encyclopédie fonctionne immédiatement, sans aucune clé : valorant-api.com est une API
publique et sans authentification.

### Clé API pour la page Profil

Les statistiques de joueur passent par l'API communautaire **HenrikDev**, qui demande une
clé gratuite (à demander sur leur [Discord](https://docs.henrikdev.xyz)). Deux façons de la fournir :

1. **Dans l'app** : onglet PROFIL → champ « Clé API HenrikDev ». Elle est stockée sur
   l'appareil (`shared_preferences`) et n'est jamais envoyée ailleurs qu'à HenrikDev.
2. **À la compilation**, pour ne pas la ressaisir :

```bash
flutter run --dart-define=HENRIK_API_KEY=HDEV-xxxxxxxx
```

---

## Architecture

Le projet suit un découpage par fonctionnalité, chacune en trois couches
(`domain` → modèles, `data` → accès réseau/stockage, `presentation` → écrans),
reliées par des providers [Riverpod](https://riverpod.dev).

```text
lib/
├─ app.dart                     # MaterialApp + thème
├─ core/
│  ├─ network/                  # clients HTTP : valorant-api.com et HenrikDev
│  ├─ theme/                    # palette et thème Valorant
│  └─ widgets/                  # briques réutilisables (coins coupés, images, nav…)
└─ features/
   ├─ encyclopedia/             # agents, armes, cartes, rangs
   │  ├─ domain/ data/ presentation/ providers/
   └─ profile/                  # Riot ID, rang, historique, précision, skins
      ├─ domain/ data/ presentation/ providers/
```

Quelques principes suivis dans le code :

- Chaque source de données passe par un **repository** abstrait, ce qui rend les écrans
  testables et interchangeables (`EncyclopediaRepository`, `PlayerRepository`).
- Le parsing réseau est **défensif** : l'API HenrikDev a changé de noms de champs entre v2
  et v4, chaque lecture accepte les deux écritures.
- Chaque section de la page profil gère ses propres états chargement / erreur / vide :
  une requête qui échoue n'efface pas le reste de la page.

### Qualité

```bash
flutter analyze
```

```bash
flutter test
```

---

## Limites connues

- **Les skins possédés ne sont pas récupérables automatiquement.** Riot n'expose aucune API
  publique d'inventaire ; y accéder demanderait de se connecter avec les identifiants Riot,
  ce que l'app ne fait pas. La collection est donc cochée à la main, puis conservée localement.
- **La précision par arme est une reconstruction.** Riot ne publie pas de statistique par arme :
  elle est recalculée round par round (arme tenue × impacts placés) sur les parties chargées.
  Les chiffres sont donc très proches de la réalité, sans en être la copie exacte.
- La page profil couvre les comptes **PC** ; la console utilise une autre plateforme côté API.
- Le classement Radiant (onglet Rangs) est encore un écran d'attente — il pourra utiliser
  l'endpoint leaderboard de HenrikDev maintenant qu'une clé est gérée par l'app.
- La composition méta par carte est saisie à la main et vieillit avec les patchs.

---

## Crédits

- [valorant-api.com](https://valorant-api.com) — données et visuels du jeu.
- [HenrikDev API](https://docs.henrikdev.xyz) — données de compte, rang et historique.
- Clips de compétences : pages officielles des agents sur playvalorant.com.

Projet personnel non affilié à Riot Games. Valorant et tous les éléments associés sont des
marques ou marques déposées de Riot Games, Inc.
