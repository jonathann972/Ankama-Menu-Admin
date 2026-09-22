# Diagnostic UI Anomalies — état transmis

## Symptôme actuel

- Le bouton Anomalies est bien présent dans le menu.
- Un clic produit dans le chat : `[ANOMALIES-UI] Verification : OUVERT`.
- Aucun pixel du panneau n'est visible à l'écran.
- Le problème est apparu pendant un travail qui devait seulement remplacer les images de l'UI.
- Une version antérieure du panneau s'affichait correctement.

## Résultat du diagnostic display list

Un nouveau SWF a été compilé avec les opérations suivantes dans `onRenderComplete` :

- lecture de `uiApi.getUi("anomaliesUi")` ;
- dump du root, de ses parents et de ses enfants ;
- ajout direct au root d'un `Sprite` Flash magenta de 500 × 500 pixels.

Les deux appels `clearCacheFromId` et `clearCacheFromUiName` ont été désactivés pour ce test.

Après redémarrage complet et clic, le seul message obtenu est :

```text
[ANOMALIES-UI] Verification : OUVERT
```

Aucune ligne `[ANOMALIES-DISPLAY]`, `[ANOMALIES-PARENT]`, `[ANOMALIES-TREE]` ou `SPRITE AJOUTE` n'apparaît, et aucun carré magenta n'est visible. Cela indique que le callback `onRenderComplete` installé sur `UiRenderManager` n'est pas exécuté pour cette ouverture, alors que `uiApi.getUi("anomaliesUi")` renvoie bien un objet 800 ms plus tard.

## Module réellement installé

Le module actif est dans :

`2.68.0.0/Dofus/ui/Ankama_Anomalies/`

Fichiers principaux :

- `Ankama_Anomalies.swf` : binaire actuellement chargé par Dofus.
- `src/Ankama_Anomalies/Ankama_Anomalies.as` : enregistrement et ouverture du panneau.
- `src/Ankama_Anomalies/ui/AnomaliesUi.as` : logique du panneau.
- `xml/anomaliesSmoke.xml` : définition XML réellement enregistrée sous `anomaliesUi`.
- `xml/anomaliesUiV2.xml` : autre définition embarquée dans le SWF, mais non utilisée par `registerPanel()` dans l'état actuel.
- `assets/` : images disponibles dans le module.

## Correctif de cache essayé précédemment

Avant `uiApi.loadUi`, le code appelait :

```actionscript
renderManager.clearCacheFromId(panelFile);
renderManager.clearCacheFromUiName("anomaliesUi");
```

Le SWF a été compilé avec :

```text
-target-player=32.0
-keep-as3-metadata+=Api
```

Une décompilation de contrôle a confirmé la présence des métadonnées `[Api]` et des deux appels de purge. Cela n'a pas résolu le symptôme : Berilia retourne toujours une UI nommée `anomaliesUi`, mais elle reste invisible.

Ces deux appels sont commentés dans la version diagnostique actuellement installée et incluse dans cette archive.

## Contenu complémentaire du ZIP

- `ANOMALIES_UI_DEBUG_PACKAGE_V2/` : snapshots, références runtime et version précédemment visible.
- `assets/` : assets originaux fournis pour la nouvelle interface.
- `CAHIER_DES_CHARGES_ANOMALIES_UI.txt` : cahier des charges.
- `MANIFEST_SHA256.txt` : empreintes des fichiers pour identifier exactement les versions analysées.

## Point important

Le bridge, le bouton et l'appel de chargement fonctionnent suffisamment pour obtenir `Verification : OUVERT`. Le diagnostic doit donc porter en priorité sur le cycle Berilia `UiRootContainer` / rendu / finalisation, la définition XML réellement résolue et la visibilité ou le rattachement du conteneur créé.
