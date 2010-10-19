@echo off
@echo Updating subscribtions...
tortoiseproc /command:update /path:"." /closeonend:3
@echo Calculating checksums:
checksum.pl advblock.txt
@echo * advblock.txt
checksum.pl antinuha.txt
@echo * antinuha.txt
checksum.pl bitblock.txt
@echo * bitblock.txt
checksum.pl cntblock.txt
@echo * cntblock.txt
@echo Commiting changes to server...
tortoiseproc /command:commit /path:"."