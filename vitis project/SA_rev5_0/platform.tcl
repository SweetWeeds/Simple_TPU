# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\DICE\workspace\SA_rev5_0\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\DICE\workspace\SA_rev5_0\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {SA_rev5_0}\
-hw {D:\workspace\210805_1710\systolic_array\SYSTOLIC_ARRAY_BD_wrapper_rev5_0.xsa}\
-proc {psu_cortexa53_0} -os {standalone} -arch {64-bit} -fsbl-target {psu_cortexa53_0} -out {C:/Users/DICE/workspace}

platform write
platform generate -domains 
platform active {SA_rev5_0}
platform generate
platform clean
platform generate
