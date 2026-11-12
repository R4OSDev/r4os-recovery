R4STD.R4L
=========

R4STD is an independent Runtime-R4L for text, R4S settings, dates, time zones,
and atomic configuration files. Its contract, baseline, implementation, Zig
and C bindings, generated Rust contract consumers and tests belong entirely
to this library. Higher Rust/C consumers use the original helper functions
through Libraries/Shared/Rust and Bindings/C/r4std_helpers.h; instructions
and lifetime rules are in Libraries/Shared/Rust/README.md. The kernel, central
platform Contract, and core SDK contain no R4STD implementation.

Versioned interfaces:

- R4STD:TEXT_V1:1
- R4STD:CODEC_V1:1
- R4STD:SETTINGS_V1:1
- R4STD:DATE_V1:1
- R4STD:TIME_V1:1
- R4STD:CONFIG_V1:1

Applications import only the interfaces they use and bind
Bindings/Zig/r4std.zig or Bindings/C/r4std.h. Query:1 is the technical module
identity, not a functional R4STD import.

CODEC_V1 provides strict CP437, CP850 and Windows-1252 conversion and scalar UTF-8
encode/decode, plus a caller-owned incremental UTF-8 state. The five existing
interfaces, their IDs/layouts, and Bytes/SystemText/DocumentText semantics are
unchanged. Zig consumers import CODEC_V1 explicitly and use r4std.codec.

CP437 control mode follows the official Microsoft text table. Its separate
pc_graphics mode uses Unicode's IBMGRAPH display mapping for 01..1F and7F;
00 remains U+0000. Windows-1252 rejects its five undefined bytes. CP850 has a
distinct identifier and is unsupported, never treated as CP437. Valid scalars
without an exact inverse are unrepresentable. No guessing, normalization or
automatic replacement. Scalar codecs allow U+0000; TextV1 still rejects NUL.

UTF-8 accepts only shortest scalar encodings. Complete, valid incomplete,
and invalid are distinct. Stream state retains at most three pending bytes
and examines at most four. Negative results consume nothing and preserve
state/output; the caller explicitly resets/reports/replaces and may retry
the offending byte. finish reports unfinished input without discarding it.
Each stream owns its state; call boundaries and streams never share bytes.
Lengths name bytes or scalars; graphemes and display width are separate.

Bulk Zig conversion preflights every scalar, policy and capacity before
writing. Overlap is rejected in both directions. The imported provider stays
pinned and has immutable, stateless mappings for the writing pass.
Original tables, hashes, transformations and notices are retained in
ThirdParty/Unicode. Derived scalar tables contain no borrowed codec code.

Important paths:

- Contract: Contract/LibraryContract.json
- Compatibility baseline: Contract/LibraryContract.baseline.json
- Implementation: Source
- Bindings: Bindings/Zig and Bindings/C
- Generated reference: Docs/API.md
- Tests: Tests

CONFIG_V1 receives the opaque caller-owned R4XStart context per call and uses
it to resolve R4SYS. R4STD retains neither that context nor any other supplied
pointer. Buffers and state objects remain caller-owned.

The Zig binding also owns the shared desktop file-handler helpers. These are
compiled into their consumers and do not add a premature R4STD runtime ABI:

- `app_assoc` parses and writes APPASSOC entries for application, subsystem,
  and deliberately removed handlers.
- `file_handler` combines application defaults with the installed subsystem
  resolver and emits the stable subsystem launch request.
- `subsystem_runtime` loads the subsystem view solely from installed
  `MODULES.JSON`, keeps bounded 256 KiB probe storage, and performs the final
  host-file check. Metadata inspection precedes resolution; only an unknown or
  ambiguous result completes the content window through range reads. Access
  counters expose info calls, read calls, and bytes without retaining source
  data across a launch. ASSOC.R4S stores only stable subsystem and format IDs,
  never a copied host path or display name.

The shipped default maps `.BAS` to subsystem `r4os.basic` and format
`basic.qbasic-source`. Open With still lists the ordinary Notepad application
alongside the resolved subsystem host.

Build and test from the owning Repositories/Libraries directory:

    Windows: Build.bat R4STD test
    Linux:   ./Build.sh R4STD test


Konfigurationsspeicherung ab 0.78.63
-----------------------------------
R4STD0.2.2 behandelt nur R4SYS-Read -3 als fehlende Datei. Null Bytes
bezeichnen einen vorhandenen leeren Bestand. Zu grosse Dateien ergeben
config_error_buffer_too_small (-3); sonstige Lesefehler werden als neuer
config_error_read_failed (-9) gemeldet. Die bestehenden Fehlernummern und
Tabellenlayouts bleiben gleich; der Library-Contract wurde ausschliesslich
um diese Fehlerkonstante erweitert und kontrolliert neu generiert.

Einzelwerte werden erst nach erfolgreicher TMP-/BAK-Wiederherstellung aus
dem tatsaechlichen Zielinhalt komponiert. Unveraenderte Schluessel bleiben
erhalten. Nicht lesbare oder ungeeignete Zieldaten und nicht lesbare
Sicherungen stoppen den Vorgang vor Loeschen oder Schreiben. Ein gueltiges
TMP hat bei fehlendem Ziel Vorrang; sonst kann eine lesbare BAK verwendet
werden. Fehlgeschlagenes Umbenennen einer brauchbaren Sicherung behaelt sie.
Scheitern Publikation und Rueckbenennung, liefert saveDocument
error_recovery_failed; TMP und BAK bleiben fuer die Wiederherstellung stehen.
Es gibt keine bedingungslose Aussage, dass ein Rueckbau abgeschlossen sei.
Der Zig-Pfadvergleich ruft den kanonischen SDK-Helfer equalsIgnoreCase auf.

Nachweis: bestehender R4STD-Build mit47 Hosttests einschliesslich zweier
gebuendelter Fehler-/Wiederherstellungsfaelle und instanziiertem Binding-
Pfadvergleich; fuenf gezielte Hostfaelle fuer die betroffenen Oberflaechen und
REG; ein SMP4-Gastlauf mit privaten TMP/BAK-Daten, erhaltenem Fremdschluessel,
geaendertem COUNT, unveraenderter4097-Byte-Datei nach Groessenfehler und
vorhandener leerer Datei. Kein neuer kanonischer Testlauf angelegt.
Transportpfade (0.85.42)
-----------------------
Bindings/Zig/path_text.zig ist ein reiner statischer Texthelfer, exportiert
als r4std_path_text. valid prueft kanonisches UTF8, NUL/ASCII-Steuerzeichen,
unzulassige Pfadzeichen,255UTF16-Einheiten je Komponente und die vom Caller
uebergebene Bytekapazitaet ohne NUL. Laufwerkspraefixe sind Syntax.
Leerzeichen, kombinierte Zeichen und alle zugelassenen Originalbytes bleiben
unveraendert; keine Normalisierung, Kollation oder OEM-Vermutung. Weitere
Dateisystem-/Transaktionsgrenzen bleiben beim jeweiligen Operationsbesitzer.
validText prueft komplette druckbare UTF8-Protokollzeilen; ein Transport muss
unvollstaendige Bytepraefixe bis zum Recordende behalten. Die dynamische
R4STD-Version und CODEC_V1 aendern sich dadurch nicht.
Gezielte Hostpruefung im Libraries-Root: zig build test-path-text.


Graphemgrenzen (statischer Zig-Textbaustein, Paket0.64.23):
Bindings/Zig/grapheme.zig implementiert die Default Extended Grapheme
Clusters nach Unicode17.0.0/UAX29Revision47 einschliesslich GB9c.
Byteoffsets, Skalare, Cluster und Displayzellen bleiben getrennt. Kein
Normalisieren, Shaping, Bidi oder Breitenversprechen. Iterator und Stream
sind allokationsfrei; der Caller behaelt Bytes bis zum naechsten Grenzereignis.
Ganze Eingaben werden vor begrenzten Praefixen streng validiert.
ThirdParty/Unicode17 enthaelt gepinnte Originaldaten, Lizenz und Hashes.
Tools/Generate-Grapheme.ps1 generiert die Tabellen deterministisch offline.
Runtime-R4L und bestehender Rustkern bleiben unveraendert.
