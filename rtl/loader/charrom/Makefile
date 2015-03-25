BASE	= 
CC      = $(BASE)gcc
LD      = $(BASE)gcc
AS      = $(BASE)as
CP      = $(BASE)objcopy
DUMP    = $(BASE)objdump

ROMGEN = charromgen

MAIN_PRJ = loader_charrom
MAIN_SRC = loader_charrom.s
MAIN_OBJ = $(patsubst %.s,%.bin,$(MAIN_SRC))


all: $(MAIN_PRJ).bin $(MAIN_PRJ)_rom.vhd

clean:
	rm -f *.bin $(MAIN_PRJ)_rom.vhd $(ROMGEN) $(MAIN_PRJ).o


# Convert ELF binary to bin file.
%.bin: %.o
	$(CP) -O binary $< $@

%.o: %.s Makefile
	$(CC) -c -o $@ $<

$(ROMGEN): $(ROMGEN).c
	gcc -o $@ $<
#	gcc -o $(ROMGENDIR)/$(ROMGEN) $(ROMGENDIR)/romgen.c

%_rom.vhd: %.bin $(ROMGEN)
	sed 's/soc_firmware/$*_rom/' >../$*_rom.vhd <bitrom_prologue.vhd
	./$(ROMGEN) $*.bin >>../$*_rom.vhd
	cat >>../$*_rom.vhd bitrom_epilogue.vhd

