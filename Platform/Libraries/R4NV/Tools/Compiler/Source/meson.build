# Copyright 2026 R4
# SPDX-License-Identifier: Apache-2.0
executable(
  'r4nak',
  ['r4nak.c', 'shaders.c'],
  include_directories : [inc_include, inc_src],
  dependencies : [idep_nak, idep_nir, idep_compiler, idep_mesautil,
                  idep_nvidia_headers.partial_dependency(includes : true)],
  install : false,
)
