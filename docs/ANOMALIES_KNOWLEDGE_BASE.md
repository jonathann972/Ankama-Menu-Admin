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
| Palier du slot II | `x=398, y=280` | `110 × 18 px` | Texte statique `Niv. 100`, même style et même alignement vertical. |
| Palier du slot III | `x=548, y=280` | `110 × 18 px` | Texte statique `Niv. 200`, même style et même alignement vertical. |

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

## Rémanence — candidate de test (23 septembre 2026)

Rémanence est la seconde définition du catalogue multi-anomalies. Cette version part exclusivement de la baseline Écho complète validée ; elle ne devient une nouvelle baseline qu'après validation en jeu.

| Propriété | Valeur |
|---|---|
| GID | `32761` |
| Type d'objet | `290` |
| Marqueur actif partagé | `3102` |
| Chance de rémanence | effet `3103`, valeur en dixièmes, `150..250` soit `15,0..25,0 %` |
| PA conservés | effet `3104`, entier `1..2` |
| Icône module | `Remanence_64x64.png`, `64 × 64 px`, non modifiée |
| Catégorie | `Utilitaire` |
| Niveau | `1` |

Le marqueur `3102` reste générique : il représente uniquement l'objet anomalie dont l'UID correspond à `CharacterRecord.ActiveAnomalyItemUid`. Il ne contient aucune donnée propre à Écho ou Rémanence.

Le catalogue du contrôleur Berilia associe désormais `GID → nom → niveau → rareté → catégorie → description → icône → deux effets → minima/maxima`. Le panneau de droite, les deux premiers slots de collection et le slot équipé sont rendus depuis la définition sélectionnée, sans branche spécifique au nom de l'anomalie.

Dans la collection, l'icône d'une anomalie cataloguée reste affichée même lorsqu'elle n'est pas encore possédée. Le cadre `slot_locked` transparent est alors affiché par-dessus l'icône ; il est remplacé par `slot_unlocked` dès que l'objet réel est détecté dans l'inventaire. Le verrouillage fonctionnel reste déterminé exclusivement par l'inventaire.

Règles gameplay de Rémanence :

- à la fin du tour, ne tenter le jet que si l'objet `32761` est réellement actif et s'il reste des PA éligibles ;
- réserver `min(PA restants éligibles, jet 3104, 2)` en cas de succès ;
- appliquer puis vider la réserve au début du tour suivant ;
- soustraire du calcul de fin de tour les PA accordés par Rémanence durant ce tour afin d'interdire leur recyclage ;
- annuler une réserve en attente si Rémanence a été déséquipée avant son application ;
- la répétition de sort d'Écho vérifie explicitement le GID `32760`, afin qu'elle ne s'exécute jamais pour Rémanence.

Les données client sont intégrées de façon reproductible par `project/tools/RemanenceIntegrator` : clonage structurel de l'objet Écho vers le GID `32761`, nouveaux textes D2I et ajout de l'icône `32761.png` dans `bitmap0_1.d2p`. L'objet est ensuite importé individuellement dans la table serveur avec `Giny.DatabaseSynchronizer --item 32761 --client <Dofus>`.

Diagnostics gameplay attendus :

```text
[ANOM-REMANENCE] roll uid=<UID> <tirage> / <chance> -> PROC; pa_restants=<N>; capacité=<1|2>
[ANOM-REMANENCE] réserve créée uid=<UID> pa=<1|2>
[ANOM-REMANENCE] réserve appliquée uid=<UID> pa=<1|2>
```

En cas d'échec :

```text
[ANOM-REMANENCE] roll uid=<UID> <tirage> / <chance> -> FAIL; pa_restants=<N>; capacité=<1|2>
```

Baseline utilisée pour cette candidate : client `3A8602C8963EFC645456BECFDD557E32E0B5324CAD11714CD7504ECF1705AEC1` et serveur `842FA006486B004FF0480090E784A36A0BACE70A6D0E95C4AD9F21E0B0BC9FA4`.

### Piège PA identifié pendant le test Rémanence

`Fighter.GainAp()`/`FighterStats.GainAp()` est un mécanisme de remboursement : il augmente `Context`, mais diminue également `Used`. Pour une réserve appliquée au début du tour, ce comportement produit côté client un état équivalent à `total=base+2, used=2`, donc le compteur disponible reste visuellement à sa valeur normale. Les logs serveur peuvent malgré cela indiquer que la réserve a été appliquée.

Rémanence doit augmenter directement `Stats.ActionPoints.Context`, conserver `Used=0` en début de tour, puis envoyer `GameActionFightPointsVariationMessage`. Le diagnostic d'application doit inclure `total_avant`, `total_après` et `used`; pour un bonus de 2 attendu : `9 → 11`, `used=0`.

Le même bonus `Context` doit impérativement être soustrait dans `StoreRemanenceReserve()` avant le `ResetUsedPoints()` normal de fin de tour. Sans ce retrait, le bonus devient permanent et se cumule avec les tours suivants. Le calcul des PA encore éligibles est effectué avant ce retrait sous la forme `TotalInContext - grantedThisTurn`, ce qui empêche aussi le recyclage des PA accordés.

L'ordre réseau est également déterminant : la réserve doit être appliquée dans `Fight.OnTurnStarted()` **avant** l'envoi de `GameFightTurnStartMessage`. Dofus initialise son compteur local de PA pendant le traitement de ce message. Une application ultérieure dans `CharacterFighter.OnTurnBegin()` peut être calculée correctement côté serveur (`9 → 11`, `used=0`) tout en restant affichée à 9 côté client.

L'affichage de Rémanence dans la barre des passifs n'est pas inclus dans la baseline validée. Les essais avec un simple `GameActionFightDispellableEffectMessage`, puis avec un buff d'affichage synthétique, n'ont produit aucun passif visible dans Dofus 2.68. Cette piste expérimentale a été retirée afin de ne pas modifier l'architecture générique des buffs pour une fonctionnalité non validée. Un futur affichage custom devra être conçu et testé comme une couche indépendante ; il ne devra pas modifier le calcul de PA validé.

## Baseline Écho + Rémanence validée en jeu

Validation du 23 septembre 2026 : détection et sélection des deux anomalies, collection multi-anomalies, équipement générique, remplacement de l'anomalie active, Rémanence en combat, bonus visible `9 → 11`, retrait au tour suivant `11 → 9`, absence de recyclage et comportement d'Écho préservé.

| Binaire | SHA256 | Sauvegarde officielle |
|---|---|---|
| Client `DofusInvoker.swf` | `F8A7188630C6913A49C361A331C13B197579EC7BD3329C612001E929329B244F` | `DofusInvoker.baseline-echo-remanence-validated-20260923.bak.swf` |
| Serveur `Giny.World.dll` | `3C14B08854B14416AA0049086616F88B61C9638CDBC7D18B12298DCDB8866250` | `Giny.World.baseline-echo-remanence-validated-20260923.bak.dll` |

Cette baseline devient le point de restauration officiel. Le passif visuel Rémanence reste explicitement hors périmètre et sera étudié comme UI custom séparée.
