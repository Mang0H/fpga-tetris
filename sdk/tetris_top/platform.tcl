# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct /home/user/projects/tetris/sdk/tetris_top/platform.tcl
# 
# OR launch xsct and run below command.
# source /home/user/projects/tetris/sdk/tetris_top/platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {tetris_top}\
-hw {/home/user/projects/tetris/tetris_top.xsa}\
-out {/home/user/projects/tetris/sdk}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {hello_world}
platform generate -domains 
platform active {tetris_top}
platform generate -quick
platform generate
platform clean
platform generate
platform active {tetris_top}
platform config -updatehw {/home/user/projects/tetris/tetris_top.xsa}
platform clean
platform generate
platform config -updatehw {/home/user/projects/tetris/tetris_top.xsa}
platform config -updatehw {/home/user/projects/tetris/tetris_top.xsa}
platform clean
platform generate
platform config -updatehw {/home/user/projects/tetris/tetris_top.xsa}
platform clean
platform active {tetris_top}
platform config -updatehw {/home/user/projects/tetris/tetris_top.xsa}
platform clean
platform clean
platform generate
platform active {tetris_top}
platform config -updatehw {/home/user/projects/tetris/tetris_top.xsa}
platform clean
platform generate
platform active {tetris_top}
platform config -updatehw {/home/user/projects/tetris/tetris_top.xsa}
platform clean
platform generate
