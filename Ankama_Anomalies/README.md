# Ankama Anomalies UI recovery

This directory contains the reproducible sources and diagnostics for the Dofus
2.68 Anomalies UI.

## Safe state

`module/Ankama_Anomalies.dm` intentionally keeps `<uis></uis>`. Declaring
`AnomaliesUi` there while `Modules.scripts["Ankama_Anomalies"]` still points to
the external-loader bridge blocks the client at 48%, because
`UiModule.bindUiClasses()` runs before the bridge loads the external SWF.

## Native rebuild source

`native-patch-source/` contains the minimal JPEXS import unit used to test a
native registration. It embeds `AnomaliesModuleRuntime` and
`AnomaliesUiRuntime` in the same ABC block as `Modules`, removes runtime
`UiData` creation, and maps the module ID to the real module class.

The generated `DofusInvoker.swf` is deliberately not committed. Rebuild and
verify it locally against the exact client binary, then declare the UI in the
module descriptor only after both classes are confirmed in the client
application domain.

## Relevant files

- `module/src/`: ActionScript source for the external diagnostic module.
- `module/xml/`: Berilia UI definitions.
- `native-patch-source/`: minimal native registry experiment.
- `docs/`: project specification and runtime diagnosis.

