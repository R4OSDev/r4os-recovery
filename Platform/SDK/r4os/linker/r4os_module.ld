SECTIONS
{
    . = 0;

    .text : ALIGN(4096) {
        KEEP(*(.text.r4xstart_entry))
        KEEP(*(.text.r4x_entry))
        KEEP(*(.text.r4d_entries))
        KEEP(*(.text.r4l_entry))
        KEEP(*(.text.r4l_exports*))
        KEEP(*(.text.r4p_entries))
        /* Clang's large code model uses SHF_X86_64_LARGE .l* inputs. */
        *(.ltext*)
        *(.text*)
    }

    .rodata : ALIGN(4096) {
        *(.lrodata*)
        *(.rodata*)
    }

    .data : ALIGN(4096) {
        KEEP(*(.data.r4l_exports*))
        *(.ldata*)
        *(.data*)
    }

    .bss : ALIGN(4096) {
        *(.lbss*)
        *(.bss*)
        *(COMMON)
    }

    /DISCARD/ : {
        *(.comment*)
        *(.eh_frame*)
        *(.note*)
    }
}
