# Based on https://yosyshq.net/yosys/
yosys -import
plugin -i systemverilog
yosys -import

set flist $::env(FLIST)
set techmap_dir $::env(TECHMAP_DIR)

source ${techmap_dir}/config.tcl
set lib_file $::env(LIB_SYNTH)

set tiehi_cell       sky130_fd_sc_hd__conb
set tiehi_pin        HI
set tielo_cell       sky130_fd_sc_hd__conb
set tielo_pin        LO
set clkbuf_cell      sky130_fd_sc_hd__clkbuf
set clkbuf_pin       X
set buf_cell         sky130_fd_sc_hd__buf
set buf_ipin         A
set buf_opin         X

set f [split [string trim [read [open ${flist} r]]] "\n"]
foreach x $f {
  if {![string match "" $x]} {
    # If the item starts with +incdir+, directory files need to be added
    if {[string match "+" [string index $x 0]]} {
      set trimchars "+incdir+"
      set temp [string trimleft $x $trimchars]
      set expanded [subst $temp]
      systemverilog_defaults -add "-I${expanded} "
    } else {
      set expanded [subst $x]
      read_systemverilog -defer ${expanded}
    }
  }
}

set design bp_unicore
set verilog_v_file output.sv2v.v
set elab_v_file output.elab.v
set opt_v_file output.opt.v
set map_v_file output.map.v
set syn_v_file output.syn.v

set check_file check.rpt
set stat_file stat.rpt

read_systemverilog -link --top-module ${design}

# write verilog design
write_verilog -nostr -noattr -noexpr -nohex -nodec ${verilog_v_file}

# elaborate design hierarchy
hierarchy -check -top ${design}

# write elab design
write_verilog -nostr -noattr -noexpr -nohex -nodec ${elab_v_file}

# the high-level stuff
yosys proc; opt; fsm; opt; yosys memory; opt

# write opt design
write_verilog -nostr -noattr -noexpr -nohex -nodec ${opt_v_file}

# mapping to internal cell library
techmap; opt
techmap -map ${techmap_dir}/csa_map.v
techmap -map ${techmap_dir}/fa_map.v
techmap -map ${techmap_dir}/latch_map.v
techmap -map ${techmap_dir}/mux2_map.v
techmap -map ${techmap_dir}/mux4_map.v
techmap -map ${techmap_dir}/rca_map.v
techmap -map ${techmap_dir}/tribuff_map.v

# mapping to cell lib
dfflibmap -liberty ${lib_file}

# write mapped design
write_verilog -nostr -noattr -noexpr -nohex -nodec ${map_v_file}

# mapping logic to cell lib
abc -liberty ${lib_file}

# Set X to zero
setundef -zero

# mapping constants and clock buffers to cell lib
hilomap -hicell ${tiehi_cell} ${tiehi_pin} -locell ${tielo_cell} ${tielo_pin}
clkbufmap -buf ${clkbuf_cell} ${clkbuf_pin}

# Split nets to single bits and map to buffers
splitnets
insbuf -buf ${buf_cell} ${buf_ipin} ${buf_opin}

# Clean up the design
opt_clean -purge

# Check and print statistics
tee -o ${check_file} check -mapped -noinit
tee -o ${stat_file} stat -top ${design} -liberty ${lib_file} -tech cmos -width -json

# write synthesized design
write_verilog -nostr -noattr -noexpr -nohex -nodec ${syn_v_file}

