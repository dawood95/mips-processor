onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /system_tb/CLK
add wave -noupdate /system_tb/nRST
add wave -noupdate /system_tb/CLK
add wave -noupdate /system_tb/nRST
add wave -noupdate /system_tb/DUT/CPU/CLK
add wave -noupdate /system_tb/DUT/CPU/nRST
add wave -noupdate -expand -group RAM /system_tb/DUT/CPU/scif/ramREN
add wave -noupdate -expand -group RAM /system_tb/DUT/CPU/scif/ramWEN
add wave -noupdate -expand -group RAM /system_tb/DUT/CPU/scif/ramaddr
add wave -noupdate -expand -group RAM /system_tb/DUT/CPU/scif/ramstore
add wave -noupdate -expand -group RAM /system_tb/DUT/CPU/scif/ramload
add wave -noupdate -expand -group RAM /system_tb/DUT/CPU/scif/ramstate
add wave -noupdate -expand -group RAM /system_tb/DUT/CPU/scif/memREN
add wave -noupdate -expand -group RAM /system_tb/DUT/CPU/scif/memWEN
add wave -noupdate -expand -group RAM /system_tb/DUT/CPU/scif/memaddr
add wave -noupdate -expand -group RAM /system_tb/DUT/CPU/scif/memstore
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/halt
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/CM/dcif/flushed
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/CM/DCACHE/flush_frame
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/CM/DCACHE/currentState
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/ihit
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/imemREN
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/imemload
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/imemaddr
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/dhit
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/datomic
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/dmemREN
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/dmemWEN
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/flushed
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/dmemload
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/dmemstore
add wave -noupdate -expand -group {DataPath Cache} /system_tb/DUT/CPU/dcif/dmemaddr
add wave -noupdate -expand -group Datapath /system_tb/DUT/CPU/DP/CLK
add wave -noupdate -expand -group Datapath /system_tb/DUT/CPU/DP/nRST
add wave -noupdate -expand -group Datapath /system_tb/DUT/CPU/DP/control_unit/iinstr
add wave -noupdate -expand -group Datapath /system_tb/DUT/CPU/DP/control_unit/jinstr
add wave -noupdate -expand -group Datapath /system_tb/DUT/CPU/DP/control_unit/rinstr
add wave -noupdate -expand -group Datapath /system_tb/DUT/CPU/DP/immExt
add wave -noupdate -expand -group Datapath /system_tb/DUT/CPU/DP/immExt_sel
add wave -noupdate -expand -group Datapath /system_tb/DUT/CPU/DP/regW_sel
add wave -noupdate -expand -group register /system_tb/DUT/CPU/DP/rfif/WEN
add wave -noupdate -expand -group register -radix unsigned /system_tb/DUT/CPU/DP/rfif/wsel
add wave -noupdate -expand -group register /system_tb/DUT/CPU/DP/rfif/rsel1
add wave -noupdate -expand -group register /system_tb/DUT/CPU/DP/rfif/rsel2
add wave -noupdate -expand -group register /system_tb/DUT/CPU/DP/rfif/wdat
add wave -noupdate -expand -group register /system_tb/DUT/CPU/DP/rfif/rdat1
add wave -noupdate -expand -group register /system_tb/DUT/CPU/DP/rfif/rdat2
add wave -noupdate /system_tb/DUT/CPU/DP/alif/nf
add wave -noupdate /system_tb/DUT/CPU/DP/alif/zf
add wave -noupdate /system_tb/DUT/CPU/DP/alif/of
add wave -noupdate /system_tb/DUT/CPU/DP/alif/porta
add wave -noupdate /system_tb/DUT/CPU/DP/alif/portb
add wave -noupdate /system_tb/DUT/CPU/DP/alif/out
add wave -noupdate /system_tb/DUT/CPU/DP/alif/op
add wave -noupdate /system_tb/DUT/CPU/DP/ifetch
add wave -noupdate /system_tb/DUT/CPU/DP/decode
add wave -noupdate /system_tb/DUT/CPU/DP/exec
add wave -noupdate /system_tb/DUT/CPU/DP/mem
add wave -noupdate /system_tb/DUT/CPU/DP/regw
add wave -noupdate /system_tb/DUT/CPU/DP/dpif/halt
add wave -noupdate /system_tb/DUT/CPU/CM/dcif/flushed
add wave -noupdate /system_tb/DUT/CPU/DP/pcEn_ifde
add wave -noupdate /system_tb/DUT/CPU/DP/pcEn_deex
add wave -noupdate /system_tb/DUT/CPU/DP/pcEn_exmem
add wave -noupdate /system_tb/DUT/CPU/DP/pcEn_memregw
add wave -noupdate /system_tb/DUT/CPU/DP/ifde_en
add wave -noupdate /system_tb/DUT/CPU/DP/deex_en
add wave -noupdate /system_tb/DUT/CPU/DP/exmem_en
add wave -noupdate /system_tb/DUT/CPU/DP/reg_file/register_f
add wave -noupdate -expand -group BTB /system_tb/DUT/CPU/DP/BTB/CLK
add wave -noupdate -expand -group BTB /system_tb/DUT/CPU/DP/BTB/nRST
add wave -noupdate -expand -group BTB /system_tb/DUT/CPU/DP/BTB/instr
add wave -noupdate -expand -group BTB /system_tb/DUT/CPU/DP/BTB/pr_correct
add wave -noupdate -expand -group BTB /system_tb/DUT/CPU/DP/BTB/update_br_target
add wave -noupdate -expand -group BTB /system_tb/DUT/CPU/DP/BTB/w_index
add wave -noupdate -expand -group BTB /system_tb/DUT/CPU/DP/BTB/r_index
add wave -noupdate -expand -group BTB /system_tb/DUT/CPU/DP/BTB/br_target
add wave -noupdate -expand -group BTB /system_tb/DUT/CPU/DP/BTB/take_br
add wave -noupdate -expand -group BTB /system_tb/DUT/CPU/DP/BTB/out_index
add wave -noupdate -expand -group BTB /system_tb/DUT/CPU/DP/BTB/out_idx
add wave -noupdate -expand /system_tb/DUT/CPU/DP/BTB/target
add wave -noupdate /system_tb/DUT/CPU/DP/btb_correct
add wave -noupdate /system_tb/DUT/CPU/DP/btb_wrongtype
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {985678 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {1172593 ps} {1388037 ps}
