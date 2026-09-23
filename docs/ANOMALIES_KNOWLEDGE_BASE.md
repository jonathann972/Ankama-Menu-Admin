# Base de connaissance — Anomalies

## Architecture validée

La chaîne validée en jeu est :

```text
Berilia → AnomaliesModuleBridge → API/composants injectés → logique dynamique
```

`com.ankamagames.dofus::AnomaliesModuleBridge` est le contrôleur Berilia officiel de `anomaliesUi`. Le fichier `.dm` doit conserver cette classe.

Le bridge possède deux contextes d'instanciation :

- contexte module : les API sont injectées, mais pas les composants du XML ; il charge le SWF externe et installe le bouton ;
- contexte UI : les API et les composants publics nommés du XML sont injectés ; son `main()` exécute la logique du panneau.

## Cycle Berilia 2.68 observé

```text
UiModuleManager.onModuleScriptLoaded
→ UiModule.bindUiClasses
→ getDefinitionByName(ui.uiClassName)
→ création du script de module
→ loadUi
→ UiRenderer.script = UiData.uiClass
→ instanciation du contrôleur
→ injection des API
→ injection des composants XML
→ UiRootContainer appelle main()
```

La classe déclarée dans le `.dm` doit être disponible lors de `bindUiClasses()`. `Ankama_Anomalies.ui::AnomaliesUi` provient d'un SWF externe chargé plus tard : elle ne doit donc pas être déclarée directement dans le `.dm`.

## Architectures ayant échoué

### Classe externe directement dans le `.dm`

Déclarer `Ankama_Anomalies.ui::AnomaliesUi` comme classe de `anomaliesUi` provoque un blocage du client vers 48 %, car la classe n'existe pas encore dans l'`ApplicationDomain` lors de `bindUiClasses()`.

### Remplacement tardif de `UiData.uiClass`

Remplacer `UiData.uiClass` après le chargement du SWF externe empêche le panneau de s'ouvrir. Cette mutation contourne le cycle de liaison Berilia et ne doit pas être réintroduite.

## Test de contrôleur validé en jeu

Le test suivant a été validé le 23 septembre 2026 :

- le client dépasse 48 % ;
- le bouton Anomalies est présent ;
- le panneau s'ouvre avec son design intact ;
- `Collection TEST` apparaît ;
- `[ANOM-UI] Contrôleur Berilia exécuté` apparaît dans le chat ;
- fermeture et réouverture fonctionnent.

Ce test prouve que le contexte UI de `AnomaliesModuleBridge` reçoit les API et les composants XML avant l'appel à `main()`.

## Données Anomalies confirmées

- GID Écho : `32760`
- Effet chance de répétition : `3100` (valeur en dixièmes de pourcent)
- Effet puissance de l'écho : `3101`
- Marqueur actif : `3102`
- Type d'objet Anomalie : `290`, confirmé en runtime le 23 septembre 2026.

## Lecture d'inventaire Écho validée en jeu

La lecture seule d'Écho depuis `AnomaliesModuleBridge` a été validée en jeu le 23 septembre 2026 :

- panneau fonctionnel ;
- `[ANOM-UI] Contrôleur Berilia exécuté` visible ;
- `Collection 1/1` ;
- GID Écho `32760` détecté ;
- premier slot déverrouillé avec l'icône Écho ;
- chance de répétition : `19,0 % / 20 %` ;
- puissance de l'Écho : `49 % / 60 %` ;
- type `290` confirmé par le client en runtime ;
- diagnostic `anomalies possédées=1`.

Cette version est le point de retour stable obligatoire avant le développement d'ÉQUIPER/DÉSÉQUIPER.

## Slot équipé I — géométrie et typographie

Les coordonnées ci-dessous sont celles du panneau `1086 × 672` dans `anomaliesSmoke.xml` :

| Élément | Position | Taille | Règle |
|---|---:|---:|---|
| Cadre du slot I | `x=243, y=145` | `125 × 175 px` | Ne pas déplacer sans revalider tous ses enfants. |
| Icône de l'anomalie | `x=274, y=199` | `64 × 64 px` | Centrée sur les limites opaques réelles de la zone centrale. |
| `lbl_equipped_name` | `x=259, y=166` | `89 × 20 px` | Roboto 14 px, gras, centré, contour sombre. |
| `lbl_equipped_level` | `x=248, y=280` | `110 × 18 px` | Roboto 12 px, gras, centré, contour sombre. |

Le nom d'une anomalie équipée est limité à `10` caractères, espaces compris. Sa largeur réelle doit être contrôlée à l'exécution avec le `textWidth` du composant après application de la police. La zone autorisée mesure `89 px`. En cas de dépassement de la longueur ou de la largeur, émettre un diagnostic `[ANOM-EQUIP] nom hors limites` : ne jamais réduire la police et ne jamais tronquer silencieusement le texte.

Pour Écho, l'affichage attendu est :

- nom : `Écho` ;
- niveau : `Niv. 1` ;
- nom et niveau invisibles lorsque le slot est vide.

## Synchronisation runtime de l'équipement

Le test en jeu du 23 septembre 2026 a confirmé que `InventoryHookList.ObjectModified` n'était pas reçu après `.anomaly <UID>` ou `.anomaly off`, alors que l'état devenait correct à la réouverture du panneau.

Le chemin Dofus 2.68 observé est :

```text
serveur Inventory.OnItemModified
→ ObjectModifiedMessage
→ InventoryManagementFrame
→ Inventory.modifyObjectItem
→ RealView.modifyItem
→ ObjectModified ajouté à Inventory.HookLock
```

`ObjectModifiedMessage` actualise donc bien l'inventaire client, mais le hook n'est pas publié immédiatement. `InventoryManagementFrame` appelle `inventory.releaseHooks()` lors du traitement d'un `InventoryWeightMessage` ou d'un `KamasUpdateMessage`. L'ancienne implémentation d'`AnomalyRollManager.SynchronizeActiveMarker()` envoyait uniquement `ObjectModifiedMessage` : le hook restait en attente.

La correction serveur ciblée consiste à appeler `character.Inventory.RefreshWeight()` une seule fois après le lot de `OnItemModified`. Cela envoie `InventoryWeightMessage`, libère le `HookLock` côté client, puis rend `InventoryHookList.ObjectModified` observable par le contrôleur Berilia. Il ne faut pas contourner ce protocole par un état local simulé ou par polling.

Cette correction est validée complètement en jeu : équipement et déséquipement d'Écho actualisent immédiatement le slot I et le bouton, sans fermeture ni réouverture du panneau. La reconstruction à l'ouverture et la persistance après reconnexion restent fonctionnelles.

## Baselines importantes

| Baseline | SHA256 | Sauvegarde |
|---|---|---|
| Client/panneau statique fonctionnel | `CD54EDF238751CC2BC3313C85BB4D7A31B0AF7D38EADE33F49BA94D3546C0610` | `DofusInvoker.ANOMALIES_NATIVE_WORKING_BASE.swf` |
| Avant tentative de liaison tardive | `CD54EDF238751CC2BC3313C85BB4D7A31B0AF7D38EADE33F49BA94D3546C0610` | `DofusInvoker.before-ui-controller-binding-20260923-000317.bak.swf` |
| Avant test du bridge contrôleur | `CD54EDF238751CC2BC3313C85BB4D7A31B0AF7D38EADE33F49BA94D3546C0610` | `DofusInvoker.before-native-ui-bridge-test-20260923-001721.bak.swf` |
| Bridge contrôleur minimal validé en jeu | `76B0341BC05FB1EEB71C7EFB178E25AE7B751BAA8A067F06F5FAA7911515724A` | `DofusInvoker.baseline-native-ui-bridge-validated-20260923-002831.bak.swf` |
| Lecture inventaire Écho validée en jeu — ancienne baseline lecture seule | `049F23E30E33A4AD42617A20D684F88DF645A86842F6537C3080A6D5DF6C4A29` | `DofusInvoker.baseline-echo-inventory-validated-20260923.bak.swf` |
| Écho complet validé — client officiel | `3A8602C8963EFC645456BECFDD557E32E0B5324CAD11714CD7504ECF1705AEC1` | `DofusInvoker.baseline-echo-complete-validated-20260923.bak.swf` |
| Écho complet validé — serveur officiel | `842FA006486B004FF0480090E784A36A0BACE70A6D0E95C4AD9F21E0B0BC9FA4` | `Giny.World.baseline-echo-complete-validated-20260923.bak.dll` |

## Diagnostic

Avant d'étudier les données métier, prouver toute la chaîne :

```text
source → compilation → déploiement → chargement → instanciation → exécution
```

Pour le contrôleur, une ligne `[ANOM-UI]` et une modification visuelle contrôlée confirment l'exécution. Pour l'inventaire, les diagnostics `[ANOM-INVENTORY]` doivent rapporter le filtre de type, la recherche directe par GID, l'UID, le type réel, la position et les effets.

## Restauration

1. Arrêter complètement Dofus et le serveur World.
2. Restaurer en priorité `DofusInvoker.baseline-echo-complete-validated-20260923.bak.swf` et `Giny.World.baseline-echo-complete-validated-20260923.bak.dll`, sauf si le diagnostic concerne une étape antérieure.
3. Comparer les deux SHA256 avec les valeurs documentées.
4. Copier les baselines vers `DofusInvoker.swf` et `serveur-local/world/Giny.World.dll`.
5. Redémarrer le serveur, puis retester démarrage, bouton, panneau, lecture inventaire et équipement temps réel avant toute autre modification.

## Règle de travail

**Une seule couche doit être modifiée/testée à la fois.**

Ordre obligatoire :

```text
démarrage → module → bouton → ouverture UI → contrôleur → inventaire → rendu → équipement
```

Avant toute modification importante, relire ce document. Une architecture marquée comme ayant échoué ne doit pas être réintroduite sans justification explicite et nouveau protocole de restauration.
