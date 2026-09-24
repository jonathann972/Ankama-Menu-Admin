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

## Zones et glyphes natifs en combat — audit du 23 septembre 2026

Giny.NET et le client Dofus 2.68 possèdent déjà une chaîne native complète pour représenter une zone au sol. Aucun moteur graphique d'Anomalies ne doit être créé avant d'avoir testé cette chaîne :

```text
runtime Anomaly serveur
→ Mark / Glyph
→ Fight.AddMark()
→ GameActionFightMarkCellsMessage
→ FightSequenceFrame.cellsHasBeenMarked()
→ FightMarkCellsStep
→ MarkedCellsManager.addMark()
→ TrapZoneRenderer / STRATA_GLYPH
```

Suppression native :

```text
Fight.RemoveMark()
→ GameActionFightUnmarkCellsMessage
→ FightUnmarkCellsStep
→ MarkedCellsManager.removeGlyph() + removeMark()
```

Références serveur vérifiées :

- `Managers/Fights/Marks/Mark.cs` : source, cellule centrale, cellules calculées, couleur, sort, visibilité et mise à jour ;
- `Managers/Fights/Marks/Glyph.cs` : glyphe visible, durée et expiration au début des tours de son propriétaire ;
- `Managers/Fights/Marks/MarkShape.cs` : conversion de la couleur serveur en `GameActionMarkedCell.cellColor` ;
- `Managers/Fights/Effects/Marks/SpawnGlyph.cs` : handlers natifs des effets `401`, `402` et `1165` ;
- `Managers/Fights/Fight.cs` : `AddMark`, `UpdateMark`, `RemoveMark`, `TriggerMarks` et identifiants uniques via `PopNextMarkId()` ;
- `Managers/Fights/Zones/` : formes `Single`, `Lozenge`, `Cross`, `Square`, lignes et ensembles de zones.

Références protocole 2.68 vérifiées :

- `GameActionFightMarkCellsMessage` transporte un `GameActionMark` ;
- `GameActionFightUnmarkCellsMessage` supprime par `markId` ;
- `GameActionMark` transporte auteur, équipe, sort, niveau, type, impact, cellules et état actif ;
- `GameActionMarkedCell` transporte `cellId`, `zoneSize`, `cellColor` et `cellsType` ;
- types de marque : glyphe `1`, piège `2`, mur `3`, portail `4`, rune `5` ;
- formes protocole : cercle `0`, croix `1`, carré `2`.

Références client 2.68 vérifiées dans la décompilation :

- `FightSequenceFrame.as` reçoit `GameActionFightMarkCellsMessage` et `GameActionFightUnmarkCellsMessage` ;
- `FightMarkCellsStep.as` résout le sort et transmet la marque à `MarkedCellsManager` ;
- `MarkedCellsManager.as` crée une sélection colorée avec `TrapZoneRenderer` sur `STRATA_GLYPH` ;
- `FightUnmarkCellsStep.as` détruit la sélection et le GFX éventuel ;
- `AddGlyphGfxStep.as` instancie le GFX central lorsque le sort possède un paramètre `glyphGfxId`.

Deux couches visuelles doivent rester distinguées :

1. l'overlay coloré au sol provient de `cellColor`, est pilotable dynamiquement par le serveur et ne nécessite aucun nouvel asset ;
2. le GFX animé central dépend du `markSpellId` et du paramètre client `glyphGfxId`. Un sort/glyphe existant peut être réutilisé. Un visuel inédit nécessiterait des assets client, mais pas un nouveau moteur de marques.

Architecture obligatoire pour une Anomalie à zone : le runtime Anomaly conserve l'état métier (propriétaire, cellules, niveau, durée et règles de proc), tandis que `Glyph` reste la représentation native. Le serveur décide toujours de l'appartenance à la zone et applique les effets. Le client ne fait qu'afficher les messages reçus.

Pour un changement de niveau : utiliser `Fight.UpdateMark()` si seules les cellules ou la couleur changent ; supprimer puis recréer la marque si le niveau doit changer de `markSpellId`/`glyphGfxId`. Plusieurs zones simultanées sont supportées tant que chaque zone utilise un `markId` unique.

Prototype minimal recommandé avant Sylvestre complet : commande `.anomalyzone`, zone `Single` sur la cellule du joueur, `MarkTriggerType.None`, overlay vert, durée trois tours et aucun effet gameplay. Le prototype n'est pas encore implémenté ni validé en jeu : tout résultat le concernant reste à marquer **NON VÉRIFIÉ EN JEU** jusqu'au test réel.

## Entités temporaires / Invocations — audit du 23 septembre 2026

Cette section constitue la référence technique permanente pour les entités temporaires utilisées par les Anomalies. Elle documente les capacités observées dans le code de Giny.NET 2.68 et dans la décompilation du client Dofus 2.68. Une capacité observée dans le code ne doit pas être présentée comme validée en jeu tant que son cycle complet n'a pas été testé dans le runtime Anomaly.

### 1. Chaîne native d'une invocation

La chaîne native vérifiée est :

```text
Spell / Effect_Summon
→ Summon.Apply()
→ MonsterRecord + MonsterGrade
→ SpellEffectHandler.CreateSummon()
→ new SummonedMonster(...)
→ Fight.AddSummon() / Fight.AddSummons()
→ FightTeam.AddFighter()
→ AIFighter.Initialize() et Fight.PopNextContextualId()
→ FightTimeline.InsertFighter()
→ GameActionFightSummonMessage
→ FightSequenceFrame.fighterSummonEntity()
→ GameFightShowFighterMessage
→ FightSummonStep
→ entité visible côté client
→ SummonedMonster.OnSummoned()
```

Références serveur vérifiées dans `project/Giny.NETCore-2.68/Sources/Servers/Giny.World/Managers/Fights/` :

- `Effects/Summons/Summon.cs`, classe `Summon`, méthode `Apply()` : résout `MonsterRecord` avec `Effect.Min`, la cellule d'invocation, le grade avec `Effect.Max`, puis appelle `Fight.AddSummon()` ;
- `Cast/SpellEffectHandler.cs`, méthode `CreateSummon()` : construit un `SummonedMonster` à partir de la source, du record, du grade et de la cellule ;
- `Fighters/SummonedMonster.cs` : associe le `MonsterRecord`, le `MonsterGrade`, les statistiques, le look et les sorts à l'invocation ;
- `Fight.cs`, méthodes `AddSummon()` et `AddSummons()` : ajout à l'équipe, insertion dans la timeline, envoi de `GameActionFightSummonMessage`, mise à jour de la timeline, puis appel de `OnSummoned()` ;
- `FightTeam.cs`, méthode `AddFighter()` : assigne le combat, appelle `Initialize()`, ajoute le Fighter à l'équipe et notifie le combat ;
- `Fighters/AIFighter.cs`, méthode `Initialize()` : attribue un identifiant contextuel avec `Fight.PopNextContextualId()` et crée le cerveau ;
- `Timeline/FightTimeline.cs`, méthode `InsertFighter()` : insertion de l'invocation dans la structure de tour ;
- `Fighters/SummonedFighter.cs`, méthode `OnSummoned()` : point d'entrée post-spawn, incluant les sorts initiaux natifs.

Le message réseau exact est `Giny.Protocol/Messages/Game/Actions/Fight/GameActionFightSummonMessage.cs`. Les informations envoyées par `SummonedMonster.GetFightFighterInformations()` sont un `GameFightMonsterInformations` comprenant notamment l'identifiant contextuel, le `creatureGenericId`, le grade, le niveau, l'équipe, la position, le look et les statistiques.

### 2. IA native Giny

`Fighters/AIFighter.cs` est la base des combattants autonomes. Son `Initialize()` crée systématiquement un `MonsterBrain`. Son `OnTurnBegin()` exécute `Brain.Play()`, puis appelle `PassTurn()` si le Fighter est encore vivant.

`AI/MonsterBrain.cs` applique une séquence générique :

```text
SummonAction
→ MarkAction
→ BuffAction
→ HealAction
→ CastOnEnemyAction
→ MoveToTarget
→ BuffAction
→ FleeAction
```

Fonctionnement vérifié :

- les sorts disponibles proviennent de `SummonedMonster.GetSpells()`, donc de `MonsterRecord.SpellRecords` et du niveau correspondant au `MonsterGrade` ;
- `AI/CastOnEnemyAction.cs` examine les sorts de catégories agressives ou debuff, énumère les lancers possibles, vérifie `Fighter.CanCastSpell()`, attribue une efficacité puis exécute le meilleur lancer ;
- la sélection favorise notamment les ennemis non invoqués et les cibles faibles ;
- `AI/MoveToTarget.cs` choisit le combattant ennemi le plus proche, essaie les sorts de téléportation utilisables, puis cherche un chemin vers la cible ;
- `AIFighter.FindPath()` utilise `Pathfinding`, y place les Fighters du combat comme obstacles et limite le chemin aux PM disponibles ;
- le lancer effectif repasse par `Fighter.CastSpell()` et le tour se termine par `PassTurn()`.

L'IA est donc générique et automatiquement applicable aux `AIFighter`. Les sorts et statistiques viennent des records, mais aucune architecture de comportement individuel configurable par monstre n'a été identifiée dans ce chemin. Ses heuristiques sont simples et l'ordre des actions est fixe.

**Pour une Anomalie nécessitant une action déterministe, préférer un contrôle serveur direct plutôt que `MonsterBrain`.**

### 3. Entité sans IA et sans tour

Cette architecture est supportée par le code existant. La référence technique est `Fighters/SummonedBomb.cs`, qui hérite de `SummonedMonster` et surcharge :

```csharp
public override bool CanPlay()
{
    return false;
}

public override bool DisplayInTimeline()
{
    return false;
}
```

`Fight.AddSummons()` insère encore l'objet dans la structure interne de timeline, mais `CanPlay() == false` empêche sa sélection pour un tour et `DisplayInTimeline() == false` empêche son affichage dans la timeline client.

L'entité reste néanmoins :

- présente sur la carte ;
- un véritable `Fighter` de son `FightTeam` ;
- ciblable et attaquable ;
- prise en compte par l'occupation des cellules, les collisions et le pathfinding ;
- capable de recevoir dégâts, soins, buffs et états ;
- capable de mourir par le chemin natif ;
- sans tour joué et sans affichage dans la timeline.

Ce modèle est la base obligatoire d'une entité statique d'Anomalie telle qu'Alterego.

### 4. Entité contrôlée directement par le serveur

`Fighters/Fighter.cs`, méthode `ExecuteSpell(short spellId, byte grade, CellRecord targetCell)`, construit un `SpellCast`, lui assigne `Force = true`, puis appelle `CastSpell()`.

Architecture de référence :

```text
spawn entité sans tour
→ serveur sélectionne la cible et la cellule
→ Fighter.ExecuteSpell()
→ séquence, animation et effets normaux du sort
→ Fighter.Die() après résolution
```

Aucun `MonsterBrain` ni tour autonome n'est nécessaire. Le lancement forcé contourne notamment l'obligation d'être le Fighter actif, la possession normale du sort et le coût en PA (`SpellCast.ApFree` dépend de `Force`). Il continue toutefois à passer par `FightEventApi.CanCastSpell()`, le `SpellManager`, les handlers d'effets, les séquences de combat et les messages de lancement de sort.

Précautions obligatoires : un lancement forcé peut contourner les restrictions normales de tour, de PA et de possession du sort. Il peut également déclencher les effets, buffs, marques, réactions, vérifications de fin de combat ou demandes de passage de tour attachés au sort. Le sort choisi doit donc être audité avant réutilisation et le cycle complet reste à valider en jeu.

### 5. Affichage client Dofus 2.68

La chaîne client vérifiée dans `serveur-local/patches/anomalies-native-rebuild-20260922/scripts/com/ankamagames/dofus/logic/game/fight/frames/FightSequenceFrame.as` est :

```text
GameActionFightSummonMessage
→ FightSequenceFrame.fighterSummonEntity()
→ FightSequenceFrame.summonEntity()
→ GameFightShowFighterMessage
→ FightEntitiesFrame.process()
→ FightSummonStep
→ entité visible
```

`summonEntity()` crée et fait traiter un `GameFightShowFighterMessage`, récupère ensuite le sprite par son identifiant contextuel et ajoute un `FightSummonStep`. Pour les informations de type `GameFightMonsterInformations`, le client consulte aussi le `creatureGenericId`, notamment pour déterminer certains attributs de créature ou de bombe.

En réutilisant :

```text
MonsterRecord existant
+ MonsterGrade existant
+ EntityLook existant
```

le client possède déjà les données et assets nécessaires à l'apparence et aux animations. Aucune modification de `DofusInvoker.swf`, aucun nouveau D2O et aucun nouveau D2P ne sont nécessaires pour cette architecture.

Une entité totalement custom avec un `EntityLook` envoyé par le serveur mais sans véritable `MonsterRecord` client semble permise par une partie du protocole. Le client effectue cependant aussi des résolutions par `creatureGenericId`. Cette possibilité est donc **NON VÉRIFIÉE EN JEU** et ne doit jamais être présentée comme validée.

### 6. Ciblage, zones et collisions

Une invocation ajoutée par `FightTeam.AddFighter()` entre dans les collections normales du combat. Elle devient donc compatible avec :

- `Fight.GetFighter(short cellId)` et les recherches génériques de Fighters dans `Fight.cs` ;
- `Fight.IsCellFree()` dans `Fight.cs`, qui considère une cellule occupée par un Fighter vivant comme non libre ;
- les zones de sorts et la résolution des cibles par les handlers ;
- les critères `TargetMask`, notamment `Effects/Targets/TargetTypeCriterion.cs`, qui reconnaissent aussi `SummonedFighter` ;
- le pathfinding de `AIFighter.FindPath()`, qui ajoute les Fighters comme obstacles ;
- les collisions, mouvements, poussées et échanges de position gérés par `Fighter.cs` ;
- les dégâts, soins, buffs, états et déclencheurs appliqués aux `Fighter` ;
- le système de mort commun `Fighter.Die()`.

La présence dans le `FightTeam`, une cellule valide, l'état vivant et un identifiant contextuel unique sont donc des invariants nécessaires pour qu'une entité temporaire soit traitée comme un véritable combattant.

### 7. Mort et nettoyage

Le chemin recommandé est `Fighters/Fighter.cs`, méthode `Die(Fighter killedBy)` :

```text
Fighter.Die()
→ PV courants à zéro et DeathTime
→ TriggerBuffs(OnDeath)
→ killedBy.TriggerBuffs(OnKill)
→ Alive = false
→ KillAllSummons()
→ RemoveAllCastedBuffs()
→ RemoveMarks()
→ GameActionFightDeathMessage
→ OnDie()
→ traitement client de la mort
```

Si l'entité meurt pendant son propre tour, `Die()` demande aussi le passage de tour. `SummonedFighter.OnDie()` conserve le traitement commun puis ajuste si nécessaire le contexte d'une invocation contrôlée.

`FightTeam.RemoveFighter()` et `FightTimeline.RemoveFighter()` existent, ainsi que les messages génériques de retrait de contexte, mais aucun chemin complet et générique de despawn silencieux en combat n'a été identifié comme équivalent sûr à `Die()` pour une invocation temporaire.

Il n'existe pas actuellement de hook générique `OnDespawn` équivalent identifié. Pour les premiers systèmes d'Anomalies, préférer la mort native à un despawn silencieux custom.

### 8. Hooks disponibles

Points d'accroche vérifiés :

- `Fight.TurnStarted` : événement global de début de tour ;
- `Fight.TurnEnded` : événement global de fin de tour ;
- `Fighter.Death` : événement cible/source déclenché par `OnDie()` ;
- `Fighter.DamageReceived` : événement contenant les dégâts et leur résultat ;
- `Fighter.Moved` : événement après déplacement ;
- `Fighter.Tackled` : événement de tacle ;
- `SummonedFighter.OnSummoned()` : initialisation post-spawn ;
- `Fighter.OnTurnBegin()` : début du tour du Fighter ;
- `Fighter.OnTurnEnded()` : fin du tour du Fighter ;
- `Fighter.OnDie()` : traitement extensible après la mort native.

Le runtime Anomaly doit se désabonner explicitement des événements auxquels il s'abonne lorsque le combat se termine ou lorsque l'entité meurt, afin d'éviter de conserver un état temporaire périmé.

### 9. Architecture recommandée pour les Anomalies

| Besoin | Architecture recommandée | Comportement |
|---|---|---|
| Entité statique et ciblable | Modèle `SummonedBomb` | `Fighter` sans tour, sans IA et masqué dans la timeline. |
| Alterego | Fighter statique lié à une cible métier | Sans IA ; `DisplayInTimeline() == false` ; `Death` déclenche l'effet ou le malus sur la cible liée. |
| Pantin | Fighter statique piloté par le serveur | Le serveur choisit la cible, appelle `ExecuteSpell()`, puis utilise la mort native. |
| Invocation réellement autonome | `SummonedMonster` + `MonsterBrain` | Tour propre, sélection générique des actions, déplacement et sorts issus du record. |

### 10. Invariants techniques

- Le serveur est la source de vérité.
- Ne pas créer un nouveau moteur d'IA.
- Réutiliser `MonsterBrain` uniquement lorsqu'une vraie autonomie est voulue.
- Pour une action déterministe d'Anomalie, préférer `Fighter.ExecuteSpell()`.
- Réutiliser en priorité des `MonsterRecord`, `MonsterGrade` et `EntityLook` existants.
- Ne pas modifier `DofusInvoker.swf` pour une invocation utilisant du contenu existant.
- Une entité sans tour doit suivre le modèle éprouvé de `SummonedBomb`.
- Préférer `Fighter.Die()` pour le nettoyage tant qu'un despawn propre n'est pas validé.
- Ne jamais présenter une mécanique comme validée en jeu uniquement parce qu'elle semble supportée par le code.

### 11. État de validation

**VALIDÉ PAR LECTURE DU CODE :**

- infrastructure native d'invocation ;
- construction et exécution générique de `MonsterBrain` ;
- intégration d'un Fighter ajouté au ciblage et à l'occupation des cellules ;
- modèle `SummonedBomb` sans tour ;
- masquage de timeline avec `DisplayInTimeline() == false` ;
- lancement direct par `Fighter.ExecuteSpell()` ;
- messages et chaîne d'affichage client d'une invocation ;
- mort et nettoyage par `Fighter.Die()`.

**NON ENCORE VALIDÉ EN JEU :**

- commande `.anomalyentity` ;
- Alterego réel ;
- Pantin réel ;
- entité totalement custom sans `MonsterRecord` ;
- cycle complet spawn → action → mort depuis le runtime Anomaly ;
- retrait silencieux complet sans passer par `Fighter.Die()`.

### 12. Prototype futur — TODO uniquement

Commande future : `.anomalyentity`.

Objectif du futur test :

- réutiliser un `MonsterRecord` existant ;
- apparaître sur une cellule libre adjacente au joueur ;
- posséder 100 PV ;
- ne pas utiliser d'IA ;
- ne jouer aucun tour ;
- être caché de la timeline ;
- rester ciblable et attaquable ;
- durer deux tours ;
- appeler `Fighter.Die()` à expiration.

Ce prototype n'est ni implémenté ni validé. Il reste un TODO documentaire et ne doit pas être confondu avec une fonctionnalité disponible.

## Association Donjon / Boss / Anomalie / Bestiaire / Obtention

Cette section définit la relation officielle et permanente entre les 124 donjons retenus, leurs boss et les 124 Anomalies prévues.

### Principe d'association

Chaque Anomalie doit être associée à un boss de donjon précis. Elle fait partie des objets et récompenses propres à ce boss et, une fois son intégration terminée, doit apparaître dans ses butins dans le Bestiaire Dofus.

```text
donjon
→ boss
→ Anomalie associée
→ drop réel côté serveur
→ affichage du drop dans le Bestiaire
```

L'association ne doit jamais exister uniquement dans un tableau de design. Une intégration complète exige à la fois une association serveur fonctionnelle et une représentation Bestiaire fonctionnelle.

### Règle de conception des 124 Anomalies

On n'invente pas d'abord une Anomalie pour chercher ensuite où la placer. La conception part du contenu existant :

```text
donjon
→ mécanique et identité du boss
→ concept thématique de l'Anomalie
→ effet de l'Anomalie
→ drop du boss
→ affichage Bestiaire
```

Une Anomalie doit donc être thématiquement liée au boss qui la fournit.

### Source de vérité minimale

Pour chaque association, le registre officiel doit conserver au minimum :

- `DungeonId` ;
- nom du donjon ;
- `BossMonsterId` réel provenant des données Dofus 2.68 ;
- nom du boss ;
- GID de l'Anomalie ;
- nom de l'Anomalie ;
- taux de drop ;
- éventuelles conditions ;
- statut de l'intégration Bestiaire ;
- statut du drop serveur ;
- source ayant permis de vérifier chaque identifiant.

Les 124 `BossMonsterId` ne doivent jamais être remplis arbitrairement. Ils doivent être récupérés et vérifiés progressivement depuis les données réelles du projet Dofus 2.68.

### Drop serveur et données du Bestiaire

Deux mécanismes distincts doivent être contrôlés :

1. le drop réellement calculé et attribué par le serveur Giny ;
2. les données lues par le client pour présenter les butins du monstre dans le Bestiaire.

Ces mécanismes peuvent reposer sur des sources ou des synchronisations différentes. La présence de l'Anomalie dans le Bestiaire ne prouve pas qu'elle peut réellement tomber. Inversement, un drop serveur fonctionnel ne prouve pas que le Bestiaire l'affiche.

Une association n'est terminée que si les deux chaînes sont validées en jeu :

```text
boss → drop serveur réel de l'Anomalie
ET
Bestiaire → fiche du boss → Butins → Anomalie visible
```

L'objectif est de réutiliser au maximum le Bestiaire natif. Aucune UI Bestiaire custom ne doit être créée tant que les données natives Dofus permettent de déclarer et d'afficher correctement le drop.

### Procédure standard pour une nouvelle Anomalie

1. Identifier le donjon retenu.
2. Identifier le boss exact dans les données Dofus 2.68.
3. Récupérer et documenter son `MonsterId` réel sans le deviner.
4. Créer ou intégrer l'item Anomalie.
5. Lui attribuer son GID.
6. Implémenter son roll spécifique.
7. Associer le drop au boss côté serveur.
8. Ajouter ou configurer les données natives nécessaires à son affichage dans le Bestiaire.
9. Vérifier en jeu : Bestiaire → recherche du boss → fiche → Butins → Anomalie visible.
10. Vérifier réellement l'obtention du drop côté serveur.
11. Seulement après ces contrôles, inscrire séparément : `Boss association = VALIDÉE`, `Bestiaire = VALIDÉ` et `Drop = VALIDÉ`.

### Registre officiel des associations

La KB devra contenir ou référencer un registre technique ayant cette structure :

| DungeonId | Donjon | Boss MonsterId | Boss | Anomaly GID | Anomalie | Taux | Conditions | Bestiaire | Drop serveur |
|---:|---|---:|---|---:|---|---:|---|---|---|
| `41` | Goulet du Rasboul | `1071` | Silf le Rasboul Majeur | `32761` | Rémanence | `1 %` pour les grades 1 à 5 | Aucune ; 1 jet, limite 1, verrou PP 0 | IMPLÉMENTÉ — À VALIDER EN JEU | IMPLÉMENTÉ — À VALIDER EN JEU |
| À déterminer | À déterminer | À déterminer | **À DÉTERMINER** | `32760` | Écho | À déterminer | À déterminer | NON INTÉGRÉ / NON VALIDÉ | NON INTÉGRÉ / NON VALIDÉ |

Ce tableau ne constitue pour l'instant que le début du registre. Il ne faut pas préremplir les 122 autres associations sans vérification individuelle.

### Cas vérifié : Rémanence et le Goulet du Rasboul

Association de design retenue :

```text
DungeonId 41 — Goulet du Rasboul
→ MonsterId 1071 — Silf le Rasboul Majeur
→ GID 32761 — Rémanence
```

Le `MonsterId 1071` est **VALIDÉ PAR LES DONNÉES LOCALES** :

- `serveur-local/sql/giny_world.sql`, table `monsters`, ligne d'insertion `(1071, 'Silf le Rasboul Majeur', ...)` ; la colonne `IsBoss` vaut `1` dans cet enregistrement ;
- `project/Giny.NETCore-2.68/Sources/Modules/Giny.DatabasePatcher/Monsters/Dungeons.cs`, bloc `Goulet du Rasboul` : `DungeonRecord.GetDungeon(41)` et salle finale `MonsterRoom(..., 1070, 1071, ...)`, accompagnée du commentaire nommant Silf le Rasboul Majeur.

Cette double correspondance valide techniquement l'identité du boss et son appartenance au donjon 41.

Intégration effectuée le 23 septembre 2026, restant à valider en jeu :

- taux de base `1 %` identique pour les grades 1 à 5 ;
- un jet par bénéficiaire, limite globale native de `1`, verrou de prospection `0`, aucune condition ;
- `AnomalyDropManager.ConfigureOfficialDrops()` ajoute le drop `32761` au `MonsterRecord 1071` au chargement du serveur ;
- l'ancien drop de développement de Rémanence sur le Bouftou Royal a été retiré ; le comportement d'Écho n'a pas été modifié ;
- `MonsterFighter.RollLoot()` conserve la formule native : taux de base × prospection du bénéficiaire × bonus de challenge × `WorldConfig.DropRate`. Avec 100 PP, aucun bonus et la configuration déployée `DropRate = 1.0`, le taux effectif est `1 %` ;
- `FightPvM` crée toute Anomalie gagnée avec `ItemsManager.CreateCharacterItem()`, qui appelle `AnomalyRollManager.AddGeneratedRolls()` ; une Rémanence reçoit donc `3103 = 150..250` et `3104 = 1..2` ;
- `FightPlayerResult.Apply()` ajoute cette instance précise à l'inventaire, sans recréer un objet brut ;
- `Monsters.d2o`, enregistrement `Monster 1071`, contient une unique entrée `MonsterDrop` vers `32761`, à `1 %` pour les cinq grades ;
- l'injection D2O modifie uniquement les octets de l'index `1071` et ajoute son nouvel enregistrement en fin de fichier. La première méthode, qui reconstruisait tout le D2O, réduisait le fichier de 11 423 926 à 8 639 273 octets et vidait le Bestiaire ; elle a été abandonnée et le fichier natif restauré avant cette correction ciblée ;
- le même défaut historique touchait `Items.d2o` (6 772 768 octets au lieu des 11 972 717 octets natifs) et `ItemTypes.d2o` (11 263 au lieu de 24 861), ce qui vidait tous les onglets et neutralisait la recherche de l'Encyclopédie. Les bases natives ont été restaurées, puis Écho `32760` et Rémanence `32761` ont été réinjectés avec une opération d'index ciblée ;
- `ItemSets.d2o` et `Effects.d2o` présentaient également des divergences index/recherche (`618/504` et `817/764`). Leurs versions natives ont été restaurées et valident maintenant `504/504` et `764/764` ; les versions précédentes restent sauvegardées avec le suffixe `.before-encyclopedia-repair-20260923.bak` ;
- les descriptions d'Écho et Rémanence utilisent désormais une ligne en gras avec `Rareté :` en doré (`#E8C34A`) et `Épique` en violet (`#B15CFF`), puis un corps en gras bleu ciel (`#67CFFF`). La classe de tooltip objet `.quote` est configurée sans italique dans les CSS normal et petit écran du thème `darkStone` ;
- l'audit du code réellement exécuté dans `DofusInvoker.swf` montre que `ItemTooltipUi` définit `ANOMALY_TYPE_ID = 290` et choisit `iconUri` uniquement pour ce type ; tout autre type utilise `fullSizeIconUri`. Le passage client à `233` était donc la cause déterministe du cadre vide, car aucune grande icône correspondante n'existe. Écho et Rémanence utilisent de nouveau le type client et serveur `290` ;
- l'audit de `AbstractItemFilterManager` montre que l'onglet Ressources intersecte successivement les index `typeId`, `etheral=false`, `isSaleable=true` et `level`, puis appelle `queryString(Item, "name", recherche)`. Le précédent patch ne renseignait que `typeId` et `nameId`, et les deux objets avaient encore `isSaleable=false` : ils étaient donc retirés avant même la recherche textuelle. Le réparateur positionne maintenant `isSaleable=true` et inscrit les deux IDs dans les groupes exacts de `id`, `typeId=290`, `nameId`, `level=1`, `etheral=false` et `isSaleable=true`. Après réparation, `Items.d2o` valide `18 844` objets dans les index `id`, `typeId` et `nameId`, et `ItemTypes.d2o` valide `220` objets/index avec le type `290` ;
- l'icône Rémanence `32761.png` est présente dans `bitmap0_1.d2p` (8 883 octets). Les archives D2P d'objets étant liées, elle ne doit pas être dupliquée dans `bitmap1_1.d2p`, qui a été restauré à l'identique depuis sa sauvegarde ;
- `BestiaryTab.as` lit nativement `monster.drops`, construit l'`ItemWrapper` depuis `objectId` et présente le taux sans hardcode UI ;
- l'icône `32761.png` du D2P et l'asset du module utilisent la nouvelle image Rémanence.

Diagnostics ajoutés :

```text
[ANOM-DROP] boss=1071 item=32761 roll=<tirage>/<taux ajusté> -> PROC|FAIL
[ANOM-DROP] Rémanence créée uid=<UID> chance=<15.0..25.0>% pa=<1..2>
```

Statuts actuels :

```text
Boss association : VALIDÉE PAR LES DONNÉES
Drop serveur : IMPLÉMENTÉ — À VALIDER EN JEU
Bestiaire : IMPLÉMENTÉ — À VALIDER EN JEU
Rolls 3103/3104 sur un drop réel : IMPLÉMENTÉ — À VALIDER EN JEU
Nouvelle icône : IMPLÉMENTÉE — À VALIDER EN JEU
```

Hashes SHA-256 déployés :

| Fichier | SHA-256 |
|---|---|
| `serveur-local/world/Giny.World.dll` | `2E2B8F3B085A5DC6A15376E4522F49CDE668232283FCBF45C418A518BED4F101` |
| `2.68.0.0/Dofus/data/common/Items.d2o` | `7339B8F8A3C2DA81A2183655FF6CD3F15EA9D3FB895D3926999E7896BFE4C51C` |
| `2.68.0.0/Dofus/data/common/ItemTypes.d2o` | `EAFD51D611CD2C9E7B13FD3F34AC3EE1D86AE93FD0C5B70B14457FB53467674A` |
| `2.68.0.0/Dofus/data/common/ItemSets.d2o` | `520F2C6F8D81EDB2FB56D571A02CA1EB41515A75A5BF6AB27AC3C7C87120355A` |
| `2.68.0.0/Dofus/data/common/Effects.d2o` | `6BBC0DE1DF38E05874334834609FD0C4F3DB9674E3EC2ED926B8DC6C54A4FD90` |
| `2.68.0.0/Dofus/data/common/Monsters.d2o` | `5408B2D92D28CFD5F1D4B7A10F231126A56444051F02A4D864FC3959438C73CA` |
| `2.68.0.0/Dofus/content/gfx/items/bitmap0_1.d2p` | `62D5678E5CFF8D2CBCBFED7F80AD35CAC6B4628AAE52DBEC5A4CA7AB2D82EE82` |
| nouvelle `Remanence_64x64.png` | `9D9CEA5C76B4C2EA627B1D5C7F281D91FFAAE19CE66627810D2A1C039771CDB4` |

Une anomalie découverte durant l'intégration a également été corrigée dans `Giny.IO/D2P/D2PFile.SaveAs()` : l'écriture sur un D2P existant doit tronquer le flux avant réécriture. Sans cela, un ancien pied de fichier pouvait rester après une archive raccourcie et rendre le D2P illisible.

### Cas actuel : Écho

Écho possède le GID `32760`, mais aucune association définitive à l'un des 124 donjons n'a été décidée.

```text
Boss association : À DÉTERMINER
Bestiaire : NON INTÉGRÉ / NON VALIDÉ
Drop serveur : NON INTÉGRÉ / NON VALIDÉ
```

Aucun boss ne doit lui être assigné arbitrairement.

### Invariants d'intégration

- Le registre officiel est la source de vérité technique des 124 associations.
- Tout identifiant de donjon, monstre ou item doit provenir des données réelles et conserver sa source de vérification.
- Le serveur reste la source de vérité pour l'obtention effective.
- Le Bestiaire natif doit être utilisé avant d'envisager une UI custom.
- Un affichage Bestiaire fonctionnel ne valide pas le drop serveur.
- Un drop serveur fonctionnel ne valide pas l'affichage Bestiaire.
- Les statuts `VALIDÉ` ne peuvent être attribués qu'après vérification en jeu de la partie concernée.
- Aucun prototype de zone ou d'entité ne doit modifier implicitement cette architecture d'obtention.

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
