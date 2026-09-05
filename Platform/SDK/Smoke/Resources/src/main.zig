//! RSRCFIX - dauerhaftes Smokefixture fuer den R4M0-Ressourcenbereich.
//!
//! Das Programm selbst ist bewusst leer bis auf einen Marker: Sein Wert
//! liegt in den EINGEBETTETEN Ressourcen (zwei Icons, ein Helpfile, eine
//! benannte Datei), die RESDIAG ab 0.61.13 im Gast liest und byteweise
//! gegen die Bauquellen vergleicht. Die Bauquellen unter Assets/ sind
//! deterministische, eingecheckte Fixtures und duerfen sich nicht aendern.
const r4os = @import("r4os");

pub fn r4_app_main(app: *r4os.App) i32 {
    if (app.profile != .console or !app.hasGroup(.r4sys)) return 71;
    const sys = app.system();
    sys.println("RSRCFIX result: OK");
    return 0;
}
