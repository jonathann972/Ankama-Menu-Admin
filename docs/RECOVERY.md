# Restauration rapide — Anomalies

## Client bloqué vers 48 %

1. Restaurer la dernière baseline connue.
2. Vérifier le `.dm` et le moment de `bindUiClasses()`.
3. Ne pas continuer à modifier d'autres couches.

## Client démarre mais le panneau ne s'ouvre plus

1. Restaurer le dernier `DofusInvoker.swf` fonctionnel.
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

## Règle obligatoire

**Une seule couche doit être modifiée/testée à la fois.**

Ordre de validation :

```text
démarrage → module → bouton → ouverture UI → contrôleur → inventaire → rendu → équipement
```

Ne jamais réintroduire une architecture documentée comme défaillante sans justification explicite.
