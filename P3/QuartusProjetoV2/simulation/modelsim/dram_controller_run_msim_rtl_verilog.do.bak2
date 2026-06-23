transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -vlog01compat -work work +incdir+/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos {/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos/dram_top_level.v}
vlog -vlog01compat -work work +incdir+/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos {/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos/dram_controller.v}
vlog -vlog01compat -work work +incdir+/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos {/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos/dram_iface.v}
vlog -vlog01compat -work work +incdir+/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos {/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos/write.v}
vlog -vlog01compat -work work +incdir+/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos {/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos/read.v}
vlog -vlog01compat -work work +incdir+/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos {/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos/init.v}
vlog -vlog01compat -work work +incdir+/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos {/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos/bin2hex.v}
vlog -vlog01compat -work work +incdir+/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos {/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/Modulos/autorefresh.v}

vlog -vlog01compat -work work +incdir+/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/QuartusProjetoV2/../Modulos {/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/QuartusProjetoV2/../Modulos/init.v}
vlog -vlog01compat -work work +incdir+/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/QuartusProjetoV2/../TestBenchs {/home/c-ec2024/ra252694/Documents/MC613/PosGreve/Projetos-MC613/P3/QuartusProjetoV2/../TestBenchs/init_tb.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  init_tb

add wave *
view structure
view signals
run -all
