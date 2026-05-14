onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/clk
add wave -noupdate /tb/reset
add wave -noupdate /tb/Ext_MemWrite
add wave -noupdate /tb/Ext_WriteData
add wave -noupdate /tb/Ext_DataAdr
add wave -noupdate /tb/WriteData
add wave -noupdate /tb/DataAdr
add wave -noupdate /tb/ReadData
add wave -noupdate /tb/MemWrite
add wave -noupdate /tb/PC
add wave -noupdate /tb/Result
add wave -noupdate /tb/fault_instrs
add wave -noupdate /tb/i
add wave -noupdate /tb/fw
add wave -noupdate /tb/flag
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1704310 ps} 0}
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
WaveRestoreZoom {1704050 ps} {1705050 ps}
