# Restauration rapide — Anomalies

## Baseline recommandée

Le point de restauration officiel courant comprend le client et le serveur :

```text
DofusInvoker.baseline-echo-complete-validated-20260923.bak.swf
SHA256: 3A8602C8963EFC645456BECFDD557E32E0B5324CAD11714CD7504ECF1705AEC1

Giny.World.baseline-echo-complete-validated-20260923.bak.dll
SHA256: 842FA006486B004FF0480090E784A36A0BACE70A6D0E95C4AD9F21E0B0BC9FA4
```

Cette baseline valide le démarrage, le bouton, le panneau, le contrôleur natif, la lecture d'Écho, le type runtime `290`, le rendu de ses jets et l'équipement/déséquipement en temps réel. Elle est le point de restauration obligatoire avant toute prochaine fonctionnalité.

Toujours restaurer les deux fichiers ensemble pour conserver la compatibilité entre le hook client et la fin de lot `InventoryWeightMessage` envoyée par le serveur.

## Client bloqué vers 48 %

1. Restaurer la baseline recommandée ci-dessus.
2. Vérifier le `.dm` et le moment de `bindUiClasses()`.
3. Ne pas continuer à modifier d'autres couches.

## Client démarre mais le panneau ne s'ouvre plus

1. Restaurer la baseline recommandée ci-dessus.
2. Comparer les SHA256.
3. Inspecter uniquement les changements du contrôleur ou du bridge.

## Panneau ouvert mais statique

1. Vérifier que `[ANOM-UI]` apparaît.
2. Vérifier une modification visuelle contrôlée comme `Collection TEST`.
3. Ne pas commencer par déboguer `InventoryApi` tant que le contrôleur n'est pas prouvé.

## Modification inventaire sans effet

Prouver successivement :

```text
source → compilation → déploiement → chargement → instanciation → exécution
```

## Équipement persistant mais UI non actualisée

1. Vérifier que le serveur déployé correspond au SHA256 officiel de `Giny.World.dll`.
2. Vérifier la chaîne `ObjectModifiedMessage → HookLock → InventoryWeightMessage → releaseHooks()`.
3. Ne pas simuler l'état au clic et ne pas ajouter de polling.
4. Restaurer ensemble les baselines client et serveur si le hook `[ANOM-EQUIP] hook ObjectModified` n'apparaît plus.

## Règle obligatoire

**Une seule couche doit être modifiée/testée à la fois.**

Ordre de validation :

```text
démarrage → module → bouton → ouverture UI → contrôleur → inventaire → rendu → équipement
```

Ne jamais réintroduire une architecture documentée comme défaillante sans justification explicite.
