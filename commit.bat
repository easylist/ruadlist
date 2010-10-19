@echo off
@echo Обновление подписок...
tortoiseproc /command:update /path:"." /closeonend:3
@echo Расчёт контрольных сумм:
checksum.pl advblock.txt
@echo * advblock.txt
checksum.pl antinuha.txt
@echo * antinuha.txt
checksum.pl bitblock.txt
@echo * bitblock.txt
checksum.pl cntblock.txt
@echo * cntblock.txt
@echo Внесение изменений на сервер...
tortoiseproc /command:commit /path:"."