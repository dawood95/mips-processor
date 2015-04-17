onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group RAM /system_tb/DUT/RAM/CLK
add wave -noupdate -group RAM /system_tb/DUT/RAM/nRST
add wave -noupdate -group RAM /system_tb/DUT/RAM/count
add wave -noupdate -group RAM /system_tb/DUT/RAM/rstate
add wave -noupdate -group RAM /system_tb/DUT/RAM/q
add wave -noupdate -group RAM /system_tb/DUT/RAM/addr
add wave -noupdate -group RAM /system_tb/DUT/RAM/wren
add wave -noupdate -group RAM /system_tb/DUT/RAM/en
add wave -noupdate -group {Cache Control} /system_tb/DUT/CPU/CC/CLK
add wave -noupdate -group {Cache Control} /system_tb/DUT/CPU/CC/nRST
add wave -noupdate -group {Cache Control} /system_tb/DUT/CPU/CC/currentState
add wave -noupdate -group {Cache Control} /system_tb/DUT/CPU/CC/nextState
add wave -noupdate -group {Cache Control} /system_tb/DUT/CPU/CC/snoopAddr
add wave -noupdate /system_tb/DUT/CPU/CC/reqCache
add wave -noupdate /system_tb/DUT/CPU/CC/snoopCache
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/iwait
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/dwait
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/iREN
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/dREN
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/dWEN
add wave -noupdate -expand -group CCIF -expand /system_tb/DUT/CPU/ccif/iload
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/dload
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/dstore
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/iaddr
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/daddr
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/ccwait
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/ccinv
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/ccwrite
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/cctrans
add wave -noupdate -expand -group CCIF -childformat {{{/system_tb/DUT/CPU/ccif/ccsnoopaddr[1]} -radix hexadecimal} {{/system_tb/DUT/CPU/ccif/ccsnoopaddr[0]} -radix hexadecimal}} -expand -subitemconfig {{/system_tb/DUT/CPU/ccif/ccsnoopaddr[1]} {-height 17 -radix hexadecimal} {/system_tb/DUT/CPU/ccif/ccsnoopaddr[0]} {-height 17 -radix hexadecimal}} /system_tb/DUT/CPU/ccif/ccsnoopaddr
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/ramWEN
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/ramREN
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/ramstate
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/ramaddr
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/ramstore
add wave -noupdate -expand -group CCIF /system_tb/DUT/CPU/ccif/ramload
add wave -noupdate -group DCACHE0 /system_tb/DUT/CPU/CM0/DCACHE/CLK
add wave -noupdate -group DCACHE0 /system_tb/DUT/CPU/CM0/DCACHE/nRST
add wave -noupdate -group DCACHE0 /system_tb/DUT/CPU/CM0/DCACHE/currentState
add wave -noupdate -group DCACHE0 /system_tb/DUT/CPU/CM0/DCACHE/nextState
add wave -noupdate -group DCACHE0 /system_tb/DUT/CPU/CM0/DCACHE/addr
add wave -noupdate -group DCACHE0 /system_tb/DUT/CPU/CM0/DCACHE/snoopaddr
add wave -noupdate /system_tb/DUT/CPU/CM0/DCACHE/frame
add wave -noupdate {/system_tb/DUT/CPU/CM1/DCACHE/frame[4]}
add wave -noupdate /system_tb/DUT/CPU/CM1/DCACHE/frame
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/halt
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/ihit
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/imemREN
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/imemload
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/imemaddr
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/dhit
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/datomic
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/dmemREN
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/dmemWEN
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/flushed
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/dmemload
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/dmemstore
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/dcif0/dmemaddr
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/DP0/ifetch
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/DP0/decode
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/DP0/exec
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/DP0/mem
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/DP0/regw
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/DP0/npc
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/DP0/npc_ff
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/DP0/immExt
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/DP0/regW_sel
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/DP0/iinstr
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/DP0/jinstr
add wave -noupdate -expand -group DP0 /system_tb/DUT/CPU/DP0/rinstr
add wave -noupdate -group DCACHE1 /system_tb/DUT/CPU/CM1/DCACHE/CLK
add wave -noupdate -group DCACHE1 /system_tb/DUT/CPU/CM1/DCACHE/nRST
add wave -noupdate -group DCACHE1 /system_tb/DUT/CPU/CM1/DCACHE/currentState
add wave -noupdate -group DCACHE1 /system_tb/DUT/CPU/CM1/DCACHE/nextState
add wave -noupdate -group DCACHE1 /system_tb/DUT/CPU/CM1/DCACHE/addr
add wave -noupdate -group DCACHE1 /system_tb/DUT/CPU/CM1/DCACHE/snoopaddr
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/halt
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/ihit
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/imemREN
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/imemload
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/imemaddr
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/dhit
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/datomic
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/dmemREN
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/dmemWEN
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/flushed
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/dmemload
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/dmemstore
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/dcif1/dmemaddr
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/CLK
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/nRST
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/ifetch
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/decode
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/exec
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/mem
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/regw
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/npc
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/npc_ff
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/immExt
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/pcEn_ifde
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/pcEn_deex
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/pcEn_exmem
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/pcEn_memregw
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/ifde_en
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/deex_en
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/exmem_en
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/immExt_sel
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/btb_correct
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/btb_wrongtype
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/regW_sel
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/iinstr
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/jinstr
add wave -noupdate -expand -group DP1 /system_tb/DUT/CPU/DP1/rinstr
add wave -noupdate -expand -group I0 /system_tb/DUT/CPU/CM0/ICACHE/CLK
add wave -noupdate -expand -group I0 /system_tb/DUT/CPU/CM0/ICACHE/nRST
add wave -noupdate -expand -group I0 /system_tb/DUT/CPU/CM0/ICACHE/state
add wave -noupdate -expand -group I0 /system_tb/DUT/CPU/CM0/ICACHE/nextState
add wave -noupdate -expand -group I0 /system_tb/DUT/CPU/CM0/ICACHE/frames
add wave -noupdate -expand -group I0 /system_tb/DUT/CPU/CM0/ICACHE/icache_addr
add wave -noupdate -expand -group I0 /system_tb/DUT/CPU/CM0/ICACHE/blk
add wave -noupdate -expand -group I1 /system_tb/DUT/CPU/CM1/ICACHE/CLK
add wave -noupdate -expand -group I1 /system_tb/DUT/CPU/CM1/ICACHE/nRST
add wave -noupdate -expand -group I1 /system_tb/DUT/CPU/CM1/ICACHE/state
add wave -noupdate -expand -group I1 /system_tb/DUT/CPU/CM1/ICACHE/nextState
add wave -noupdate -expand -group I1 /system_tb/DUT/CPU/CM1/ICACHE/frames
add wave -noupdate -expand -group I1 /system_tb/DUT/CPU/CM1/ICACHE/icache_addr
add wave -noupdate -expand -group I1 /system_tb/DUT/CPU/CM1/ICACHE/blk
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {177648 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 188
configure wave -valuecolwidth 215
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
WaveRestoreZoom {0 ps} {1153966 ps}
