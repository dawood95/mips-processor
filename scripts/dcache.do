onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /dcache_tb/CLK
add wave -noupdate /dcache_tb/nRST
add wave -noupdate /dcache_tb/DUT/flush_frame
add wave -noupdate /dcache_tb/DUT/next_flush_frame
add wave -noupdate /dcache_tb/DUT/flush_block
add wave -noupdate /dcache_tb/DUT/next_flush_block
add wave -noupdate /dcache_tb/DUT/count_en
add wave -noupdate /dcache_tb/DUT/count
add wave -noupdate -expand -group DUT /dcache_tb/DUT/currentState
add wave -noupdate -expand -group DUT /dcache_tb/DUT/nextState
add wave -noupdate -expand -group DUT /dcache_tb/DUT/addr
add wave -noupdate -expand -group DUT /dcache_tb/DUT/wen
add wave -noupdate -expand -group DUT /dcache_tb/DUT/membsel
add wave -noupdate -expand -group DUT /dcache_tb/DUT/bsel
add wave -noupdate -expand -group {Cache control} {/dcache_tb/DUT/ccif/dREN[0]}
add wave -noupdate -expand -group {Cache control} {/dcache_tb/DUT/ccif/dWEN[0]}
add wave -noupdate -expand -group {Cache control} {/dcache_tb/mc/ccif/dwait[0]}
add wave -noupdate -expand -group {Cache control} {/dcache_tb/mc/ccif/dload[0]}
add wave -noupdate -expand -group {Cache control} {/dcache_tb/mc/ccif/dstore[0]}
add wave -noupdate -expand -group {Cache control} {/dcache_tb/mc/ccif/daddr[0]}
add wave -noupdate -expand -group {Datapath cache} /dcache_tb/DUT/dcif/halt
add wave -noupdate -expand -group {Datapath cache} /dcache_tb/DUT/dcif/dhit
add wave -noupdate -expand -group {Datapath cache} /dcache_tb/DUT/dcif/dmemREN
add wave -noupdate -expand -group {Datapath cache} /dcache_tb/DUT/dcif/dmemWEN
add wave -noupdate -expand -group {Datapath cache} /dcache_tb/DUT/dcif/dmemload
add wave -noupdate -expand -group {Datapath cache} /dcache_tb/DUT/dcif/dmemstore
add wave -noupdate -expand -group {Datapath cache} /dcache_tb/DUT/dcif/dmemaddr
add wave -noupdate -expand -group ram /dcache_tb/ramif/ramREN
add wave -noupdate -expand -group ram /dcache_tb/ramif/ramWEN
add wave -noupdate -expand -group ram /dcache_tb/ramif/ramaddr
add wave -noupdate -expand -group ram /dcache_tb/ramif/ramstore
add wave -noupdate -expand -group ram /dcache_tb/ramif/ramload
add wave -noupdate -expand -group ram /dcache_tb/ramif/ramstate
add wave -noupdate -expand -group RAM /dcache_tb/Ram/CLK
add wave -noupdate -expand -group RAM /dcache_tb/Ram/nRST
add wave -noupdate -expand -group RAM /dcache_tb/Ram/count
add wave -noupdate -expand -group RAM /dcache_tb/Ram/rstate
add wave -noupdate -expand -group RAM /dcache_tb/Ram/q
add wave -noupdate -expand -group RAM /dcache_tb/Ram/addr
add wave -noupdate -expand -group RAM /dcache_tb/Ram/wren
add wave -noupdate -expand -group RAM -expand /dcache_tb/Ram/en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 6} {430592 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 132
configure wave -valuecolwidth 135
configure wave -justifyvalue left
configure wave -signalnamewidth 1
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
WaveRestoreZoom {430592 ps} {968832 ps}
