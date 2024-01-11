#
# ----------------------------------------------------------------------------------
# Stack
#             Node 1                         Node 2                        Sink
#   +--------------------------+   +--------------------------+   +-------------+------------+
#   |  7. UW/CBR               |   |  7. UW/CBR               |   |  7. UW/CBR  | UW/CBR     |
#   +--------------------------+   +--------------------------+   +-------------+------------+
#   |  6. UW/UDP               |   |  6. UW/UDP               |   |  6. UW/UDP               |
#   +--------------------------+   +--------------------------+   +--------------------------+
#   |  5. UW/FLOODING          |   |  5. UW/FLOODING          |   |  5. UW/FLOODING          |
#   +--------------------------+   +--------------------------+   +--------------------------+
#   |  4. UW/IP                |   |  4. UW/IP                |   |  4. UW/IP                |
#   +--------------------------+   +--------------------------+   +--------------------------+
#   |  3. UW/MLL               |   |  3. UW/MLL               |   |  3. UW/MLL               |
#   +--------------------------+   +--------------------------+   +--------------------------+
#   |  2. UW/CSMA_ALOHA        |   |  2. UW/CSMA_ALOHA        |   |  2. UW/CSMA_ALOHA        |
#   +--------------------------+   +--------------------------+   +--------------------------+
#   |  1. WOSS/BPSK/Underwater |   |  1. WOSS/BPSK/Underwater |   |  1. WOSS/BPSK/Underwater |
#   +--------------------------+   +--------------------------+   +--------------------------+
#            |         |                    |         |                   |         |       
#   +----------------------------------------------------------------------------------------+
#   |                                     UnderwaterChannel                                  |
#   +----------------------------------------------------------------------------------------+

######################################
# Flags to enable or disable options #
######################################
set opt(verbose)            1
# Bash parameters = 1 to usa an externale executable
set opt(bash_parameters)    0
set opt(trace_files)        0

#####################
# Library Loading   #
#####################
load libMiracle.so
load libMiracleBasicMovement.so
load libmphy.so
load libUwmStd.so
load libuwinterference.so
load libuwphy_clmsgs.so
load libuwstats_utilities.so
load libuwphysical.so
load libuwcsmaaloha.so
load libuwip.so
load libuwmll.so
load libuwudp.so
load libuwcbr.so
load libuwflooding.so

#############################
# NS-Miracle initialization #
#############################
# You always need the following two lines to use the NS-Miracle simulator
set ns [new Simulator]
$ns use-Miracle


##################
# Tcl variables  #
##################
set opt(start_clock) [clock seconds]

##################################
# YOU CAN CHANGE NUMBER OF NODES #
##################################
set opt(nn)                 2.0 ; # Number of Nodes
set opt(starttime)          1
set opt(stoptime)           6002
set opt(interrupttime)      60
set opt(txduration)         [expr $opt(stoptime) - $opt(starttime)]
set opt(seedcbr)            0
set opt(memory_slots)       10000

set opt(maxinterval_)       20.0
set opt(freq)               10500.0
# Originally bw=4200.0 & bitrate 4800
set opt(bw)                 4200.0
set opt(bitrate)            4800.0
set opt(ack_mode)           "setAckMode"

# Parameters used to configure the BPSK module of WOSS
set opt(txpower)	    136.0
set opt(per_tgt)	    0.1
set opt(rx_snr_penalty_db)  -10.0
set opt(tx_margin_db)	    10.0

set rng [new RNG]
set rng_position [new RNG]


if {$opt(bash_parameters)} {
    if {$argc != 2} {
        puts "The script requires two inputs:"
        puts "- the first one is the cbr packet size (byte);"
        puts "- the second one is the cbr poisson period (seconds);"
        puts "example: ns uwflooding.tcl 125 60"
        puts "Please try again."
        return
    } else {
        set opt(pktsize)       [lindex $argv 0]
        set opt(cbr_period)    [lindex $argv 1]
        $rng seed              $opt(seedcbr)
    }
} else {
    set opt(pktsize)    125
    set opt(cbr_period) 60
    $rng seed           $opt(seedcbr)
}

set rnd_gen [new RandomVariable/Uniform]
$rnd_gen use-rng $rng

if {$opt(trace_files)} {
    set opt(tracefilename) "./test_uwflooding.tr"
    set opt(tracefile) [open $opt(tracefilename) w]
    set opt(cltracefilename) "./test_uwflooding.cltr"
    set opt(cltracefile) [open $opt(tracefilename) w]
} else {
    set opt(tracefilename) "/dev/null"
    set opt(tracefile) [open $opt(tracefilename) w]
    set opt(cltracefilename) "/dev/null"
    set opt(cltracefile) [open $opt(cltracefilename) w]
}

set channel [new Module/UnderwaterChannel]
set propagation [new MPropagation/Underwater]
set data_mask [new MSpectralMask/Rect]
$data_mask setFreq       $opt(freq)
$data_mask setBandwidth  $opt(bw)

#########################
# Module Configuration  #
#########################
# UW/CBR
Module/UW/CBR set packetSize_          $opt(pktsize)
Module/UW/CBR set period_              $opt(cbr_period)
Module/UW/CBR set PoissonTraffic_      1
Module/UW/CBR set drop_out_of_order_   0

# UW/FLOODING
Module/UW/FLOODING set ttl_                       6
Module/UW/FLOODING set maximum_cache_time__time_  60
Module/UW/FLOODING set optimize_                  1

# CSMA
Module/UW/CSMA_ALOHA set buffer_pkts_    [expr $opt(memory_slots)/$opt(pktsize)];
Module/UW/CSMA_ALOHA set max_tx_tries_   3

# BPSK              
Module/UW/PHYSICAL set debug_                     0
Module/UW/PHYSICAL set BitRate_                   $opt(bitrate)
Module/UW/PHYSICAL set AcquisitionThreshold_dB_   4.0
Module/UW/PHYSICAL set RxSnrPenalty_dB_           $opt(rx_snr_penalty_db)
Module/UW/PHYSICAL set TxSPLMargin_dB_            $opt(tx_margin_db)
Module/UW/PHYSICAL set MaxTxSPL_dB_               $opt(txpower)
Module/UW/PHYSICAL set MinTxSPL_dB_               10
Module/UW/PHYSICAL set MaxTxRange_                50000
Module/UW/PHYSICAL set PER_target_                $opt(per_tgt)
Module/UW/PHYSICAL set CentralFreqOptimization_   0
Module/UW/PHYSICAL set BandwidthOptimization_     0
Module/UW/PHYSICAL set SPLOptimization_           1

################################
# Procedure(s) to create nodes #
################################
proc createNode { id } {

    global channel propagation data_mask ns cbr position node udp portnum ipr ipif channel_estimator
    global phy posdb opt rvposx rvposy rvposz mhrouting mll mac woss_utilities woss_creator db_manager
    global node_coordinates

    set node($id) [$ns create-M_Node $opt(tracefile) $opt(cltracefile)]

    set cbr($id)  [new Module/UW/CBR]
    set udp($id)  [new Module/UW/UDP]
    set ipr($id)  [new Module/UW/FLOODING]
    set ipif($id) [new Module/UW/IP]
    set mll($id)  [new Module/UW/MLL]
    set mac($id)  [new Module/UW/CSMA_ALOHA]
    set phy($id)  [new Module/UW/PHYSICAL]

    $node($id) addModule 7 $cbr($id)   0  "CBR"
    $node($id) addModule 6 $udp($id)   0  "UDP"
    $node($id) addModule 5 $ipr($id)   0  "IPR"
    $node($id) addModule 4 $ipif($id)  0  "IPF"
    $node($id) addModule 3 $mll($id)   0  "MLL"
    $node($id) addModule 2 $mac($id)   0  "MAC"
    $node($id) addModule 1 $phy($id)   0  "PHY"

    $node($id) setConnection $cbr($id)   $udp($id)   0
    $node($id) setConnection $udp($id)   $ipr($id)   0
    $node($id) setConnection $ipr($id)   $ipif($id)  0
    $node($id) setConnection $ipif($id)  $mll($id)   0
    $node($id) setConnection $mll($id)   $mac($id)   0
    $node($id) setConnection $mac($id)   $phy($id)   0
    $node($id) addToChannel  $channel    $phy($id)   0

    set portnum($id) [$udp($id) assignPort $cbr($id) ]
        if {$id > 254} {
            puts "hostnum > 254!!! exiting"
        exit
    }
    set tmp_ [expr ($id) + 1]
    $ipif($id) addr $tmp_
    $ipr($id)  addr $tmp_

    set position($id) [new "Position/BM"]
    $node($id) addPosition $position($id)
    set posdb($id) [new "PlugIn/PositionDB"]
    $node($id) addPlugin $posdb($id) 20 "PDB"
    $posdb($id) addpos [$mac($id) addr] $position($id)

    set interf_data($id) [new "Module/UW/INTERFERENCE"]
    $interf_data($id) set maxinterval_ $opt(maxinterval_)
    $interf_data($id) set debug_       0

    $phy($id) setPropagation $propagation
    $phy($id) setSpectralMask $data_mask
    $phy($id) setInterference $interf_data($id)
    $mac($id) $opt(ack_mode)
    $mac($id) initialize
}

proc createSink { } {

    global channel propagation smask data_mask ns cbr_sink position_sink node_sink udp_sink portnum_sink interf_data_sink
    global phy_data_sink posdb_sink opt mll_sink mac_sink ipr_sink ipif_sink bpsk interf_sink channel_estimator

    set node_sink [$ns create-M_Node $opt(tracefile) $opt(cltracefile)]

    for {set cnt 0} {$cnt < $opt(nn)} {incr cnt} {
        set cbr_sink($cnt)  [new Module/UW/CBR]
    }
    set udp_sink       [new Module/UW/UDP]
    set ipr_sink       [new Module/UW/FLOODING]
    set ipif_sink      [new Module/UW/IP]
    set mll_sink       [new Module/UW/MLL]
    set mac_sink       [new Module/UW/CSMA_ALOHA]
    set phy_data_sink  [new Module/UW/PHYSICAL]

    for { set cnt 0} {$cnt < $opt(nn)} {incr cnt} {
        $node_sink addModule 7 $cbr_sink($cnt) 0 "CBR"
    }
    $node_sink addModule 6 $udp_sink       0 "UDP"
    $node_sink addModule 5 $ipr_sink       0 "IPR"
    $node_sink addModule 4 $ipif_sink      0 "IPF"
    $node_sink addModule 3 $mll_sink       0 "MLL"
    $node_sink addModule 2 $mac_sink       0 "MAC"
    $node_sink addModule 1 $phy_data_sink  0 "PHY"

    for { set cnt 0} {$cnt < $opt(nn)} {incr cnt} {
        $node_sink setConnection $cbr_sink($cnt)  $udp_sink      0
    }
    $node_sink setConnection $udp_sink  $ipr_sink            0
    $node_sink setConnection $ipr_sink  $ipif_sink           0
    $node_sink setConnection $ipif_sink $mll_sink            0
    $node_sink setConnection $mll_sink  $mac_sink            0
    $node_sink setConnection $mac_sink  $phy_data_sink       0
    $node_sink addToChannel  $channel   $phy_data_sink       0

    for { set cnt 0} {$cnt < $opt(nn)} {incr cnt} {
        set portnum_sink($cnt) [$udp_sink assignPort $cbr_sink($cnt)]
        if {$cnt > 252} {
            puts "hostnum > 252!!! exiting"
            exit
        }
    }

    $ipif_sink addr 254
    $ipr_sink addr 254

    set position_sink [new "Position/BM"]
    $node_sink addPosition $position_sink
    set posdb_sink [new "PlugIn/PositionDB"]
    $node_sink addPlugin $posdb_sink 20 "PDB"
    $posdb_sink addpos [$mac_sink addr] $position_sink

    set interf_data_sink [new "Module/UW/INTERFERENCE"]
    $interf_data_sink set maxinterval_ $opt(maxinterval_)
    $interf_data_sink set debug_       0

    $phy_data_sink setSpectralMask $data_mask
    $phy_data_sink setInterference $interf_data_sink
    $phy_data_sink setPropagation $propagation

    $mac_sink $opt(ack_mode)
    $mac_sink initialize
}

#################
# Node Creation #
#################
# Initialize Nodes and Sink
for {set id 0} {$id < $opt(nn)} {incr id}  {
    createNode $id
}
createSink

################################
# Inter-node module connection #
################################
proc connectNodes {id1} {
    global ipif ipr portnum cbr cbr_sink ipif_sink portnum_sink ipr_sink

    $cbr($id1) set destAddr_ [$ipif_sink addr]
    $cbr($id1) set destPort_ $portnum_sink($id1)
    $cbr_sink($id1) set destAddr_ [$ipif($id1) addr]
    $cbr_sink($id1) set destPort_ $portnum($id1)
}

# Setup flows
for {set id1 0} {$id1 < $opt(nn)} {incr id1} {
    connectNodes $id1
}

# Fill ARP tables
for {set id1 0} {$id1 < $opt(nn)} {incr id1} {
    for {set id2 0} {$id2 < $opt(nn)} {incr id2}  {
      $mll($id1) addentry [$ipif($id2) addr] [$mac($id2) addr]
    }
    $mll($id1) addentry [$ipif_sink addr] [ $mac_sink addr]
    $mll_sink addentry [$ipif($id1) addr] [ $mac($id1) addr]
}

# Setup positions
for {set id 0} {$id < $opt(nn)} {incr id} {
    $position($id) setX_ [expr 652*$id]
    $position($id) setY_ 0
    $position($id) setZ_ -9
}

$position_sink setX_ 0
$position_sink setY_ 0
$position_sink setZ_ -9

#####################
# Start/Stop Timers #
#####################
# Set here the timers to start and/or stop modules (optional)
# e.g., 
for {set id1 0} {$id1 < $opt(nn)} {incr id1}  {
    $ns at $opt(starttime)    "$cbr($id1) start"
    $ns at $opt(stoptime)     "$cbr($id1) stop"
}

global id

###################
# Final Procedure #
###################
# Define here the procedure to call at the end of the simulation
proc interrupt {} {
    global ns opt outfile
    global mac propagation cbr_sink mac_sink phy_data phy_data_sink channel db_manager propagation
    global node_coordinates
    global ipr_sink ipr ipif udp cbr phy phy_data_sink
    global node_stats tmp_node_stats sink_stats tmp_sink_stats
    global channel propagation data_mask ns cbr position node udp portnum ipr ipif channel_estimator
    global phy posdb opt rvposx rvposy rvposz mhrouting mll mac woss_utilities woss_creator db_manager
    global node_coordinates
    global id

    puts "---------------------------------------------------------------------"
    puts "Simulation summary"
    puts "number of nodes  : $opt(nn)"
    puts "packet size      : $opt(pktsize) byte"
    puts "cbr period       : $opt(cbr_period) s"
    puts "number of nodes  : $opt(nn)"
    puts "simulation length: $opt(txduration) s"
    puts "tx frequency     : $opt(freq) Hz"
    puts "tx bandwidth     : $opt(bw) Hz"
    puts "bitrate          : $opt(bitrate) bps"
    puts "Node is: $id"
puts "---------------------------------------------------------------------"

    set sum_cbr_throughput     0
    set sum_per                0
    set sum_cbr_sent_pkts      0.0
    set sum_cbr_rcv_pkts       0.0
    set total_energy           0.0
    set sum_ftt                ""
    set sum_fttstd             ""
    set distances              ""
    set sum_ipr_retx           0.0
    set ipr_retx               0
    set first_check_ftt        1
    set first_check_ftt_std    1
    set shipping		0
    set windspeed 		[$propagation set windspeed_]

    set turbolence		[expr 17-30*log10($opt(freq))]
    set turbolence_pow		[expr pow(10.0,($turbolence * 0.1))]
    set ship			[expr 40 + 20 * ($shipping - 0.5) + 26 * log10($opt(freq)) - 60 * log10($opt(freq) + 0.03)]
    set ship_pow		[expr pow(10.0,($ship * 0.1))]
    set wind			[expr 50 + 7.5 * pow($windspeed,0.5) + 20 * log10($opt(freq)) -40 * log10($opt(freq) + 0.4)]
    set wind_pow		[expr pow(10.0,($wind * 0.1))]
    set thermal			[expr -15 + 20 * log10($opt(freq))]
    set thermal_pow		[expr pow(10.0,($thermal * 0.1))]
    set noise			[expr 10 * log10($turbolence_pow + $ship_pow + $wind_pow + $thermal_pow)]
    set attenuation		[expr 10 * log10(0.11*((pow($opt(freq),2))/(1+pow($opt(freq),2)))+44*((pow($opt(freq),2))/(44100+pow($opt(freq),2)))+2.75*(pow(10,-4))*(pow($opt(freq),2))+0.003)]
    set txpower_db		[expr 10 * log10($opt(txpower))]
    set bandwith_db		[expr 10 * log10($opt(bw))]
    set snr			[expr ($txpower_db+$attenuation)-($noise+$bandwith_db)]

    for {set i 0} {$i < $opt(nn)} {incr i}  {
        set cbr_throughput           [$cbr_sink($i) getthr]
        set cbr_sent_pkts        [$cbr($i) getsentpkts]
        set cbr_rcv_pkts           [$cbr_sink($i) getrecvpkts]
        set sum_cbr_throughput [expr $sum_cbr_throughput + $cbr_throughput]
        set sum_cbr_sent_pkts [expr $sum_cbr_sent_pkts + $cbr_sent_pkts]
        set sum_cbr_rcv_pkts  [expr $sum_cbr_rcv_pkts + $cbr_rcv_pkts]
    }

    puts "Node Stats"
    for {set i 0} {$i < $opt(nn)} {incr i}  {
	set cbr_throughput      [$cbr_sink($i) getthr]
        set cbr_sent_pkts       [$cbr($i) getsentpkts]
        set cbr_rcv_pkts        [$cbr_sink($i) getrecvpkts]
        set cbr_per             [$cbr_sink($i) getper]
        set cbr_ftt             [$cbr_sink($i) getftt]
        set cbr_fttstd          [$cbr_sink($i) getfttstd]

        if ($opt(verbose)) {
            puts "node($i) throughput: $cbr_throughput"
            puts "node($i) per:        $cbr_per"
            puts "node($i) sent:       -> $cbr_sent_pkts"
            puts "node($i) received:   <- $cbr_rcv_pkts"
            puts "node($i) ftt:        $cbr_ftt"
            puts "node($i) ftt std:    $cbr_fttstd"
            puts "---------------------------------------"
        }

        if ($first_check_ftt) {
            set sum_ftt "$cbr_ftt"
            set first_check_ftt 0
        } else {
            set sum_ftt "$sum_ftt    $cbr_ftt"
        }

        if ($first_check_ftt_std) {
            set sum_ftt_std "$cbr_fttstd"
            set first_check_ftt_std 0
        } else {
            set sum_ftt_std "$sum_ftt_std    $cbr_fttstd"
        }

        set sum_cbr_throughput [expr $sum_cbr_throughput + $cbr_throughput]
        set sum_cbr_sent_pkts  [expr $sum_cbr_sent_pkts + $cbr_sent_pkts]
        set sum_cbr_rcv_pkts   [expr $sum_cbr_rcv_pkts + $cbr_rcv_pkts]
        set sum_ipr_retx       [expr $sum_ipr_retx + $ipr_retx]
    }

    puts "Metrics"
    puts "Mean Throughput          : [expr (double($sum_cbr_throughput)/($opt(nn)))]"
    puts "Sent Packets             : $sum_cbr_sent_pkts"
    
    ################
    # AMUSE REWARD #
    ################
    puts "Received Packets         : $sum_cbr_rcv_pkts"
    puts "Packet Error Rate        : [expr ((1 - double($sum_cbr_rcv_pkts)/ $sum_cbr_sent_pkts) * 100)]"

    #########################################
    # SYNC WITH AMUSE, MODIFY THE FILE PATH #
    #########################################
    set reader [open "“~/file_path/synchronization.csv"]
    set data_synchro [read $reader]
    close $reader
    set data_synchro [split $data_synchro ","]
    set step [lindex $data_synchro 0]
    set rcv [lindex $data_synchro 1]
    puts "step: $step"
    puts "rcv: $rcv"
    
    #############################
    # CALCULATE THE IMPROVEMENT #
    #############################
    set rcv_temp [expr $sum_cbr_rcv_pkts - $rcv]
    set rcv $sum_cbr_rcv_pkts
    puts "rcv_temp: $rcv_temp"

    #########################################
    # WRITING TO AMUSE MODIFY THE FILE PATH #
    #########################################
    set writer [open "“~/file_path/rewards.csv" w+]
    puts $writer "$step, $rcv_temp, $snr"
    close $writer
    puts "Wrote to rewards.csv: $step, $rcv_temp, $snr"
    after 500

    #######################################################
    # ACCESSING TO AMUSE INSTRUCTION MODIFY THE FILE PATH #
    #######################################################
    while 1 {
    puts "Entering while loop"
    set reader [open "“~/file_path/actions.csv"]
    set data [read $reader]
    close $reader

    ##########################
    # READING THE MODULATION #
    ##########################
    set item [split $data ","]
    set int_step [lindex $item 0]
    set modulation [lindex $item 1]
    puts "int_step is: $int_step, modulation is: $modulation, int_step has to match step: $step"
    if { $int_step == $step } {
    puts "breaking from while loop"
    break}
    after 100
    }

    puts "setting modulation to $modulation"

    ##################################################################################################
    # SETTING THE MODULATION, YOU CAN ADD MORE MODULATION CHOICES IN RELATION TO THE NUMBER OF NODES #
    ##################################################################################################
    if {$modulation == "0"} {
    $phy(0) modulation BPSK
    $phy(1) modulation BPSK
    }
    if {$modulation == "1"} {
    $phy(0) modulation 8PSK
    $phy(1) modulation 8PSK
    }
    if {$modulation == "2"} {
    $phy(0) modulation 16PSK
    $phy(1) modulation 16PSK
    }
    
    #####################################################
    # UPDATING THE SYNCHRONIZATION MODIFY THE FILE PATH #
    #####################################################
    incr step

    puts "Incrementing step: step = $step"
    set writer [open "“~/file_path/synchronization.csv" w+]
    puts $writer "$step, $rcv"
    close $writer
    puts "wrote step: $step, rcv: $rcv to synchronization.csv"
    after 500
}

####################
# START SIMULATION #
####################
for {set i 1} {$i<$opt(stoptime)/$opt(interrupttime)} {incr i} {
$ns at [expr $opt(interrupttime)*$i + 250.0]  "interrupt;"
	#if {$k <= 14} {
	#$propagation set windspeed_ $k at [expr $opt(interrupttime)*$i*100 + 250.0]
	#incr k
	#}
}
$ns run

################################################################
# ASSURING DESERT & AMUSE SYNCHRONIZATION MODIFY THE FILE PATH #
################################################################
while 1 {
    puts "Entering while loop"
    set reader [open "“~/file_path/done.csv"]
    set value [read $reader]
    close $reader

    puts "Value is: $value"
    if { $value == 1 } {
    puts "breaking from while loop"
    break}
    after 100
}