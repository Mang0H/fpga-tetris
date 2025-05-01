# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: /home/user/projects/tetris/sdk/tetris_system/_ide/scripts/debugger_tetris-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source /home/user/projects/tetris/sdk/tetris_system/_ide/scripts/debugger_tetris-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "Xilinx Virtual Cable host.docker.internal:2542" && level==0 && jtag_device_ctx=="jsn-XVC-host.docker.internal:2542-0362f093-0"}
fpga -file /home/user/projects/tetris/sdk/tetris/_ide/bitstream/tetris_top.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw /home/user/projects/tetris/sdk/tetris_top/export/tetris_top/hw/tetris_top.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow /home/user/projects/tetris/sdk/tetris/Debug/tetris.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
con
