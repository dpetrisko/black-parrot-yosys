## Set common environment variables
TOP ?= $(shell git rev-parse --show-toplevel)
SHELL=/bin/bash

CP ?= cp
SED ?= sed
YOSYS ?= yosys
CAT ?= cat
ENVSUBST ?= envsubst

# Setup cadenv
ifeq (,$(wildcard $(TOP)/bsg_cadenv/cadenv.mk))
$(info ************************************************************************************)
$(info * bsg_cadenv does not exist:)
$(info *   please ask for access to https://github.com/bespoke-silicon-group/bsg_cadenv)
$(info *   or switch to SIM=verilator)
$(info ************************************************************************************)
$(error )
else
include $(TOP)/bsg_cadenv/cadenv.mk
endif

export SYNLIG_DIR       := $(TOP)/synlig
export BLACKPARROT_DIR  := $(TOP)/black-parrot
export BP_COMMON_DIR    := $(BLACKPARROT_DIR)/bp_common
export BP_FE_DIR        := $(BLACKPARROT_DIR)/bp_fe
export BP_BE_DIR        := $(BLACKPARROT_DIR)/bp_be
export BP_ME_DIR        := $(BLACKPARROT_DIR)/bp_me
export BP_TOP_DIR       := $(BLACKPARROT_DIR)/bp_top
export BP_EXTERNAL_DIR  := $(BLACKPARROT_DIR)/external
export BASEJUMP_STL_DIR := $(BP_EXTERNAL_DIR)/basejump_stl
export HARDFLOAT_DIR    := $(BP_EXTERNAL_DIR)/HardFloat
export PATH := $(SYNLIG_DIR)/out/current/bin:$(PATH)

export PDK_ROOT         := $(SKY130_DIR)
export PDK              := $(SKY130_VER)
export STD_CELL_LIBRARY := sky130_fd_sc_hd
export TECHMAP_DIR      := $(PDK_ROOT)/$(PDK)/libs.tech/openlane/$(STD_CELL_LIBRARY)
export FLIST            := flist.vcs
all: $(FLIST)
	cd $(BASEJUMP_STL_DIR); git checkout dpetrisko-patch-24
	$(YOSYS) -c yosys.tcl | tee run.log

$(FLIST):
	$(CAT) $(BLACKPARROT_DIR)/bp_top/syn/flist.vcs | $(ENVSUBST) > $@
	$(SED) -i 's/#.*$$//' flist.vcs
	$(SED) -i '/^$$/d' flist.vcs

clean:
	rm -rf flist.vcs

