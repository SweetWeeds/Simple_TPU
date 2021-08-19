# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: C:\Users\DICE\workspace\SA_rev6_2_FC_TB_system\_ide\scripts\debugger_sa_rev6_2_fc_tb-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source C:\Users\DICE\workspace\SA_rev6_2_FC_TB_system\_ide\scripts\debugger_sa_rev6_2_fc_tb-default.tcl
# 
connect -url tcp:127.0.0.1:3121
source C:/Xilinx/Vitis/2020.2/scripts/vitis/util/zynqmp_utils.tcl
targets -set -nocase -filter {name =~"APU*"}
rst -system
after 3000
targets -set -filter {jtag_cable_name =~ "Digilent JTAG-SMT2NC 210308AE680E" && level==0 && jtag_device_ctx=="jsn-JTAG-SMT2NC-210308AE680E-24738093-0"}
fpga -file C:/Users/DICE/workspace/SA_rev6_2_FC_TB/_ide/bitstream/SYSTOLIC_ARRAY_BD_wrapper_rev6_2.bit -no-revision-check
targets -set -nocase -filter {name =~"APU*"}
loadhw -hw C:/Users/DICE/workspace/SA_rev6_2/export/SA_rev6_2/hw/SYSTOLIC_ARRAY_BD_wrapper_rev6_2.xsa -mem-ranges [list {0x80000000 0xbfffffff} {0x400000000 0x5ffffffff} {0x1000000000 0x7fffffffff}] -regs
configparams force-mem-access 1
targets -set -nocase -filter {name =~"APU*"}
set mode [expr [mrd -value 0xFF5E0200] & 0xf]
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor
dow C:/Users/DICE/workspace/SA_rev6_2/export/SA_rev6_2/sw/SA_rev6_2/boot/fsbl.elf
set bp_46_59_fsbl_bp [bpadd -addr &XFsbl_Exit]
con -block -timeout 60
bpremove $bp_46_59_fsbl_bp
targets -set -nocase -filter {name =~ "*A53*#0"}
rst -processor
dow C:/Users/DICE/workspace/SA_rev6_2_FC_TB/Debug/SA_rev6_2_FC_TB.elf
configparams force-mem-access 0
bpadd -addr &main
