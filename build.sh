
if [ "${1,,}" == "release" ]
then
fbc -w all ./source/miner.bas -x miner64 -p ./lib/lin64 -d DEBUG
else
fbc -w all ./source/miner.bas -x miner64 -p ./lib/lin64 -d DEBUG -exx -g
fi
