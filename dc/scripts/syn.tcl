########################################################################
#   This is a tcl script in dc_shell-t for pre-layout synthesis        #
#   Company:  SUSTECH                                                  #		
#   author:   XXXXX                                                    #
#   Version   1.0                                                      #
#   Date:     20220428                                                 #
########################################################################

########################################################################
# TCL script for DC to synthesize                                      #
########################################################################
set hdlin_translate_off_skip_text "true"
set verilogout_no_tri             "true"
# 写出的netlist就不会包含assign,会把tri变成wire
set default_schematic_options     "-size infinite"  
set write_name_nets_same_as_ports "true"
# dc_shell TcL startup script:
set designer "XXXXX"
set company  "SUSTECH"

########################################################################
###      1.  setup design files path                                 ###
########################################################################	
set proj_path     ../../
set work_path     $proj_path/dc
set rtl_path      $proj_path/rtl
set lib_path      $proj_path/lib
set search_path   "$search_path $work_path $rtl_path $lib_path"
set design_name   multiplier

set_app_var target_library sc_max.db
set_app_var link_library   sc_max.db
set_app_var symbol_library sc_max.db
###      set svf file for formality                                  ###
set_svf $work_path/outputs/$design_name.svf

########################################################################
###      2.  read in verilog code                                    ###
########################################################################
# Set up a work library for this design in a subdirectory:
define_design_lib syn_temp -path ./syn_temp
analyze -work syn_temp -format verilog $rtl_path/$design_name.v
elaborate -work syn_temp $design_name >> "$work_path/reports/$design_name.read_in"
current_design $design_name

########################################################################
###      3.  set enviroment parameter and compile                    ###
########################################################################
set_operating_conditions -library cb13fs120_tsmc_max cb13fs120_tsmc_max
set_wire_load_model -name tc8000000 -library cb13fs120_tsmc_max
set_fix_multiple_port_nets -all -buffer_constants

# 移除之前的约束
reset_design
#时钟周期3ns
create_clock -period 3.0 [get_ports clk]  
#系统时钟到输入端口clk时钟的延迟 
set_clock_latency -source  -max 0.7 [get_clocks clk] 
#输入端口时钟clk到模块内部时钟的延时
set_clock_latency -max 0.3 [get_clocks clk]
#时钟的不确定偏斜时间0.15ns
set_clock_uncertainty -setup 0.15 [get_clocks clk]
#时钟的转换时间0.12ns
set_clock_transition 0.12 [get_clocks clk]

#输入端口的延迟
set_input_delay -max  0.3 -clock clk [all_inputs]
#输入端口的转换时间 
set_input_transition 0.12 [all_inputs]

#输出端口out1的延迟
set_output_delay -max  2.0 -clock clk [all_outputs]

set_drive               5.0 [all_inputs]
set_load                1.0 [all_outputs]
set_max_fanout          5   [all_inputs]
set_max_transition      2.0     $design_name
set_max_fanout          20      $design_name
set_max_area            2000
set_max_delay           0.5 -to [all_outputs]

# No clock buffers allowed for regular logic paths.
#set_dont_use [get_cells slow/CLKBUF*]
#set_dont_use [get_cells slow/CLKINV*]
#no low power cells
#set_dont_use [get_cells slow/*XL]
#no scan cells
#set_dont_use [get_cells slow/SDFF*]
#set_dont_use [get_cells slow/SEDFF*]
#no negative_triggered cells
#set_dont_use [get_cells slow/*DFFN*]
# set dont touch cells

# Drop into interactive mode for compile & optimize:
# compile
compile_ultra
# ungroup -all -flatten
# compile -map_effort high 

########################################################################
###      4.  report design&lib information                           ###
########################################################################
check_design > "$work_path/reports/$design_name.check"
report_area > $work_path/reports/$design_name.area
report_power > $work_path/reports/$design_name.power
report_timing  > $work_path/reports/$design_name.timing
report_timing -loops >> $work_path/reports/$design_name.timing
report_constraint > $work_path/reports/$design_name.rc
report_constraint -verbose >> $work_path/reports/$design_name.rc
report_constraint -all_violators > $work_path/reports/$design_name.violator

########################################################################
###      5.  Write file for use in other tools                       ###
########################################################################
#write -format ddc -hierarchy -output "$work_path/output/$design_name.ddc"
#write -format db -hierarchy -xg_force_db -output "$work_path/output/$design_name.db"
#write -format db -hierarchy -output "$work_path/output/$design_name.db"
write -format verilog -hierarchy -output "$work_path/outputs/$design_name.v"
write_sdf -version 2.1 "$work_path/outputs/$design_name.sdf"
#write_parasitics -format reduced -output "$work_path/output/$design_name.spef"
write_sdc "$work_path/outputs/$design_name.sdc"
write_sdf "$work_path/outputs/$design_name.sdf"
# Quit DC:
exit
sh date >> $work_path/outputs/$design_name.date
#remove_design -all

