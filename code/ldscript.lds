SECTIONS
{
  . = 0x80000000;
  .text : {
    KEEP(*(.bootloader)) 
    *(.text*)
  }

  . = ALIGN(0x1000);

  .data : {
    *(.data*)
  }

  . = ALIGN(0x1000);

  .rodata : {
    *(.rodata*)
  }

  . = ALIGN(0x1000);

  .bss : {
    *(.bss*)
  }

  . = ALIGN(0x10);
}
