BASE	= zpu-elf
CC      = $(BASE)-gcc
LD      = $(BASE)-gcc
AS      = $(BASE)-as
CP      = $(BASE)-objcopy
DUMP    = $(BASE)-objdump

ZPUFLEXDIR = ../zpuflex
ROMGEN = $(ZPUFLEXDIR)/firmware/zpuromgen

# we use mincrt0.s from here
STARTUP_DIR = $(ZPUFLEXDIR)/firmware/startup

# we fetch ROM prologue / epilogue from here
RTL_DIR = $(ZPUFLEXDIR)/rtl/

# we use printf from here
COMMON_DIR = inc

BUILD_DIR=zpu_obj

MINSTARTUP_SRC = $(STARTUP_DIR)/mincrt0.s $(STARTUP_DIR)/premain.s
MINSTARTUP_OBJ = $(patsubst $(STARTUP_DIR)/%.s,$(BUILD_DIR)/%.o,$(MINSTARTUP_SRC))

COMMON_SRC = 
COMMON_OBJ = $(patsubst $(COMMON_DIR)/%.c,$(BUILD_DIR)/%.o,$(COMMON_SRC))

HW_SRC = osd.c
HW_OBJ = $(COMMON_OBJ) $(patsubst %.c,$(BUILD_DIR)/%.hwo,$(HW_SRC))

MAIN_PRJ = loader_firmware
MAIN_SRC = boot.c minfat.c spi.c uart.c swap.c small_printf.c ps2.c keyboard.c interrupts.c hexdump.c menu.c
MAIN_OBJ = $(COMMON_OBJ) $(HW_OBJ) $(patsubst %.c,$(BUILD_DIR)/%.o,$(MAIN_SRC))

LINKMAP  = $(ZPUFLEXDIR)/firmware/standalone_simple.ld


# Commandline options for each tool.

HWZPUOPTS= -mno-poppcrel -mno-pushspadd -mno-callpcrel -mno-neg -mno-div -mno-mod # No-neg requires bugfixed toolchain
#HWCFLAGS  = -I. -I$(COMMON_DIR)/ -g -c -Os $(HWZPUOPTS) -ffunction-sections -fdata-sections -DDISABLE_UART_RX -DPRINTF_HEX_ONLY # -DDISABLE_PRINTF -DDISABLE_UART_TX
HWCFLAGS  = -I. -I$(COMMON_DIR)/ -g -c -Os $(HWZPUOPTS) -ffunction-sections -fdata-sections -DDISABLE_UART_RX -DPRINTF_HEX_ONLY -DDISABLE_PRINTF #-DDISABLE_UART_TX

ZPUOPTS= -mno-poppcrel -mno-pushspadd -mno-callpcrel -mno-shortop -mno-byteop -mno-neg -mno-div -mno-mod # No-neg requires bugfixed toolchain
#CFLAGS  = -I. -I$(COMMON_DIR)/ -g -c -Os $(ZPUOPTS) -ffunction-sections -fdata-sections -DDISABLE_UART_RX -DPRINTF_HEX_ONLY # -DDISABLE_PRINTF -DDISABLE_UART_TX
CFLAGS  = -I. -I$(COMMON_DIR)/ -g -c -Os $(ZPUOPTS) -ffunction-sections -fdata-sections -DDISABLE_UART_RX -DPRINTF_HEX_ONLY -DDISABLE_PRINTF #-DDISABLE_UART_TX

LFLAGS  = -nostartfiles -nostdlib -Wl,--relax -Wl,--gc-sections -Os -g

LIBS = -lgcc


# Our target.
all: $(BUILD_DIR) $(MAIN_PRJ).bin $(MAIN_PRJ)_ROM.vhd $(MAIN_PRJ).rpt

clean:
	rm -f $(BUILD_DIR)/*.o *.hex *.elf *.map *.lst *.srec $(MAIN_PRJ).rom *~ */*.o *.bin


# Convert ELF binary to bin file.
%.bin: %.elf
	$(CP) -O binary $< $@

%.rpt: %.elf
	echo >$@ -n "End of code:\t"
	$(DUMP) -x $< | grep >>$@ _romend
	echo >>$@ -n "Start of BSS:\t"
	$(DUMP) -x $< | grep  >>$@ __bss_start__
	echo >>$@ -n "End of BSS:\t"
	$(DUMP) -x $< | grep >>$@ __bss_end__
	cat $@

$(ROMGEN): $(ZPUFLEXDIR)/firmware/zpuromgen.c
	gcc -o $(ZPUFLEXDIR)/firmware/zpuromgen $(ZPUFLEXDIR)/firmware/zpuromgen.c

%_ROM.vhd: %.bin $(ROMGEN)
	sed 's/dualportram/$*_rom/' >../$*_rom.vhd <$(RTL_DIR)/rom_prologue.vhd
	$(ROMGEN) $*.bin >>../$*_rom.vhd
	cat >>../$*_rom.vhd $(RTL_DIR)/rom_epilogue.vhd

# Link - this produces an ELF binary.

$(MAIN_PRJ).elf: $(MINSTARTUP_OBJ) $(MAIN_OBJ)
	$(LD) $(LFLAGS) -T $(LINKMAP) -o $@ $+ $(LIBS)

$(BUILD_DIR)/%.o: %.c Makefile
	$(CC) $(CFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.hwo: %.c Makefile
	$(CC) $(HWCFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.o: $(COMMON_DIR)/%.c Makefile
	$(CC) $(CFLAGS)  -o $@ -c $<

$(BUILD_DIR)/%.o: %.s
	$(AS) -o $@ $<

$(BUILD_DIR)/%.o: $(STARTUP_DIR)/%.s
	$(AS) -o $@ $<

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

