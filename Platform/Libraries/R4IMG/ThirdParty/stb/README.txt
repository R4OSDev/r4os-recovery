stb_image
=========

R4IMG uses stb_image 2.30 from the official nothings/stb project for PNG,
JPEG, and BMP decoding. R4OS selects the MIT option from the upstream
MIT/public-domain dual offer.

Source: https://github.com/nothings/stb/blob/master/stb_image.h
License: LICENSE-MIT and the license block at the end of stb_image.h
Retrieved for R4OS: 2026-08-05

r4img_stb.c restricts the format set and replaces dynamic C allocation with a
scratch arena supplied by the R4OS caller.
