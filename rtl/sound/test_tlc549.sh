#!/bin/sh

ghdl -a --ieee=synopsys tlc549.vhd 
ghdl -a --ieee=synopsys tlc549_testbench.vhd 
ghdl -r --ieee=synopsys tlc549_testbench --stop-time=10ms --wave=tlc549.ghw

