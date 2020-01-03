
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name VGAdemo -dir "E:/atk/VGAdemo/planAhead_run_1" -part xc7k160tffg676-2L
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "E:/atk/VGAdemo/Top.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {E:/atk/VGAdemo} {ipcore_dir} }
add_files [list {ipcore_dir/amp.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/btank.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/TANK.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/tanka.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/test.ncf}] -fileset [get_property constrset [current_run]]
add_files [list {ipcore_dir/testtanka.ncf}] -fileset [get_property constrset [current_run]]
set_param project.pinAheadLayout  yes
set_property target_constrs_file "Sword_Original.ucf" [current_fileset -constrset]
add_files [list {Sword_Original.ucf}] -fileset [get_property constrset [current_run]]
link_design
