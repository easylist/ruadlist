@echo off
@echo Обновление подписок...
hg pull
hg update --check
hg update
hg merge
@echo Расчёт контрольных сумм:
hash.pl advblock.txt
@echo * advblock.txt
hash.pl antinuha.txt
@echo * antinuha.txt
hash.pl bitblock.txt
@echo * bitblock.txt
hash.pl cntblock.txt
@echo * cntblock.txt
@echo Разница:
hg diff -U0 --nodates
@echo Внесение изменений на сервер...
hg commit
hg push
pause