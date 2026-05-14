onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/clk_3125
add wave -noupdate /tb/data
add wave -noupdate /tb/parity_type
add wave -noupdate /tb/parity_bit
add wave -noupdate /tb/tx_start
add wave -noupdate /tb/tx
add wave -noupdate /tb/tx_exp
add wave -noupdate /tb/tx_err
add wave -noupdate /tb/tx_done
add wave -noupdate /tb/tx_done_exp
add wave -noupdate /tb/tx_done_err
add wave -noupdate /tb/r
add wave -noupdate /tb/i
add wave -noupdate /tb/k
add wave -noupdate /tb/j
add wave -noupdate /tb/y
add wave -noupdate /tb/x
add wave -noupdate /tb/err
add wave -noupdate /tb/fd
add wave -noupdate /tb/fw
add wave -noupdate /tb/data_packet
add wave -noupdate /tb/file_data
add wave -noupdate /tb/str
add wave -noupdate /tb/rev_msg
add wave -noupdate /tb/msg
add wave -noupdate /tb/flag
add wave -noupdate /tb/cnt
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {765279220 ps} 0}
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
WaveRestoreZoom {765279050 ps} {765280050 ps}
