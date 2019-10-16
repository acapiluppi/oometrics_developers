#!/bin/bash
for i in  `awk -F',' '{print $3}' results_Forks.csv`; do grep ",$i," results_Forks.csv | tr -d "\n" && printf "," && grep "$i," ALL_SLOCs.txt | awk -F',' '{print $2}'; done
