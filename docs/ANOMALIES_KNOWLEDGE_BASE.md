# Base de connaissance — Anomalies

> **Document de référence actif.** Les anciens cahiers des charges et paquets de diagnostic décrivent des étapes historiques ; en cas de contradiction, ce document et les artefacts générés les plus récents font foi.

## Démarrage rapide

Avant toute intervention :

1. analyser intégralement `project/tools/AnomalyCreator/generated` ou, dans l'espace de travail local, `AnomalyCreator/generated` ;
2. réutiliser exclusivement les GID, EffectIds, plages de jets et mappings qui y sont consignés — ne jamais recréer ni deviner un identifiant ;
3. préserver le double contexte d'`AnomaliesModuleBridge` et le cycle `GameStart` du bouton HUD ;
4. employer uniquement `.anomaly <UID>` et `.anomaly off` — jamais `/anomaly` ;
5. modifier une seule couche à la fois, valider le candidat décompilé, puis tester dans l'ordre : démarrage, bouton, panneau, catalogue, équipement, combat.

### Sources de vérité

| Sujet | Source prioritaire |
|---|---|
| GID, effets, jets et mappings d'une anomalie injectée | `AnomalyCreator/generated/anomaly-<GID>.txt` |
| Définition utilisée pour une nouvelle injection | JSON correspondant dans `AnomalyCreator` |
| Architecture, garde-fous et procédures | le présent document |
| État réel du client et du serveur | candidat décompilé, hashes et test en jeu |
| Besoin visuel historique | `CAHIER_DES_CHARGES_ANOMALIES_UI.txt`, à consulter comme référence et non comme état actuel |

### Invariants à ne pas casser

- Le verrou d'un slot non possédé reste **au-dessus** de l'icône ; l'icône ne doit pas masquer le verrou.
- Le bouton Anomalies est installé après `GameStart`, sans doublon, et doit être réinstallé si le HUD natif est reconstruit après un changement de contexte ou un donjon.
- Le nom et le niveau du slot équipé restent alimentés par `lbl_equipped_name` et `lbl_equipped_level`.
- Les raretés utilisent une palette commune et distincte : Commune, Rare, Épique, Légendaire, Corrompue et autre/inconnue.
- Aucun remplacement isolé d'une classe interne partageant le bloc ABC de `Modules` n'est déployé dans `DofusInvoker.swf`.

### Navigation

- [Architecture et cycle Berilia](#architecture-validée)
- [Ajouter une Anomalie custom](#ajout-dune-anomalie-custom--procédure-canonique)
- [Échecs connus](#architectures-ayant-échoué)
- [Données et inventaire](#données-anomalies-confirmées)
- [Synchronisation de l'équipement](#synchronisation-runtime-de-léquipement)
- [Baselines et restauration](#baselines-importantes)
- [Règle de travail](#règle-de-travail)
- [Garde-fous du contrôleur](#garde-fous-du-contrôleur-natif--obligatoires)
- [Rémanence](#rémanence--candidate-de-test-23-septembre-2026)
- [Tooltips et raretés](#tooltips-anomalies--icônes-et-jets-validés-en-jeu)
- [Toison](#toison--troisième-anomalie-candidate)

## Ajout d'une Anomalie custom — procédure canonique

Cette procédure couvre l'injection des données client et leur raccordement au serveur. `AnomalyCreator` ne crée jamais automatiquement la mécanique de combat : chaque anomalie exige une implémentation serveur spécifique et des tests dédiés.

### 1. Vérifier les identifiants avant toute écriture

1. Lire **tous** les fichiers déjà présents dans `AnomalyCreator/generated`.
2. Vérifier le JSON prévu et les fichiers générés voisins.
3. Lancer `audit` avant `apply`.
4. Ne jamais déduire un GID, un EffectId ou un MonsterId à partir du nom d'une anomalie ou d'un donjon.

Les EffectIds des anomalies custom doivent rester dans la plage réservée `3000..3999`, être distincts dans le JSON et ne pas réutiliser un mapping existant. Le fichier `generated/anomaly-<GID>.txt` produit par l'outil devient la source de vérité après injection.

Pour retrouver un boss officiel sans le deviner :

```powershell
.\AnomalyCreator.exe bosses "C:\chemin\Dofus" .\LISTE_BOSS_MONSTER_ID.txt
```

### 2. Préparer le JSON et l'icône

Champs obligatoires ou structurants :

| Champ | Règle |
|---|---|
| `gid` | Identifiant libre confirmé par `audit`. |
| `templateGid` | Objet Anomalie existant servant uniquement de modèle structurel. |
| `name`, `description` | Textes finaux affichés par le client. Garder la description assez courte pour le panneau. |
| `rarity` | Valeur de la palette commune : Commune, Rare, Épique, Légendaire, Corrompue ou autre explicitement assumée. |
| `level` | Niveau d'affichage, supérieur ou égal à 1. |
| `iconFile` | PNG réel de `64 × 64 px`, RGBA/transparence recommandée, placé à côté du JSON ou donné par chemin absolu. |
| `bossMonsterId` | Boss unique. Ne pas le renseigner en même temps qu'une liste différente. |
| `bossMonsterIds` | Liste de boss lorsque plusieurs monstres doivent porter le même drop ; cette liste est prioritaire sur `bossMonsterId`. |
| `dropPercent` | Taux entre `0` exclu et `100` inclus, appliqué aux cinq grades. |
| `effects` | Au moins un effet, avec `id`, `label`, `minimum`, `maximum`, `scale` et `suffix`. |

`scale` décrit uniquement la présentation de la valeur. Exemple : une valeur stockée `190` avec `scale: 10` s'affiche `19,0 %`. Les bornes du JSON restent les bornes de stockage utilisées pour le jet serveur.

L'icône doit rester nette à sa taille réelle : sujet central couvrant environ `85–90 %` du carré, silhouette simple, contraste fort, peu de micro-détails, aucun cadre ni texte intégré. Vérifier visuellement le PNG **après** réduction en 64 × 64, pas seulement sa source haute définition.

### 3. Auditer, appliquer et vérifier

Fermer complètement Dofus, ouvrir PowerShell dans le dossier qui contient `AnomalyCreator.exe`, puis exécuter :

```powershell
.\AnomalyCreator.exe audit .\<GID>_<Nom>.json "C:\chemin\Dofus"
.\AnomalyCreator.exe apply .\<GID>_<Nom>.json "C:\chemin\Dofus"
.\AnomalyCreator.exe verify .\<GID>_<Nom>.json "C:\chemin\Dofus"
```

`audit` doit annoncer le GID, l'icône et le drop comme libres, ainsi que les effets comme valides. `apply` refuse volontairement de réécrire un GID, une icône ou un drop déjà présent. Il crée d'abord une sauvegarde horodatée sous `Dofus/AnomalyCreatorBackups/<GID>/`, puis modifie uniquement :

- `Items.d2o` pour l'objet de type `290` ;
- `i18n_fr.d2i` pour le nom et la description/rareté ;
- `bitmap0_1.d2p` pour `<GID>.png` ;
- `Monsters.d2o` pour les drops déclarés.

En cas d'échec après application :

```powershell
.\AnomalyCreator.exe rollback .\<GID>_<Nom>.json "C:\chemin\Dofus"
```

Ne jamais relancer `apply` pour déplacer un drop déjà injecté. Corriger le ou les boss dans le JSON, fermer le client, puis utiliser :

```powershell
.\AnomalyCreator.exe repair-drop .\<GID>_<Nom>.json "C:\chemin\Dofus"
.\AnomalyCreator.exe verify .\<GID>_<Nom>.json "C:\chemin\Dofus"
```

### 4. Cas multi-boss et restriction à un donjon

Pour plusieurs boss légitimes dans le même combat, utiliser `bossMonsterIds`. Exemple conceptuel : les quatre Tynrils peuvent recevoir le même drop via une liste de quatre MonsterIds.

Une restriction « uniquement dans ce donjon » ne peut pas être garantie par le drop D2O seul. Le champ `dropMapIds` existe dans le modèle JSON mais n'est actuellement pas consommé par `AnomalyCreator` : il ne doit donc jamais être considéré comme une protection active. La condition de carte/donjon doit être appliquée dans `AnomalyDropManager` côté serveur, à partir d'identifiants de carte vérifiés. C'est notamment obligatoire lorsqu'un même MonsterId peut apparaître dans plusieurs donjons mais ne doit donner l'anomalie que dans l'un d'eux.

### 5. Raccordement serveur et UI

Après `apply`, ouvrir `generated/anomaly-<GID>.txt` et reporter exactement ses constantes et mappings dans les composants concernés :

1. déclaration/catalogue de l'anomalie dans `AnomalyRollManager` ou le registre serveur équivalent ;
2. création des jets d'instance selon les bornes `minimum..maximum` ;
3. mapping des effets dans le tooltip et le panneau Berilia ;
4. ajout de l'icône au module `Ankama_Anomalies` si le catalogue embarqué l'exige ;
5. implémentation séparée de la mécanique de combat ;
6. règle de drop serveur, y compris les éventuelles restrictions de carte ;
7. compilation, déploiement et validation en jeu.

Le client D2O décrit l'objet et son drop visible ; le serveur reste autoritaire pour le jet réel, l'instance, les effets, la mécanique et les conditions de donjon. Ne jamais simuler ces règles uniquement dans l'UI.

### 6. Validation finale obligatoire

- `verify` réussit après l'injection.
- `generated/anomaly-<GID>.txt` existe et correspond au JSON.
- Le client démarre au-delà de 48 % et le bouton Anomalies reste présent.
- L'objet possède le bon nom, la bonne rareté, le bon niveau et une icône nette.
- Le verrou des exemplaires non possédés reste au-dessus de l'icône.
- Les valeurs du tooltip et du panneau proviennent des effets réels de l'instance.
- Le drop ne se produit que sur les boss et, si nécessaire, les cartes explicitement autorisés.
- La mécanique est testée avec succès, échec, limites de jet, déséquipement et reconnexion.

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

## Garde-fous du contrôleur natif — obligatoires

Ces invariants ont été reconfirmés après les régressions du 24 septembre 2026. Toute modification de `AnomaliesModuleBridge`, `AnomaliesModuleRuntime`, `Modules` ou `Ankama_Anomalies.swf` doit les préserver ensemble.

### Double contexte de `AnomaliesModuleBridge`

`AnomaliesModuleBridge.main()` ne doit jamais être remplacé par un contrôleur UI pur. Il doit conserver ses deux branches :

1. si `lbl_collection` est injecté, exécuter le contrôleur Berilia du panneau ;
2. sinon, charger `Ankama_Anomalies/Ankama_Anomalies.swf` dans `ApplicationDomain.currentDomain`, injecter les API dans `Ankama_Anomalies.Ankama_Anomalies`, puis appeler son `main()`.

Supprimer la seconde branche empêche l'amorçage du module externe et peut faire disparaître l'interface ou son bouton après redémarrage.

### Installation du bouton HUD

Le chemin validé reste `AnomaliesModuleRuntime.main()` → hook `HookList.GameStart` → `onGameStart()` → `installNativeButton()`. `installNativeButton()` doit impérativement conserver le contrôle préalable de l'entrée `id == 32760`.

Ne pas remplacer isolément la classe interne `AnomaliesModuleRuntime` dans `DofusInvoker.swf`. Cette classe partage le même bloc ABC que `Modules` et d'autres traits internes : un remplacement individuel avec FFDec a produit, le 24 septembre 2026, un client qui restait lancé en arrière-plan mais dont la fenêtre de jeu ne s'ouvrait plus correctement. Le binaire a dû être restauré depuis `DofusInvoker.before-button-repair-20260924.bak.swf`.

Si le bouton manque, vérifier d'abord le double contexte de `AnomaliesModuleBridge`, le chargement de `Ankama_Anomalies.swf`, les journaux `[ANOMALIES-UI]` et la présence du registre `_scripts["Ankama_Anomalies"]`. Toute modification de `AnomaliesModuleRuntime` doit recompiler/remplacer l'unité ABC complète depuis une baseline validée, puis être testée séparément au démarrage.

Une modification est invalide si, après redémarrage complet, le bouton Anomalies n'est pas présent dans `bannerMenu.gd_btnUis`.

#### Persistance après combat et reconstruction du HUD — candidate à tester

Symptôme observé : le bouton peut disparaître après l'entrée dans un combat, un donjon ou plusieurs minutes de jeu lorsque `bannerMenu` est reconstruit. L'entrée ajoutée à l'ancien `gd_btnUis.dataProvider` n'est alors pas automatiquement transférée au nouveau composant.

La correction candidate du 24 septembre 2026 conserve le chemin `GameStart` et ajoute deux mécanismes idempotents :

1. écouter `BeriliaHookList.UiLoaded` et rappeler `installNativeButton()` environ `250 ms` après le chargement de `bannerMenu` ;
2. contrôler toutes les `5 s` que l'entrée `id == 32760` existe encore dans le `dataProvider` courant.

`installNativeButton()` doit toujours rechercher `id == 32760` avant l'ajout. Le contrôle périodique répare donc une disparition sans créer de doublon. S'il n'existe pas encore de `bannerMenu` ou de `gd_btnUis.dataProvider`, il retente après `500 ms`.

Source candidate : `Ankama_Anomalies/native-patch-source/com/ankamagames/dofus/Modules.as`. Un SWF candidat a été recompilé et décompilé pour vérifier la présence de `UiLoaded`, `watchNativeButton()` et du garde-fou `id == 32760`, mais **le comportement après combat n'est pas encore validé en jeu**. Il ne doit pas être promu comme nouvelle baseline avant les tests suivants :

- connexion et présence d'un seul bouton ;
- entrée puis sortie d'un combat ;
- entrée puis sortie d'un donjon ;
- attente supérieure à cinq minutes ;
- reconstruction ou rechargement de `bannerMenu` ;
- ouverture du panneau après chaque étape ;
- absence de doublon dans `gd_btnUis`.

### Syntaxe des commandes d'équipement

La syntaxe serveur validée est exclusivement :

```text
.anomaly <UID>
.anomaly off
```

Ne jamais remplacer le point initial par `/`. Une recherche automatique de la chaîne `/anomaly` doit retourner zéro occurrence dans les contrôleurs avant compilation et déploiement.

### Texte du slot équipé

Le contrôleur doit déclarer et alimenter les deux composants publics suivants :

```text
lbl_equipped_name
lbl_equipped_level
```

Dans `renderEquipped()`, leur visibilité doit suivre l'état équipé, leur texte doit être vidé quand le slot est vide, et les valeurs attendues sont `d.name` et `"Niv. " + d.level`. Une refonte générique du catalogue ne doit jamais supprimer ce rendu.

### Validation obligatoire du SWF recompilé

Après remplacement ActionScript avec FFDec, décompiler le **candidat final** et vérifier avant copie vers `DofusInvoker.swf` :

```text
Modules : _scripts["Ankama_Anomalies"] = AnomaliesModuleRuntime
AnomaliesModuleRuntime : hook GameStart et installNativeButton présents dans l'unité ABC complète
AnomaliesModuleBridge : branche lbl_collection + chargeur du SWF externe
AnomaliesModuleBridge : commandes .anomaly
AnomaliesModuleBridge : lbl_equipped_name / lbl_equipped_level
AnomaliesModuleBridge : dernière entrée attendue du catalogue
```

Créer une sauvegarde du binaire déployé avant chaque remplacement. Après déploiement, effectuer un redémarrage complet du client et valider dans cet ordre : bouton HUD, ouverture/fermeture du panneau, pagination du catalogue, texte du slot équipé, équipement, déséquipement et actualisation immédiate.

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

## Tooltips Anomalies — icônes et jets validés en jeu

Validation du 23 septembre 2026 : les tooltips standards d'Écho et de Rémanence affichent désormais correctement leur icône, leur rareté, leur description et leurs jets d'instance. Ce correctif est indépendant du panneau custom Anomalies et de l'Encyclopédie.

### Chaîne de l'icône

Le chemin fonctionnel confirmé est :

```text
ItemTooltipUi
→ ItemWrapper.typeId == 290
→ ItemWrapper.iconUri
→ getIconUri(true)
→ bitmap0.d2p / archives associées
→ <iconId>.png
```

Valeurs validées :

```text
Écho       GID=32760 typeId=290 iconId=32760 → 32760.png
Rémanence  GID=32761 typeId=290 iconId=32761 → 32761.png
```

Pour une Anomalie, utiliser `iconUri` dans `ItemTooltipUi`. Le chemin vanilla `fullSizeIconUri` ne convient pas à ces icônes custom. Le type `290`, les `iconId` et les objets D2O sont maintenant gelés : ne pas les modifier pour résoudre un problème de rendu du tooltip.

### Moteur générique des jets

`ItemTooltipUi` possède une définition centralisée par GID. Chaque définition associe une rareté et une liste d'effets à rendre. La fonction de rendu reste unique : elle parcourt `ItemWrapper.effects`, indexe les valeurs par `effectId`, applique le format déclaré, puis construit la section `Jets de l'Anomalie`.

Mappings validés :

| Anomalie | EffectId | Libellé | Conversion | Plage affichée |
|---|---:|---|---|---|
| Écho `32760` | `3100` | Chance de répétition | valeur / 10, une décimale | `17–20 %` |
| Écho `32760` | `3101` | Puissance de l'Écho | entier | `40–60 %` |
| Rémanence `32761` | `3103` | Chance de Rémanence | valeur / 10, une décimale | `15–25 %` |
| Rémanence `32761` | `3104` | PA conservés | entier | `1–2` |

Les valeurs affichées ne doivent jamais être inscrites en dur dans le SWF : elles proviennent exclusivement des effets de l'instance reçue par le tooltip. Seuls les métadonnées de présentation — identifiant, libellé, échelle, décimales, suffixe et plage — appartiennent au mapping client.

Le rendu validé utilise :

- `Rareté :` en doré, avec une couleur propre à la valeur : Commune `#B8B8B8`, Rare `#4DA6FF`, Épique `#C653FF`, Légendaire `#FFB52E`, Corrompue `#D94A67`, autre/inconnue `#E8C34A` ;
- la description en bleu ciel ;
- `Jets de l'Anomalie` en doré ;
- les valeurs réelles en vert ;
- les plages min/max en gris.

La section des jets est ajoutée après le contenu descriptif final. Elle ne doit pas dépendre d'une substitution fragile autour du texte brut de rareté. Les effets présents sont rendus depuis le mapping ; le moteur n'est pas dupliqué avec une succession de branches propres à chaque Anomalie. Pour ajouter une troisième Anomalie, ajouter uniquement une nouvelle définition GID/effets.

La coloration de rareté ne doit pas dépendre de la présence du GID dans le mapping des jets. Si aucune définition GID n'existe encore, `ItemTooltipUi` doit lire la valeur après `Rareté :` dans le texte et appliquer la palette commune. Cette règle garantit la bonne couleur des nouvelles anomalies dès leur injection par `AnomalyCreator`.

### Instances et diagnostic

Plusieurs instances d'un même GID peuvent coexister avec des UID et des jets différents. État observé pendant le diagnostic Écho :

```text
UID 65 : aucun effet
UID 81 : 3100=182, 3101=42
UID 83 : 3100=194, 3101=41
UID 84 : 3100=190, 3101=49
```

Le panneau custom sélectionne la meilleure instance disponible ; son affichage ne prouve donc pas à lui seul quel UID est survolé dans l'inventaire. En cas de nouvelle régression, tracer l'UID et `ItemWrapper.effects` reçus par `ItemTooltipUi` avant de modifier les données serveur ou les D2O.

### Artefacts du correctif tooltip

| Artefact | SHA256 |
|---|---|
| `DofusInvoker.swf` — tooltip générique Écho + Rémanence validé en jeu | `ACE6AFD3B5CAD4A760872D235B039D58EB9F82633E24642A46CB53270ED3E612` |
| Sauvegarde avant correctif `DofusInvoker.before-tooltip-jets-generic-20260923.bak.swf` | `F8A7188630C6913A49C361A331C13B197579EC7BD3329C612001E929329B244F` |

### Garde-fous

Pour toute correction future limitée au tooltip Anomalie, ne pas toucher à :

```text
Items.d2o
ItemTypes.d2o
typeId / iconId
index D2O
Encyclopédie et ses filtres
panneau custom Anomalies
AnomalyRollManager
items vanilla
```

Séparer strictement les responsabilités : les D2O définissent l'objet et son icône, le serveur fournit les effets d'instance, et `ItemTooltipUi` effectue uniquement leur présentation.

## Toison — troisième Anomalie candidate

Intégration technique du 23 septembre 2026, en attente de validation gameplay complète en jeu.

| Propriété | Valeur |
|---|---|
| GID / iconId | `32762` — disponibilité auditée avant création |
| Type / niveau | `290` / `6` |
| Rareté | Commune |
| Catégorie | Mêlée |
| Boss officiel | Bouftou Royal, MonsterId `147` |
| Donjon | Cour du Bouftou Royal |
| Chance | effet `3105`, `150..250`, soit `15,0..25,0 %` |
| Restauration | effet `3106`, `10..20 %` des PV réellement perdus |

Le gameplay écoute `DamageReceived` sur le `CharacterFighter`. La condition de mêlée réutilise `damage.Source.IsMeleeWith(target)` et le calcul utilise `DamageResult.LifeLoss`, donc la perte effective après résistances et boucliers. La première attaque de mêlée avec perte de vie consomme immédiatement la tentative, avant le jet : un échec interdit toute nouvelle tentative jusqu'au prochain tour du personnage. Le soin fixe est plafonné aux PV récupérables et n'est pas appliqué si le coup est fatal.

Le drop est ajouté uniquement au Bouftou Royal avec un taux final de `1 %`. `FightFormulas.AdjustDropChance()` reconnaît les GID déclarés par `AnomalyRollManager` et retourne leur taux configuré sans multiplicateur de Prospection, bonus de challenge ou taux global. La formule vanilla reste inchangée pour tous les autres objets.

Le tooltip et le panneau utilisent les effets réels de l'instance :

```text
3105 → Chance de déclenchement
3106 → PV perdus restaurés
```

L'intégration client ciblée ajoute uniquement l'objet `32762`, deux textes D2I et `32762.png` dans `bitmap0_1.d2p`. Pour refléter le butin dans le Bestiaire, seule l'entrée `MonsterId=147` de `Monsters.d2o` est redirigée vers une nouvelle version sérialisée contenant le drop `32762` à `1 %` (`dropId=14113`). `ItemTypes.d2o` et les index de recherche de l'Encyclopédie ne sont pas modifiés.
