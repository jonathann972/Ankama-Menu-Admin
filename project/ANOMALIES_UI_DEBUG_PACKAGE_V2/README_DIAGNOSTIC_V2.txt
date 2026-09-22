DOFUS 2.68 - ANOMALIES UI - DIAGNOSTIC ACTUEL
==============================================

Etat valide confirme auparavant
-------------------------------
Le smoke test magenta (Container 700x500 + Label + Button) etait visible.
Logs confirmes :
- metadata Api presentes
- AnomaliesUi associee a uiRenderer.script et uiClass
- UIRenderComplete recu
- uiApi.getUi("anomaliesUi") != null

Cause historique resolue
-------------------------
mxmlc supprimait les metadonnees [Api]. Le module est maintenant toujours
compile avec : --keep-as3-metadata+=Api

Etat actuel problematique
-------------------------
Apres integration du fond PNG genere et des composants dynamiques, le panel
avait ete visible une premiere fois. Une version suivante (pagination,
redimensionnement grille, boutons d'onglets avec strata HIGH) est devenue
totalement invisible, tout en restant enregistree comme ouverte.

Les strata HIGH ont ensuite ete retires et le SWF recompilé/deploye, mais le
symptome reste identique chez l'utilisateur :
- clic recu
- load/rendu sans erreur visible
- Verification : OUVERT
- aucun pixel du panel a l'ecran

Le PNG v2 est valide : 1100x700 ARGB, coins alpha=0, centre alpha=252.

Demande de diagnostic
---------------------
Comparer exactement :
1. anomaliesSmoke.VISIBLE_MAGENTA.xml (smoke visible confirme)
2. anomaliesSmoke.CURRENT_INVISIBLE.xml (etat actuel)
3. les SWF smoke visible et actuel

Verifier en priorite :
- si un composant XML additionnel empeche finalisation/dessin sans unload ;
- les simpleButton de pagination et leur label XML "&lt;" / "&gt;" ;
- les Button transparents sans texture/hit area ;
- la taille et l'ordre de ctr_anomalies_content ;
- un event ou code main() rendant ctr_anomalies_content/root invisible ;
- le cache UiDefinition Berilia, puisque l'UiData conserve le meme file/name ;
- la necessite d'appeler UiRenderManager.clearCacheFromId(file) apres changement XML ;
- les logs/stack traces de UiRootContainer et UiRenderer.

Important
---------
- Ne pas modifier le DofusInvoker, le bridge, le UiData, le .dm ou le bouton :
  leur pipeline fonctionne.
- Ne pas reconstruire le design avant d'avoir explique pourquoi l'UI est
  OUVERT mais invisible.
- Le dossier contient les versions et sources exactes necessaires.
