
fbc32=/home/roland/Applications/freebasic32/bin/fbc

if [ -e $fbc32 ]
then
if [ "${1,,}" == "release" ]
then
$fbc32 -w all ./source/miner.bas -x miner32 -p ./lib/lin32 -d DEBUG
else
$fbc32 -w all ./source/miner.bas -x miner32 -p ./lib/lin32 -d DEBUG -exx -g
fi
else
  echo "Cannot find $fbc32"
fi
