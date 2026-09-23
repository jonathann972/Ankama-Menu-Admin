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

## Baselines importantes

| Baseline | SHA256 | Sauvegarde |
|---|---|---|
| Client/panneau statique fonctionnel | `CD54EDF238751CC2BC3313C85BB4D7A31B0AF7D38EADE33F49BA94D3546C0610` | `DofusInvoker.ANOMALIES_NATIVE_WORKING_BASE.swf` |
| Avant tentative de liaison tardive | `CD54EDF238751CC2BC3313C85BB4D7A31B0AF7D38EADE33F49BA94D3546C0610` | `DofusInvoker.before-ui-controller-binding-20260923-000317.bak.swf` |
| Avant test du bridge contrôleur | `CD54EDF238751CC2BC3313C85BB4D7A31B0AF7D38EADE33F49BA94D3546C0610` | `DofusInvoker.before-native-ui-bridge-test-20260923-001721.bak.swf` |
| Bridge contrôleur minimal validé en jeu | `76B0341BC05FB1EEB71C7EFB178E25AE7B751BAA8A067F06F5FAA7911515724A` | `DofusInvoker.baseline-native-ui-bridge-validated-20260923-002831.bak.swf` |
| Lecture inventaire Écho validée en jeu — baseline recommandée | `049F23E30E33A4AD42617A20D684F88DF645A86842F6537C3080A6D5DF6C4A29` | `DofusInvoker.baseline-echo-inventory-validated-20260923.bak.swf` |

## Diagnostic

Avant d'étudier les données métier, prouver toute la chaîne :

```text
source → compilation → déploiement → chargement → instanciation → exécution
```

Pour le contrôleur, une ligne `[ANOM-UI]` et une modification visuelle contrôlée confirment l'exécution. Pour l'inventaire, les diagnostics `[ANOM-INVENTORY]` doivent rapporter le filtre de type, la recherche directe par GID, l'UID, le type réel, la position et les effets.

## Restauration

1. Arrêter complètement Dofus.
2. Restaurer en priorité `DofusInvoker.baseline-echo-inventory-validated-20260923.bak.swf`, sauf si le diagnostic concerne une étape antérieure.
3. Comparer son SHA256 avec la valeur documentée.
4. Copier la baseline vers `DofusInvoker.swf`.
5. Ne modifier aucune autre couche avant d'avoir retesté démarrage, bouton et panneau.

## Règle de travail

**Une seule couche doit être modifiée/testée à la fois.**

Ordre obligatoire :

```text
démarrage → module → bouton → ouverture UI → contrôleur → inventaire → rendu → équipement
```

Avant toute modification importante, relire ce document. Une architecture marquée comme ayant échoué ne doit pas être réintroduite sans justification explicite et nouveau protocole de restauration.
