@echo off

fbc64 -w all -g -exx -s console source\miner.bas source\miner.rc -x miner64.exe -d DEBUG
fbc32 -w all -g -exx -s console source\miner.bas source\miner.rc -x miner32.exe -d DEBUG

exit /b

fbc32 -help
fbc32 -version
fbc32 -w all -g -exx -s console %1
fbc32 -pp %1
fbc32 -w pedantic %1
fbc32 -exx -s console %1
fbc32 -s console %1 fblogo.rc
fbc32 -s console %1 >> fbc.log 2>&1
fbc32 -gen gcc -r %1
