# Ankama Anomalies UI recovery

This directory contains the reproducible sources and diagnostics for the Dofus
2.68 Anomalies UI.

## Native smoke-test state

`module/Ankama_Anomalies.dm` now registers `anomaliesUi` through Berilia and
loads the minimal 700x500 magenta smoke UI. The module registry points directly
to the native `AnomaliesModuleRuntime`; no runtime `UiData`, external `Loader`,
or DIAG identifier is involved.

## Native rebuild source

`native-patch-source/` contains the JPEXS import unit used by the deployed
native smoke test. It embeds `AnomaliesModuleRuntime` in the same ABC block as
`Modules` and maps the module ID directly to it.

The existing public ABC slot named `AnomaliesModuleBridge` is retained only as
the binary-compatible public UI class resolved by `UiModule.bindUiClasses()`.
Its implementation is no longer a bridge: it contains no `Loader` and no
`ApplicationDomain` manipulation. It is the minimal UI script whose `main()`
logs `[ANOM-NATIVE] AnomaliesUi.main OK`.

The generated `DofusInvoker.swf` is deliberately not committed. Rebuild it
against the exact 2.68 client binary with a 64-bit JVM (FFDec requires more
than the 32-bit Java heap can provide), then re-export `Modules`,
`AnomaliesModuleRuntime`, and `AnomaliesModuleBridge` before deployment.

## Relevant files

- `module/src/`: ActionScript source for the external diagnostic module.
- `module/xml/`: Berilia UI definitions.
- `native-patch-source/`: minimal native registry experiment.
- `docs/`: project specification and runtime diagnosis.
