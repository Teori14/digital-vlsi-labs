#*****************************************************************************************
# DVLSI Lab6 Bonus - create original project, add AXI-Lite configuration through AXI GPIO,
# regenerate wrapper, add runtime Debayer VHDL sources.
#
# Usage from Vivado Tcl shell or Windows cmd:
#   vivado -mode batch -source scripts/build_bonus_runtime.tcl
#
# Folder assumption:
#   project_root/
#     scripts/build_bonus_runtime.tcl
#     scripts/dvlsi_lab6_prj_v2022_2.tcl
#     vhdl_srcs/dvlsi_lab6_top.vhd
#     vhdl_srcs/debayer_partA_final_line_buffers.vhd
#     vhdl_srcs/debayer_core_pipelined.vhd
#*****************************************************************************************

set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize [file join $script_dir ".."]]

# 1) Create the original Lab6 project from the provided Tcl.
source [file join $script_dir "dvlsi_lab6_prj_v2022_2.tcl"]

# 2) Add the Debayer sources that the original Tcl does not add explicitly.
set srcset [get_filesets sources_1]
foreach f [list \
    [file join $root_dir "vhdl_srcs/debayer_core_pipelined.vhd"] \
    [file join $root_dir "vhdl_srcs/debayer_partA_final_line_buffers.vhd"] \
] {
    set nf [file normalize $f]
    if {[llength [get_files -quiet $nf]] == 0} {
        add_files -norecurse -fileset $srcset $nf
    }
    set_property file_type VHDL [get_files $nf]
}

# 3) Patch block design: add an AXI GPIO used as a simple AXI-Lite config register.
open_bd_design [get_files design_1.bd]
current_bd_design design_1

if {[llength [get_bd_cells -quiet DEBAYER_CFG]] == 0} {
    # Add third AXI-Lite master port on the existing PS AXI interconnect.
    set_property CONFIG.NUM_MI {3} [get_bd_cells ps7_0_axi_periph]

    set debayer_cfg_ip [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 DEBAYER_CFG]
    set_property -dict [list \
        CONFIG.C_GPIO_WIDTH {17} \
        CONFIG.C_ALL_OUTPUTS {1} \
        CONFIG.C_IS_DUAL {0} \
    ] $debayer_cfg_ip

    # External vector to the VHDL top:
    # debayer_cfg[15:0] = image_dim
    # debayer_cfg[16]   = image_dim_vld
    set debayer_cfg_port [create_bd_port -dir O -from 16 -to 0 debayer_cfg]
    connect_bd_net [get_bd_ports debayer_cfg] [get_bd_pins DEBAYER_CFG/gpio_io_o]

    connect_bd_intf_net [get_bd_intf_pins ps7_0_axi_periph/M02_AXI] [get_bd_intf_pins DEBAYER_CFG/S_AXI]

    # Keep AXI GPIO on the existing AXI-Lite clock/reset domain.
    connect_bd_net [get_bd_pins PS_ARM/FCLK_CLK0] [get_bd_pins DEBAYER_CFG/s_axi_aclk]
    connect_bd_net [get_bd_pins PS_ARM/FCLK_CLK0] [get_bd_pins ps7_0_axi_periph/M02_ACLK]

    connect_bd_net [get_bd_pins PL_GEN_ARESETN_50/peripheral_aresetn] [get_bd_pins DEBAYER_CFG/s_axi_aresetn]
    connect_bd_net [get_bd_pins PL_GEN_ARESETN_50/peripheral_aresetn] [get_bd_pins ps7_0_axi_periph/M02_ARESETN]

    assign_bd_address -offset 0x41200000 -range 0x00010000 \
        -target_address_space [get_bd_addr_spaces PS_ARM/Data] \
        [get_bd_addr_segs DEBAYER_CFG/S_AXI/Reg] -force
}

validate_bd_design
save_bd_design

# 4) Regenerate BD output products and wrapper, because wrapper now has debayer_cfg port.
generate_target all [get_files design_1.bd]
set wrapper_files [make_wrapper -files [get_files design_1.bd] -top -force]

# Remove the old static wrapper if it exists in sources and add the regenerated one.
foreach oldw [get_files -quiet *vhdl_srcs/design_1_wrapper.vhd] {
    remove_files $oldw
}
foreach wf $wrapper_files {
    if {[llength [get_files -quiet $wf]] == 0} {
        add_files -norecurse -fileset $srcset $wf
    }
    set_property file_type VHDL [get_files $wf]
}

set_property top dvlsi_lab6_top $srcset
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# 5) Optional: run synthesis/implementation/bitstream.
# Uncomment these lines when the project opens and elaborates correctly.
# launch_runs synth_1 -jobs 4
# wait_on_run synth_1
# launch_runs impl_1 -to_step write_bitstream -jobs 4
# wait_on_run impl_1

puts "DONE: Bonus runtime project created and patched."
puts "AXI GPIO config base address is forced to 0x41200000."
