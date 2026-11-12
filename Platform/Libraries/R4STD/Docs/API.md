R4STD Runtime-R4L API
=====================

Unabhaengige Runtime-R4L fuer Text, R4S-Settings, Datum, Zeitzonen und atomare Konfigurationsdateien.

TEXT_V1
-------

Versionierte Text- und Kodierungsoberflaeche.

- ELF-Symbol: `r4std_text_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x4f8b90dbd3e7d113:0x20e30ebdcef27d92`
- Tabellengroesse: 48 Byte

- Slot 0, Offset 32: `inspect` - Prueft UTF-8-, UI-, System- oder Dokumenttext und beschreibt den Inhalt.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 1, Offset 40: `write` - Schreibt Systemtext kanonisch oder Dokumenttext bytegenau.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..

SETTINGS_V1
-----------

Versionierter R4S-Parser, Writer und Writeback-Zustand.

- ELF-Symbol: `r4std_settings_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0xad6417547bbd0509:0xa72d3a94f53635bc`
- Tabellengroesse: 128 Byte

- Slot 0, Offset 32: `entry_next` - Liefert das naechste gueltige R4S-Schluessel-Wert-Paar.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 1, Offset 40: `value` - Sucht case-insensitiv den letzten Wert eines Schluessels.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 2, Offset 48: `parse_scalar` - Parst Boolean, u32, i32 oder RGB24.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 3, Offset 56: `writer_append` - Fuegt Header, Kommentar oder typisiertes Schluessel-Wert-Paar an.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 4, Offset 64: `equals_key` - Vergleicht R4S-Schluessel ASCII-case-insensitiv.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `none`; Besitz: Keine Pointer werden behalten..
- Slot 5, Offset 72: `writeback_policy` - Berechnet eine Writeback-Policy fuer die Host-Tickfrequenz.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 6, Offset 80: `writeback_default_delay` - Liefert die Standardverzoegerung in Millisekunden.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `none`; Besitz: Keine Pointer..
- Slot 7, Offset 88: `writeback_init` - Initialisiert caller-eigenen Writeback-Zustand.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 8, Offset 96: `writeback_configure` - Konfiguriert einen bestehenden Writeback-Zustand.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 9, Offset 104: `writeback_mark_dirty` - Markiert den Zustand als geaendert.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 10, Offset 112: `writeback_prepare` - Entscheidet, ob der Caller seinen Saver aufrufen muss.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 11, Offset 120: `writeback_complete` - Uebernimmt das Ergebnis eines Writeback-Versuchs.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..

DATE_V1
-------

Versionierte Kalender-, Format- und FAT-Konvertierung.

- ELF-Symbol: `r4std_date_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0xbb8b0547d242bbc4:0x114c12ba386e91b3`
- Tabellengroesse: 128 Byte

- Slot 0, Offset 32: `days_in_month` - Liefert die Tageszahl eines Monats.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `none`; Besitz: Keine Pointer..
- Slot 1, Offset 40: `valid_date` - Prueft ein Kalenderdatum.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `none`; Besitz: Keine Pointer..
- Slot 2, Offset 48: `compare_date_time` - Vergleicht zwei lokale Datumswerte.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `none`; Besitz: Pointer gelten nur waehrend des Aufrufs..
- Slot 3, Offset 56: `weekday_number` - Liefert den Wochentag Sonntag=0 bis Samstag=6.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `none`; Besitz: Keine Pointer..
- Slot 4, Offset 64: `shift_minutes` - Verschiebt einen Zeitpunkt um Minuten.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 5, Offset 72: `from_time_state` - Konvertiert den uebersetzten Plattformzeitwert.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 6, Offset 80: `to_time_state` - Erzeugt einen lokalen Zeitstatus.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 7, Offset 88: `utc_from_date_time` - Konvertiert ein UTC-Datum in Unix-Sekunden.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 8, Offset 96: `date_time_from_utc` - Konvertiert Unix-Sekunden in ein UTC-Datum.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 9, Offset 104: `format` - Formatiert Datum oder Datum/Uhrzeit.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 10, Offset 112: `parse` - Parst ISO-Datum, Uhrzeit oder Datum/Uhrzeit.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 11, Offset 120: `decode_fat` - Dekodiert FAT-Datum oder FAT-Datum/Uhrzeit.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..

TIME_V1
-------

Versionierte Zeitzonen- und Zeitkonfigurationsoberflaeche.

- ELF-Symbol: `r4std_time_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x288ef4aa6232d1c7:0x968f346a4240a924`
- Tabellengroesse: 152 Byte

- Slot 0, Offset 32: `zone_count` - Liefert die Zahl der Zeitzonen.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `none`; Besitz: Keine Pointer..
- Slot 1, Offset 40: `copy_zone_id` - Kopiert die stabile Zeitzonen-ID.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 2, Offset 48: `copy_zone_label` - Kopiert die zustandsabhaengige Zeitzonenbezeichnung.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 3, Offset 56: `index_for_id` - Sucht eine Zeitzonen-ID.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 4, Offset 64: `offset_at_state` - Liefert den UTC-Offset in Minuten.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `none`; Besitz: Der Pointer wird nur gelesen..
- Slot 5, Offset 72: `seconds_in_zone` - Verschiebt Tagessekunden in eine Zeitzone.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `none`; Besitz: Keine Pointer..
- Slot 6, Offset 80: `split_time` - Zerlegt Tagessekunden.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 7, Offset 88: `local_date_time` - Berechnet lokales Datum und Uhrzeit.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 8, Offset 96: `format_clock` - Formatiert eine Uhrzeit.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 9, Offset 104: `format_offset` - Formatiert einen UTC-Offset.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 10, Offset 112: `config_load` - Laedt Zeitzone und Uhrformat.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `none`; Besitz: Keine Pointer werden behalten..
- Slot 11, Offset 120: `config_write` - Schreibt die Zeitkonfiguration als R4S.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 12, Offset 128: `config_normalize` - Normalisiert Index und Uhrformat.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: Alle Pointer sind nur fuer die Aufrufdauer geliehen..
- Slot 13, Offset 136: `config_offset` - Liefert den konfigurierten UTC-Offset.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `none`; Besitz: Pointer werden nur gelesen..
- Slot 14, Offset 144: `standard_offset` - Liefert den Standardoffset der Zeitzone ohne Sommerzeit.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `none`; Besitz: Keine Pointer oder Besitzuebergaenge..

CONFIG_V1
---------

Versionierte, caller-identitaetstreue R4SYS-Dateioberflaeche.

- ELF-Symbol: `r4std_config_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0xfca1d800ccd28cbc:0x8fd66db6fcbe1c43`
- Tabellengroesse: 80 Byte

- Slot 0, Offset 32: `read` - Liest einen typisierten R4S-Wert ueber den Caller-eigenen R4SYS-Kontext.
  Semantik: may_block, caller_serialized, not_reentrant; Fehlerdomaene `R4STD_CONFIG_RESULT`; Besitz: Der Startkontext und alle Buffer bleiben caller-owned und werden nicht gespeichert..
- Slot 1, Offset 40: `write` - Schreibt einen typisierten R4S-Wert atomar.
  Semantik: may_block, caller_serialized, not_reentrant; Fehlerdomaene `R4STD_CONFIG_RESULT`; Besitz: Keine Adresse wird ueber den Aufruf hinaus behalten; Dateiseiteneffekte folgen dem Ergebnisvertrag..
- Slot 2, Offset 48: `save_document` - Speichert ein vollstaendiges R4S-Dokument atomar.
  Semantik: may_block, caller_serialized, not_reentrant; Fehlerdomaene `R4STD_CONFIG_RESULT`; Besitz: Der Provider darf TMP- und BAK-Dateien erzeugen und bereinigt sie nach dem Vertrag..
- Slot 3, Offset 56: `recover_document` - Stellt einen unterbrochenen atomaren Save wieder her.
  Semantik: may_block, caller_serialized, not_reentrant; Fehlerdomaene `R4STD_CONFIG_RESULT`; Besitz: Kann vorhandene TMP- oder BAK-Dateien umbenennen oder entfernen..
- Slot 4, Offset 64: `has_leftovers` - Prueft auf TMP- oder BAK-Reste.
  Semantik: may_block, caller_serialized, not_reentrant; Fehlerdomaene `none`; Besitz: Nur lesende Dateisystemzugriffe..
- Slot 5, Offset 72: `ensure_dirs` - Legt die standardisierten Konfigurationsverzeichnisse an.
  Semantik: may_block, caller_serialized, not_reentrant; Fehlerdomaene `R4STD_CONFIG_RESULT`; Besitz: Bereits vorhandene Verzeichnisse bleiben unveraendert..

CODEC_V1
--------

Independent strict scalar/legacy codecs, separate from bytes/SystemText/DocumentText and typed keyboard events. Byte/scalar/grapheme lengths are distinct. No automatic encoding guess, normalization or replacement.

- ELF-Symbol: `r4std_codec_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x4543544558543031:0x5244535444434f44`
- Tabellengroesse: 80 Byte

- Slot 0, Offset 32: `legacy_decode` - Strict official CP437/Windows1252 byte to scalar. Byte<=255. Explicit CP437 PC-graphics mode uses separate Unicode IBMGRAPH C0/DEL mapping; undefined byte returns -107. No replacement, no CP850 alias.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: All buffers/state are caller-owned and borrowed only during this call; no allocation or retained pointer. Disjoint outputs. Failure preserves output/state; incomplete push accepts the one byte and retains only a valid prefix..
- Slot 1, Offset 40: `legacy_encode` - Strict inverse. Invalid scalar -105; not representable -106; unsupported codepage/mode -100. Failure preserves output.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: All buffers/state are caller-owned and borrowed only during this call; no allocation or retained pointer. Disjoint outputs. Failure preserves output/state; incomplete push accepts the one byte and retains only a valid prefix..
- Slot 2, Offset 48: `utf8_decode` - Read at most first four available bytes. Strict shortest scalar UTF8, including U+0000. Complete0, valid incomplete4 (length0/required1..4), invalid -102 with unchanged result. No normalization/replacement.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: All buffers/state are caller-owned and borrowed only during this call; no allocation or retained pointer. Disjoint outputs. Failure preserves output/state; incomplete push accepts the one byte and retains only a valid prefix..
- Slot 3, Offset 56: `utf8_encode` - Encode one valid scalar to1..4 shortest UTF8 bytes. Capacity preflight; invalid/capacity failure preserves entire output/written. NUL allowed in this scalar codec only; old TextV1 no-NUL policy unchanged.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: All buffers/state are caller-owned and borrowed only during this call; no allocation or retained pointer. Disjoint outputs. Failure preserves output/state; incomplete push accepts the one byte and retains only a valid prefix..
- Slot 4, Offset 64: `utf8_push` - Accept one byte transactionally into caller state. At most4 examined bytes and at most3 pending bytes after return. Valid incomplete4 retains prefix, complete0 clears state; invalid byte/prefix/state preserves state/output. Caller explicitly resets/discards on error and can retry offending byte. No lost following ASCII.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: All buffers/state are caller-owned and borrowed only during this call; no allocation or retained pointer. Disjoint outputs. Failure preserves output/state; incomplete push accepts the one byte and retains only a valid prefix..
- Slot 5, Offset 72: `utf8_finish` - Validate final state without mutation: empty0, valid unfinished prefix4, invalid state -100. Reset by zero-initializing all16 bytes. No implicit replacement or silent truncation.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4STD_STATUS`; Besitz: All buffers/state are caller-owned and borrowed only during this call; no allocation or retained pointer. Disjoint outputs. Failure preserves output/state; incomplete push accepts the one byte and retains only a valid prefix..

Typen
-----

- `R4StdTextInfo`: 40 Byte, Alignment 8. Festes Ergebnis einer Textinspektion.
- `R4StdEntryRange`: 32 Byte, Alignment 8. Bereiche eines R4S-Eintrags relativ zum Dokumentanfang.
- `R4StdWritebackPolicy`: 24 Byte, Alignment 8. Caller-owned Writeback-Policy.
- `R4StdWriteback`: 48 Byte, Alignment 8. Vollstaendig caller-owned Writeback-Zustand.
- `R4StdWritebackFlush`: 16 Byte, Alignment 4. Ergebnis einer Writeback-Entscheidung.
- `R4StdDateTime`: 8 Byte, Alignment 2. Lokales Datum und Uhrzeit ohne Plattform-ABI-Abhaengigkeit.
- `R4StdShiftedDateTime`: 12 Byte, Alignment 4. Verschobener Zeitpunkt mit Tagesdelta.
- `R4StdTimeState`: 16 Byte, Alignment 4. Library-lokale Uebersetzung eines zentralen Zeitstatus.
- `R4StdUtcTime`: 16 Byte, Alignment 8. Library-lokaler UTC-Epochenwert.
- `R4StdClockTime`: 4 Byte, Alignment 1. Uhrzeit innerhalb eines Tages.
- `R4StdTimeConfig`: 8 Byte, Alignment 4. Unabhaengige Zeitkonfiguration.
- `R4StdScalarResult`: 16 Byte, Alignment 4. Complete scalar with total encoded byte_length1..4. Incomplete scalar0/byte_length0/required1..4; reserved0. Byte counts are not grapheme counts.
- `R4StdUtf8State`: 16 Byte, Alignment 4. Caller-owned zero-initialized16-byte state. Pending bytes in low8*length bits in arrival order; length0..3, all unused bits/reserved words zero. Valid UTF8 prefixes only. No pointers, global state, allocation or stream intermixing.

Besitzregeln
------------

- Caller-Speicher: Alle Buffer, Strukturen und der R4X-Startkontext bleiben caller-owned; R4STD behaelt keine Adresse ueber einen Aufruf hinaus.
- Runtime-Tabellen: Tabellen- und Funktionspointer gelten bis zum Ende der geladenen R4STD-Providergeneration.
- Plattformgrenze: CONFIG_V1 erhaelt den zentralen R4X-Startkontext nur als opake Adresse und loest R4SYS pro Aufruf; R4STD definiert keine Kopie der zentralen Plattform-ABI.
- Dateiseiteneffekte: Konfigurationswrites duerfen sibling TMP- und BAK-Dateien verwenden; positive Ergebniswerte beschreiben Erzeugung oder Recovery, negative Werte die Fehlerklasse.
