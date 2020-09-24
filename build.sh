
#fbc -help > help.txt
#fbc -version > version.txt
#fbc -exx ./source/miner.bas -x fbm64

fbc32=/home/roland/Applications/freebasic32/bin/fbc
$fbc32 -exx -w all ./source/miner.bas -x miner32 -p ./lib/lin32 -d DEBUG

fbc -exx -w all ./source/miner.bas -x miner64 -p ./lib/lin64 -d DEBUG
