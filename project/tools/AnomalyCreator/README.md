# Anomaly Creator

Outil externe pour préparer et injecter une nouvelle Anomalie Dofus 2.68 sans reconstruire les index globaux.

## Utilisation

1. Copier `anomaly.example.json` et remplir les valeurs.
2. Placer le PNG 64×64 à côté du JSON (ou indiquer un chemin absolu).
3. Fermer le client Dofus.
4. Exécuter :

```powershell
.\AnomalyCreator.exe audit .\mon-anomalie.json "C:\chemin\Dofus"
.\AnomalyCreator.exe apply .\mon-anomalie.json "C:\chemin\Dofus"
.\AnomalyCreator.exe verify .\mon-anomalie.json "C:\chemin\Dofus"
```

`apply` crée une sauvegarde horodatée dans `AnomalyCreatorBackups`, puis modifie seulement : l'objet concerné dans `Items.d2o`, les deux textes D2I, le PNG dans `bitmap0_1.d2p` et l'entrée du boss dans `Monsters.d2o`.

Pour annuler la dernière application :

```powershell
.\AnomalyCreator.exe rollback .\mon-anomalie.json "C:\chemin\Dofus"
```

L'outil génère aussi `generated/anomaly-<gid>.txt` avec les constantes, jets et mappings à reporter dans le serveur et `ItemTooltipUi`. Il ne tente pas d'inventer la mécanique de combat : cette partie reste nécessairement spécifique à chaque Anomalie.

Pour régénérer la liste des boss et de leurs identifiants :

```powershell
.\AnomalyCreator.exe bosses "C:\chemin\Dofus" .\LISTE_BOSS_MONSTER_ID.txt
```
