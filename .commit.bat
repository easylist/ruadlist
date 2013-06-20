@echo off
@echo Обновление подписок...
hg pull
hg update --check
hg update
hg merge
@echo Разница:
hg diff --nodates
@echo Внесение изменений на сервер...
hg commit
hg push
pause