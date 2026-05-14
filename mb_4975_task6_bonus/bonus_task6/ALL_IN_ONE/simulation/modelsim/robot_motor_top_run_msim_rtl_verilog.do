transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+D:/e-yantra/motors {D:/e-yantra/motors/robot_motor_top.v}
vlog -vlog01compat -work work +incdir+D:/e-yantra/motors {D:/e-yantra/motors/encoder_decoder.v}
vlog -vlog01compat -work work +incdir+D:/e-yantra/motors {D:/e-yantra/motors/motor_controller.v}
vlog -vlog01compat -work work +incdir+D:/e-yantra/motors {D:/e-yantra/motors/pwm_generator.v}
vlog -vlog01compat -work work +incdir+D:/e-yantra/motors {D:/e-yantra/motors/path_controller.v}

vlog -vlog01compat -work work +incdir+D:/e-yantra/motors/output_files {D:/e-yantra/motors/output_files/tb_robot_motor_top.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cycloneive_ver -L rtl_work -L work -voptargs="+acc"  tb_robot_motor_top

add wave *
view structure
view signals
run -all
