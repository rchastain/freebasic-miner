
fbc32=/home/roland/Applications/freebasic32/bin/fbc

if [ "${1,,}" == "release" ]
then
$fbc32 -w all ./source/miner.bas -x miner32 -p ./lib/lin32 -d DEBUG
fbc    -w all ./source/miner.bas -x miner64 -p ./lib/lin64 -d DEBUG
else
$fbc32 -w all ./source/miner.bas -x miner32 -p ./lib/lin32 -d DEBUG -exx -g
fbc    -w all ./source/miner.bas -x miner64 -p ./lib/lin64 -d DEBUG -exx -g
fi
