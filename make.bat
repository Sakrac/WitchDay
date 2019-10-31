rem Run Convert.bat first to build the assets!

if NOT EXIST obj mkdir obj
if NOT EXIST lst mkdir lst

tools\x65 src\BDoing_Play.s -obj obj\BDoing_Play.x65 -sym obj\BDoing_Play.sym -lst=lst\BDoing_Play.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\input.s -obj obj\input.x65 -lst=lst\input.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\tables.s -obj obj\tables.x65 -lst=lst\tables.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\exodecrunch.s -obj obj\exodecrunch.x65 -lst=lst\exodecrunch.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\animdata.s -obj obj\animdata.x65 -lst=lst\animdata.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\animation.s -obj obj\animation.x65 -lst=lst\animation.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\screens\field.s -obj obj\field.x65 -lst=lst\field.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\screens\witch_house.s -obj obj\witch_house.x65 -lst=lst\witch_house.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\objects.s -obj obj\objects.x65 -lst=lst\objects.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\inventory.s -obj obj\inventory.x65 -lst=lst\inventory.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\actions.s -obj obj\actions.x65 -lst=lst\actions.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\game.s -obj obj\game.x65 -lst=lst\game.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\script.s -obj obj\script.x65 -lst=lst\script.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\text.s -obj obj\text.x65 -lst=lst\text.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\itemselector.s -obj obj\itemselector.x65 -lst=lst\itemselector.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\cauldron.s -obj obj\cauldron.x65 -lst=lst\cauldron.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\screen.s -obj obj\screen.x65 -lst=lst\screen.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\player.s -obj obj\player.x65 -lst=lst\player.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\main.s -obj obj\main.x65 -lst=lst\main.lst
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\link.s witch.prg -sym witch.sym -vice witch.vs -lst=lst\link.lst
if %errorlevel% neq 0 exit /b %errorlevel%
