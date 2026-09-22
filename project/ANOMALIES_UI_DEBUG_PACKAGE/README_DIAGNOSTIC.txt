DOFUS 2.68 - MODULE ANKAMA_ANOMALIES - DIAGNOSTIC BERILIA
==========================================================

Objectif
--------
Afficher une interface Berilia native depuis le bouton Anomalies ajoute dans
le bannerMenu. Le module doit rester independant dans Dofus/ui/Ankama_Anomalies.

Etat actuel
-----------
- Le client demarre correctement.
- Le bouton Anomalies est visible et le callback est bien execute.
- Le module SWF externe est charge par AnomaliesModuleBridge.
- UiApi.loadUi("anomaliesUi", "anomaliesUi") renvoie un UiRootContainer.
- Le fichier anomaliesSmoke.xml est accessible par URLLoader (1582 octets).
- new XML(contenu) confirme une racine Definition valide.
- Environ 800 ms plus tard, uiApi.getUi("anomaliesUi") renvoie null/ABSENT.
- AnomaliesUi.main() n'est jamais atteint : aucun message
  "Classe UI initialisee" n'apparait.

Logs observes
-------------
[ANOMALIES-UI] Clic recu.
[ANOMALIES-UI] XML : file://C:/.../Dofus/ui/Ankama_Anomalies/xml/anomaliesSmoke.xml
[ANOMALIES-UI] loadUi retourne : [object UiRootContainer]
[ANOMALIES-UI] XML LU : 1582 octets
[ANOMALIES-UI] XML VALIDE : Definition
[ANOMALIES-UI] Verification : ABSENT

Architecture particuliere
-------------------------
Le client Dofus 2.68 embarque normalement les classes principales des modules
dans DofusInvoker.swf via com.ankamagames.dofus.Modules.scripts.

Ankama_Anomalies.dm conserve volontairement <uis></uis>, car declarer l'UI au
chargement initial avait provoque un blocage du client a 48 %.

La classe AnomaliesModuleBridge est referencee par Modules.scripts. Elle charge
ensuite Ankama_Anomalies.swf. La derniere tentative utilise un LoaderContext sur
ApplicationDomain.currentDomain. Modules et le pont ont ete recompiles ensemble.

Le module enregistre ensuite dynamiquement un UiData :
  name      = anomaliesUi
  file      = module.rootPath + "xml/anomaliesSmoke.xml"
  className = Ankama_Anomalies.ui::AnomaliesUi
  uiClass   = getDefinitionByName(...) as Class

Hypothese restante
------------------
L'echec est asynchrone dans le rendu Berilia, avant l'appel de main() de la
classe UI. Il faut inspecter PoolableUiRenderer/UiRenderer, ApiBinder ou
SecureCenter, et/ou ecouter UiRenderEvent afin d'obtenir l'exception masquee.

Fichiers importants du paquet
-----------------------------
module/                 module independant complet (DM, SWF, AS, XML, assets)
bridge-source/          sources Modules et AnomaliesModuleBridge
invoker-current/        DofusInvoker actuellement deploye
invoker-stable-before/  version precedente avec bouton fonctionnel et domaine enfant
runtime-reference/      sources decompilees utiles (UiData, UiModule, UiRenderManager)
docs/                   cahier des charges et mockup PNG

Contraintes fonctionnelles
--------------------------
- Ne pas dupliquer le bouton ou le panel.
- Conserver le module Ankama_Anomalies independant autant que possible.
- Ne pas modifier le gameplay, les drops ou les donnees serveur.
- Le rendu final doit utiliser les composants et le style natifs Dofus 2.68.
