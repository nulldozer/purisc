transcript on
if ![file isdirectory vhdl_libs] {
	file mkdir vhdl_libs
}


vlib vhdl_libs/altera_mf
vmap altera_mf ./vhdl_libs/altera_mf
vcom -93 -work altera_mf {c:/altera/13.1/quartus/eda/sim_lib/altera_mf_components.vhd}
vcom -93 -work altera_mf {c:/altera/13.1/quartus/eda/sim_lib/altera_mf.vhd}

if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work



vcom -93 -work work {../../LOAD_BALANCER.vhd}
vcom -93 -work work {../../MAGIC_clocked/tristate_32.vhd}
vcom -93 -work work {../../MAGIC_clocked/tristate.vhd}
vcom -93 -work work {../../MAGIC_clocked/SETUP.vhd}
vcom -93 -work work {../../MAGIC_clocked/SELECTOR.vhd}
vcom -93 -work work {../../MAGIC_clocked/ROUTE_SIGNAL.vhd}
vcom -93 -work work {../../MAGIC_clocked/ROUTE.vhd}
vcom -93 -work work {../../MAGIC_clocked/RAM_7.vhd}
vcom -93 -work work {../../MAGIC_clocked/RAM_6.vhd}
vcom -93 -work work {../../MAGIC_clocked/RAM_5.vhd}
vcom -93 -work work {../../MAGIC_clocked/RAM_4.vhd}
vcom -93 -work work {../../MAGIC_clocked/RAM_3.vhd}
vcom -93 -work work {../../MAGIC_clocked/RAM_2.vhd}
vcom -93 -work work {../../MAGIC_clocked/RAM_1.vhd}
vcom -93 -work work {../../MAGIC_clocked/RAM_0.vhd}
vcom -93 -work work {../../MAGIC_clocked/MAGIC.vhd}
vcom -93 -work work {../../MAGIC_clocked/HAZARD_RESOLVE.vhd}
vcom -93 -work work {../../MAGIC_clocked/FLOW.vhd}
vcom -93 -work work {../../MAGIC_clocked/create_opcode.vhd}
vcom -93 -work work {../../MAGIC_clocked/address_transcode.vhd}
vcom -93 -work work {../../CORE/read_instruction_stage.vhd}
vcom -93 -work work {../../CORE/read_data_stage.vhd}
vcom -93 -work work {../../CORE/purisc_core.vhd}
vcom -93 -work work {../../CORE/execute_stage.vhd}
vcom -93 -work work {../../Compute_Group.vhd}

vlog -sv -work work {../../testbench.sv}

vsim -t 1ps -L altera_mf -L rtl_work -L work -voptargs="+acc"  compute_group_testbench

add wave *
view structure
view signals
run 100ns
