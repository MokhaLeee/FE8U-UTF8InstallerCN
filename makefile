MAKEFLAGS += --no-print-directory

MAIN    := main.event
FE8_CHX := fireemblem8re-skillsys20220703-cn.gba
FE8_GBA := fireemblem8re-skillsys20220703.gba

TOOL_DIR := Tools
LIB_DIR  := $(TOOL_DIR)/FE-CLib-Mokha
FE8_REF  := $(LIB_DIR)/reference/fireemblem8.ref.o
FE8_SYM  := $(LIB_DIR)/reference/fireemblem8.sym

TEXT_DIR     := Texts
FONT_DIR     := Fonts

HACK_DIRS    := $(TEXT_DIR) # $(FONT_DIR)

CACHE_DIR := .cache_dir
$(shell mkdir -p $(CACHE_DIR) > /dev/null)

CLEAN_FILES :=
CLEAN_DIRS  := $(CACHE_DIR) $(shell find -name __pycache__)
CLEAN_BUILD :=

ifeq ($(strip $(DEVKITPRO)),)
	$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>devkitpro)
endif

ifeq ($(strip $(DEVKITARM)),)
	$(error "Please set DEVKITARM in your environment. export DEVKITARM=<path to>devkitARM)
endif

TOOLCHAIN ?= $(DEVKITARM)
ifneq (,$(TOOLCHAIN))
	export PATH := $(TOOLCHAIN)/bin:$(PATH)
endif

ifeq ($(OS),Windows_NT)
	EXE := .exe
else
	EXE :=
endif

ifeq ($(shell python3 -c 'import sys; print(int(sys.version_info[0] > 2))'),1)
	PYTHON3 := python3
else
	PYTHON3 := python
endif

PREFIX  ?= arm-none-eabi-
CC      := $(PREFIX)gcc
AS      := $(PREFIX)as

EA_DIR            := $(TOOL_DIR)/EventAssembler
EA                := $(EA_DIR)/ColorzCore$(EXE)
PARSEFILE         := $(EA_DIR)/Tools/ParseFile$(EXE)
PORTRAITFORMATTER := $(EA_DIR)/Tools/PortraitFormatter$(EXE)
PNG2DMP           := $(EA_DIR)/Tools/Png2Dmp$(EXE)
COMPRESS          := $(EA_DIR)/Tools/compress$(EXE)
LYN               := $(EA_DIR)/Tools/lyn$(EXE) -longcalls
EA_DEP            := $(EA_DIR)/ea-dep$(EXE)

PORTRAIT_PROCESS  := $(PYTHON3) $(TOOL_DIR)/FE-PyTools/portrait-process.py
TEXT_PROCESS      := $(PYTHON3) $(TOOL_DIR)/FE-PyTools/text-process-classic.py
C2EA              := $(PYTHON3) $(TOOL_DIR)/FE-PyTools/NMM2CSV/c2ea.py
TMX2EA            := $(PYTHON3) $(TOOL_DIR)/FE-PyTools/TMX2EA/tmx2ea.py
GRIT              := $(DEVKITPRO)/tools/bin/grit$(EXE)

# ========
# = Main =
# ========

all:
	@$(MAKE) pre_build
	@$(MAKE) chax

pre_build: text font
chax: $(FE8_CHX)

$(FE8_CHX): $(MAIN) $(FE8_GBA) $(FE8_SYM) $(shell $(EA_DEP) $(MAIN) -I $(EA_DIR) --add-missings)
	@echo "[GEN]	$@"
	@cp -f $(FE8_GBA) $(FE8_CHX)
	@$(EA) A FE8 -input:$(MAIN) -output:$(FE8_CHX) --nocash-sym || rm -f $(FE8_CHX)
	@cat $(FE8_SYM) >> $(FE8_CHX:.gba=.sym)

CLEAN_FILES += $(FE8_CHX)  $(FE8_CHX:.gba=.sym)

# ============
# = Wizardry =
# ============

INC_DIRS := include $(LIB_DIR)/include
INC_FLAG := $(foreach dir, $(INC_DIRS), -I $(dir))

ARCH    := -mcpu=arm7tdmi -mthumb -mthumb-interwork
CFLAGS  := $(ARCH) $(INC_FLAG) -Wall -Wextra -Wno-unused-parameter -O2 -mtune=arm7tdmi -mlong-calls
ASFLAGS := $(ARCH) $(INC_FLAG)

CDEPFLAGS = -MMD -MT "$*.o" -MT "$*.asm" -MF "$(CACHE_DIR)/$(notdir $*).d" -MP
SDEPFLAGS = --MD "$(CACHE_DIR)/$(notdir $*).d"

LYN_REF := $(FE8_REF)

%.lyn.event: %.o $(LYN_REF)
	@echo "[LYN]	$@"
	@$(LYN) $< $(LYN_REF) > $@

%.o: %.s
	@echo "[AS ]	$@"
	@$(AS) $(ASFLAGS) $(SDEPFLAGS) -I $(dir $<) $< -o $@

%.o: %.c text
	@echo "[CC ]	$@"
	@$(CC) $(CFLAGS) $(CDEPFLAGS) -g -c $< -o $@

.PRECIOUS: %.o;

-include $(wildcard $(CACHE_DIR)/*.d)

CFILES := $(shell find $(HACK_DIRS) -type f -name '*.c')
CLEAN_FILES += $(CFILES:.c=.o) $(CFILES:.c=.asm) $(CFILES:.c=.dmp) $(CFILES:.c=.lyn.event)

SFILES := $(shell find $(HACK_DIRS) -type f -name '*.s')
CLEAN_FILES += $(SFILES:.s=.o) $(SFILES:.s=.dmp) $(SFILES:.s=.lyn.event)

# =========
# = Texts =
# =========

text:
	@$(MAKE) -C $(TEXT_DIR)

%.fetxt.dmp: %.fetxt
	@$(MAKE) -f $(TEXT_DIR)/makefile $@

CLEAN_BUILD += $(TEXT_DIR)

# =========
# = Glyph =
# =========

font:
	@$(MAKE) -C $(FONT_DIR)

%_font.img.bin: %_font.png
	@echo "[GEN]	$@"
	@$(GRIT) $< -gB2 -p! -tw16 -th16 -ftb -fh! -o $@

CLEAN_BUILD += $(FONT_DIR)

# ==============
# = MAKE CLEAN =
# ==============

clean:
	@for i in $(CLEAN_BUILD); do if test -e $$i/makefile ; then $(MAKE) -f $$i/makefile clean || { exit 1;} fi; done;
	rm -f $(CLEAN_FILES)
	rm -rf $(CLEAN_DIRS)
	@echo "All cleaned .."
