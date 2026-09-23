# Restauration rapide — Anomalies

## Baseline recommandée

Le point de restauration stable courant est :

```text
DofusInvoker.baseline-echo-inventory-validated-20260923.bak.swf
SHA256: 049F23E30E33A4AD42617A20D684F88DF645A86842F6537C3080A6D5DF6C4A29
```

Cette baseline valide le démarrage, le bouton, le panneau, le contrôleur natif, la lecture d'Écho, le type runtime `290` et le rendu de ses jets. Elle doit être utilisée avant tout diagnostic concernant les prochaines étapes d'équipement.

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

## Règle obligatoire

**Une seule couche doit être modifiée/testée à la fois.**

Ordre de validation :

```text
démarrage → module → bouton → ouverture UI → contrôleur → inventaire → rendu → équipement
```

Ne jamais réintroduire une architecture documentée comme défaillante sans justification explicite.
