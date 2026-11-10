# build the ROMs documentation, assemble and compare the binaries

ROMS = zx81_edition1 zx81_edition2 zx81_edition3 tk85 sg81 ts1500

all: 
	perl tools/format_all.pl $(wildcard src/*.asm)
	perl tools/make_all.pl $(MAKE) make_proj $(ROMS)

clean: 
	perl tools/make_all.pl $(MAKE) clean_proj $(ROMS)
	$(RM) -r build

make_proj: build/$(PROJ).bin $(PROJ).html

build/$(PROJ).bin: build/$(PROJ).asm Makefile build
	z88dk-z80asm -b -l -m build/$(PROJ).asm
	z88dk-dis -x build/$(PROJ).map build/$(PROJ).bin > build/$(PROJ).asm.dump
	z88dk-dis -x build/$(PROJ).map       $(PROJ).rom > build/$(PROJ).rom.dump
	dos2unix build/$(PROJ).asm.dump build/$(PROJ).rom.dump
	diff build/$(PROJ).rom.dump build/$(PROJ).asm.dump

build/$(PROJ).asm: $(wildcard src/*.asm) \
					tools/format_asm.pl tools/format_all.pl Makefile build
	perl -S filepp -DROM_$(PROJ) src/zx81_roms.asm -o build/$(PROJ).asm

clean_proj:
	$(RM) $(wildcard *.bak src/*.bak tools/*.bak)

$(PROJ).html: build/$(PROJ).asm \
					tools/format_asm.pl tools/build_asm_html.pl Makefile
	perl tools/format_asm.pl     build/$(PROJ).asm
	perl tools/build_asm_html.pl build/$(PROJ).asm
	cp build/$(PROJ).html $(PROJ).html
	cp build/$(PROJ).asm  $(PROJ).asm

build:
	mkdir $@
