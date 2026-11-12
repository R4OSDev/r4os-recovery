/* Generated from pinned Mesa 26.2.2; original functions/types retained.
 * Copyright 2009 Younes Manton; 2017-2025 Advanced Micro Devices, Inc.
 * MIT; full original notices/grants in ThirdParty/Mesa26.2.2/Original.
 * Regenerate: Tools/VcnEncode.ps1 -Write. */
unsigned int radeon_enc_h2645_picture_type(enum pipe_h2645_enc_picture_type type)
{
   switch (type) {
   case PIPE_H2645_ENC_PICTURE_TYPE_I:
   case PIPE_H2645_ENC_PICTURE_TYPE_IDR:
      return RENCODE_PICTURE_TYPE_I;
   case PIPE_H2645_ENC_PICTURE_TYPE_P:
      return RENCODE_PICTURE_TYPE_P;
   case PIPE_H2645_ENC_PICTURE_TYPE_SKIP:
      return RENCODE_PICTURE_TYPE_P_SKIP;
   case PIPE_H2645_ENC_PICTURE_TYPE_B:
      return RENCODE_PICTURE_TYPE_B;
   default:
      assert(false);
      return 0;
   }
}

void radeon_enc_dummy(struct radeon_encoder *enc) {}
