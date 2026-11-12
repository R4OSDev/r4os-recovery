R4IMG Runtime-R4L API
=====================

Unabhaengige Runtime-R4L fuer begrenztes PNG-, JPEG-, BMP- und SVG-Decoding sowie ARGB-Skalierung. Color metadata and full-precision RGBA16 PNG decoding are available through the independent PNG_V1 interface; API_V1 remains byte-compatible. JPEG/BMP characterization and embedded ICC extraction use RASTER_V1.

API_V1
------

Append-only V1-Tabelle fuer Bildprobe, Decoding, SVG-Rendering, Skalierung und Diagnose.

- ELF-Symbol: `r4img_api_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x315346a3a7ea4152:0x5233f7f0fb63b451`
- Tabellengroesse: 80 Byte

- Slot 0, Offset 32: `probe` - Erkennt Format und begrenzte intrinsische Dimensionen ohne Pixeldecoding.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4IMG_STATUS`; Besitz: Alle Pointer werden nur waehrend des Aufrufs verwendet..
- Slot 1, Offset 40: `scratch_bytes` - Berechnet die konservative Scratchobergrenze fuer einen Decodeaufruf.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4IMG_STATUS`; Besitz: Die Funktion allokiert und behaelt keinen Speicher..
- Slot 2, Offset 48: `decode` - Decodiert PNG, JPEG, BMP oder SVG in ARGB; SVG nutzt dabei Standardoptionen.
  Semantik: may_block, caller_serialized, not_reentrant; Fehlerdomaene `R4IMG_STATUS`; Besitz: Eingabe, Pixel und Scratch bleiben caller-owned; die Library behaelt keinen Pointer..
- Slot 3, Offset 56: `decode_svg_at` - Rendert SVG in frei waehlbare begrenzte Zieldimensionen und ruft optionale C-ABI-Callbacks auf.
  Semantik: may_block, caller_serialized, not_reentrant; Fehlerdomaene `R4IMG_STATUS`; Besitz: Alle Buffer und Callbackkontexte bleiben caller-owned und gelten nur fuer den Aufruf..
- Slot 4, Offset 64: `scale_composite` - Skaliert bilinear und komponiert Alpha gegen einen RGB-Hintergrund.
  Semantik: may_block, thread_safe, reentrant; Fehlerdomaene `R4IMG_STATUS`; Besitz: Quell- und Zielpuffer bleiben vollstaendig caller-owned..
- Slot 5, Offset 72: `decoder_diagnostic` - Liefert Scratch-Spitze und Allokationsfehler des letzten STB-Decodes.
  Semantik: nonblocking, caller_serialized, not_reentrant; Fehlerdomaene `R4IMG_STATUS`; Besitz: Die Ausgabe wird kopiert; es wird kein Pointer behalten..

PNG_V1
------

Bounded PNG color metadata, ICC extraction and RGBA16 source decoding.

- ELF-Symbol: `r4img_png_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x52434f4c4f525031:0x52494d47504e4731`
- Tabellengroesse: 64 Byte

- Slot 0, Offset 32: `png_color_info` - Validate PNG structure and color chunk CRC/order/values without decoding pixels. No hidden allocation. Reads at most max_color_encoded_bytes.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4IMG_STATUS`; Besitz: Only caller storage; no retained pointers. Encoded input, writable pixels, scratch and metadata/count outputs must be mutually separate. Decode/extraction failure leaves the result invalid and unpublished..
- Slot 1, Offset 40: `png_icc_profile` - Extract iCCP into bounded caller bytes; verifies zlib Adler32, exact ICC size and matching RGB/GRAY model. Capacity at least max_color_profile_bytes admits any supported profile. Full ICC validation belongs to the color engine.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4IMG_STATUS`; Besitz: Only caller storage; no retained pointers. Encoded input, writable pixels, scratch and metadata/count outputs must be mutually separate. Decode/extraction failure leaves the result invalid and unpublished..
- Slot 2, Offset 48: `png_scratch_bytes16` - Conservative scratch bound for PNG RGBA16 decode, within max_scratch_bytes.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4IMG_STATUS`; Besitz: Only caller storage; no retained pointers. Encoded input, writable pixels, scratch and metadata/count outputs must be mutually separate. Decode/extraction failure leaves the result invalid and unpublished..
- Slot 3, Offset 56: `png_decode16` - Decode PNG into full-precision RGBA uint16 channels in native little-endian order. Four channels per pixel; 8-bit input expands by257. No transfer, gamut or alpha conversion. Metadata/count outputs publish only on success. Serialized with all other raster decoder calls.
  Semantik: nonblocking, caller_serialized, not_reentrant; Fehlerdomaene `R4IMG_STATUS`; Besitz: Only caller storage; no retained pointers. Encoded input, writable pixels, scratch and metadata/count outputs must be mutually separate. Decode/extraction failure leaves the result invalid and unpublished..

RASTER_V1
---------

Independent JPEG/BMP color metadata and exact ICC extraction; PNG_V1 and API_V1 remain byte-compatible.

- ELF-Symbol: `r4img_raster_v1`
- ABI-Major: 1
- Revision: 1
- Interface-ID: `0x5234494d47434f31:0x5241535445523031`
- Tabellengroesse: 48 Byte

- Slot 0, Offset 32: `raster_color_info` - Read JPEG ICC/Exif or BMP V4/V5 color metadata; validate bounded complete ICC segments and matching source model before publishing.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4IMG_STATUS`; Besitz: Only caller storage; no retained pointers. Encoded input, writable pixels, scratch and metadata/count outputs must be mutually separate. Decode/extraction failure leaves the result invalid and unpublished..
- Slot 1, Offset 40: `raster_icc_profile` - Copy the complete original ICC profile in caller storage. JPEG chunks are reassembled by sequence number. Linked BMP profiles are explicitly unsupported; no hidden allocation or file access.
  Semantik: nonblocking, thread_safe, reentrant; Fehlerdomaene `R4IMG_STATUS`; Besitz: Only caller storage; no retained pointers. Encoded input, writable pixels, scratch and metadata/count outputs must be mutually separate. Decode/extraction failure leaves the result invalid and unpublished..

Typen
-----

- `R4ImgInfo`: 16 Byte, Alignment 4. Festes Bildmetadatenlayout der V1-ABI.
- `R4ImgSvgOptions`: 56 Byte, Alignment 8. Festes Optionslayout; Callbacks und Kontexte gelten nur waehrend decode_svg_at.
- `R4ImgDecoderDiagnostic`: 16 Byte, Alignment 8. Festes Diagnoseergebnis der V1-ABI.
- `R4ImgPngColor`: 128 Byte, Alignment 4. Version1/size128. PNG Third Edition color metadata. Kind uses highest understood priority cICP > ICC > sRGB > gAMA/cHRM; unspecified/unknown are explicit, never implicit sRGB. Presence flags independently retain all chunks. cICP uses H.273 numbers; gamma/chromaticities use1/100000; mastering xy uses1/50000 and all luminance values use1/10000 cd/m2. Zero luminance in cLLI means unknown. PNG samples/alpha are straight, no display conversion is performed. iCCP remains encoded in the input until png_icc_profile extracts it. Unknown transfer/primaries must be handled by caller policy.
- `R4ImgRasterColor`: 88 Byte, Alignment 4. Version1/size88. JPEG ICC/Exif or BMP V4/V5 source characterization. RGB=1, GRAY=2, CMYK=3; old API_V1 always decodes JPEG/BMP into ARGB8. Endpoints retain signed2.30 XYZ triplets, gamma retains unsigned16.16 decoding exponents; these are interpreted only for calibrated BMP. Intent uses ICC numbering0..3. Profile length is the exact reassembled size, limited to4MB; profile copying never opens external files. Unknown/linked/CMYK source colors require explicit caller handling, never an implicit sRGB assumption. Reserved fields and flags are zero.

Besitzregeln
------------

- Caller-owned Buffer: Codierte Daten, Pixelpuffer und Scratchspeicher bleiben beim Caller; R4IMG verwendet sie nur waehrend des Aufrufs und allokiert nie ueber die ABI.
- Callback-Lebensdauer: SVG-Callbackadressen und ihre Kontexte muessen nur bis zur Rueckkehr von decode_svg_at gueltig bleiben und werden nicht gespeichert.
- Providergeneration: Die API-Tabelle und ihre Funktionspointer bleiben bis zum Ende der geladenen R4IMG-Providergeneration gueltig.
- Serialisierung: Rasterdecode und Decoderdiagnose muessen vom Caller serialisiert werden, weil der eingebettete STB-Adapter eine providerlokale Scratchdiagnose fuehrt.
