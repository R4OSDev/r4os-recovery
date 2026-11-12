R4FONT Runtime-R4L API
======================

Unabhaengige Runtime-R4L fuer TTF-, OTF/CFF-, WOFF-, WOFF2- und TTC-Fonts mit Metriken, Kerning und Alpha8-Rasterung.

API_V1
------

Versionierte R4FONT-V1-Funktionstabelle.

- ELF-Symbol: `r4font_api_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0xc0549d6a89118bf3:0x767de92df622018`
- Tabellengroesse: 120 Byte

- Slot 0, Offset 32: `sniff` - Erkennt das Fontcontainerformat anhand seiner Signatur.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4FONT_STATUS`; Besitz: Die Eingabe wird nur waehrend des Aufrufs gelesen..
- Slot 1, Offset 40: `decoder_create` - Erzeugt einen voneinander unabhaengigen Decoder.
  Semantik: may_block, thread_safe, reentrant; Fehlerdomaene `R4FONT_STATUS`; Besitz: Der Provider speichert eine Kopie der Allocatorbeschreibung bis decoder_destroy..
- Slot 2, Offset 48: `decoder_destroy` - Zerstoert Decoder und providerseitigen Zustand.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4FONT_STATUS`; Besitz: Nach Rueckkehr ist das Decoderhandle ungueltig; alle Faces muessen zuvor geschlossen sein..
- Slot 3, Offset 56: `decoder_diagnostics` - Liest die Speicherdiagnose eines Decoders.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4FONT_STATUS`; Besitz: Die Diagnose wird kopiert und behaelt keine Pointer..
- Slot 4, Offset 64: `decoder_open_face` - Oeffnet ein Face aus caller-eigenen Fontdaten.
  Semantik: may_block, handle_serialized, not_reentrant; Fehlerdomaene `R4FONT_STATUS`; Besitz: Die Fontdaten bleiben caller-owned und werden bis face_close nur geborgt..
- Slot 5, Offset 72: `face_close` - Schliesst ein Face.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4FONT_STATUS`; Besitz: Nach Rueckkehr ist das Facehandle ungueltig..
- Slot 6, Offset 80: `face_info` - Liest feste Face-Metadaten und geborgte Namen.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4FONT_STATUS`; Besitz: Familien- und Stiladressen bleiben provider-owned und gelten bis face_close..
- Slot 7, Offset 88: `glyph_index` - Loest einen Codepoint auf einen Glyphenindex auf.
  Semantik: nonblocking, handle_serialized, not_reentrant; Fehlerdomaene `R4FONT_STATUS`; Besitz: Die Ausgabe wird kopiert..
- Slot 8, Offset 96: `glyph_metrics` - Liest unskalierte Glyphenmetriken.
  Semantik: may_block, handle_serialized, not_reentrant; Fehlerdomaene `R4FONT_STATUS`; Besitz: Die Ausgabe wird kopiert..
- Slot 9, Offset 104: `kerning` - Liest das Kerning eines Glyphenpaares.
  Semantik: may_block, handle_serialized, not_reentrant; Fehlerdomaene `R4FONT_STATUS`; Besitz: Die Ausgabe wird kopiert..
- Slot 10, Offset 112: `rasterize` - Rastert eine Glyphe als Alpha8.
  Semantik: may_block, handle_serialized, not_reentrant; Fehlerdomaene `R4FONT_STATUS`; Besitz: Pixelpuffer und Metadatenausgabe bleiben caller-owned..

Typen
-----

- `R4FontAllocator`: 32 Byte, Alignment 8. Feste V1-Allocatorbeschreibung.
- `R4FontDiagnostics`: 56 Byte, Alignment 8. Feste Decoderdiagnose der V1-ABI.
- `R4FontFaceInfo`: 56 Byte, Alignment 8. Feste Face-Metadaten der V1-ABI.
- `R4FontGlyphMetrics`: 28 Byte, Alignment 4. Feste unskalierte Glyphenmetriken der V1-ABI.
- `R4FontKerning`: 8 Byte, Alignment 4. Feste Kerningausgabe der V1-ABI.
- `R4FontRaster`: 32 Byte, Alignment 8. Feste Rastermetadaten der V1-ABI.

Besitzregeln
------------

- Decoderhandle: Ein Decoderhandle gehoert dem Caller, wird mit decoder_destroy geschlossen und darf erst nach allen zugehoerigen Faces zerstoert werden.
- Facehandle: Ein Facehandle gehoert dem Caller und wird mit face_close geschlossen; es ist an Decoder und Providergeneration gebunden.
- Fontdaten: decoder_open_face kopiert Fontdaten nicht. Der Caller haelt sie bis face_close unveraendert und lesbar.
- Allocator: Die Library kopiert Callbackadressen und Userkontext. Sie bleiben bis decoder_destroy gueltig; Allokationen werden ueber denselben Allocator freigegeben.
- Namen: Familien- und Stilnamen bleiben provider-owned, nullterminiert und nur bis face_close gueltig.
- Providergeneration: API-Tabelle, Funktionspointer und alle Handles gelten nur fuer die geladene R4FONT-Providergeneration.
