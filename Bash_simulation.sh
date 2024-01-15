#!/bin/bash
for i in {0..15}
	do
		sleep 2
		echo 1, 0 > ~/file_path/synchronization.csv
		ns AMUSE_DESERT_simulation.tcl
	done
