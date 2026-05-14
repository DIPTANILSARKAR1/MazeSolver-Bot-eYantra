onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/clk_3125
add wave -noupdate /tb/rx
add wave -noupdate /tb/rx_msg
add wave -noupdate /tb/rx_exp
add wave -noupdate /tb/rx_parity
add wave -noupdate /tb/exp_parity
add wave -noupdate /tb/rx_complete
add wave -noupdate /tb/exp_rx_complete
add wave -noupdate /tb/err
add wave -noupdate /tb/data
add wave -noupdate /tb/msg
add wave -noupdate /tb/i
add wave -noupdate /tb/j
add wave -noupdate /tb/k
add wave -noupdate /tb/p
add wave -noupdate /tb/fd
add wave -noupdate /tb/fw
add wave -noupdate /tb/s
add wave -noupdate /tb/f
add wave -noupdate /tb/counter
add wave -noupdate /tb/str
add wave -noupdate /tb/flag
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {999999279 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {1050 us}
