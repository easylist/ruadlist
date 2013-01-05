@echo off
@echo Обновление подписок...
tortoiseproc /command:update /path:"." /closeonend:3
@echo Расчёт контрольных сумм:
hash.pl advblock.txt
@echo * advblock.txt
hash.pl antinuha.txt
@echo * antinuha.txt
hash.pl bitblock.txt
@echo * bitblock.txt
hash.pl cntblock.txt
@echo * cntblock.txt
@echo Внесение изменений на сервер...
tortoiseproc /command:commit /path:"."
