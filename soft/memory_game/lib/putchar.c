int putchar(int c)
{
tgt_putchar(c);
return 0;
}

void tgt_putchar(c)
{
    asm(
        ".set noreorder\n\t"
        "jr $31\n\t"
        "sb %0,-0x10($0)\n\t"
        ".set reorder\n\t"
        :
        :"r"(c) );
}
