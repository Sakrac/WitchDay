if NOT EXIST bin mkdir bin

tools\gfx -texthires Assets\gamelayout.png -out=bin\gamelayout -bg=15
if %errorlevel% neq 0 exit /b %errorlevel%

tools\gfx -texthires Assets\witchhouse.png -out=bin\witchhouse -bg=15
if %errorlevel% neq 0 exit /b %errorlevel%

tools\fontconv assets\WitchDayFont.png bin\WitchDayFont.bin bin\WitchDayFont.wid 68
tools\x65 src\fontdata.s bin\fontdata.prg
if %errorlevel% neq 0 exit /b %errorlevel%
tools\exomizer mem -q bin\fontdata.prg -o bin\fontdata.exo

tools\gfx -columns assets\InventoryAssets.png bin\InventoryAssets.bin 15 12 1x16
if %errorlevel% neq 0 exit /b %errorlevel%


tools\gfx -columns assets\walk.png bin\walk.bin 15 5 2x21
if %errorlevel% neq 0 exit /b %errorlevel%
tools\gfx -columns assets\dance.png bin\dance.bin 15 3 2x21
if %errorlevel% neq 0 exit /b %errorlevel%
tools\gfx -columns assets\cauldron.png bin\cauldron.bin 15 2 2x21
if %errorlevel% neq 0 exit /b %errorlevel%
tools\gfx -columns assets\boy_sad.png bin\boy_sad.bin 15 1 1x15
if %errorlevel% neq 0 exit /b %errorlevel%
tools\gfx -columns assets\bull_idle.png bin\bull_idle.bin 15 2 3x21
if %errorlevel% neq 0 exit /b %errorlevel%
tools\gfx -columns assets\apple.png bin\apple.bin 15 1 1x8
if %errorlevel% neq 0 exit /b %errorlevel%
tools\gfx -columns assets\cursor.png bin\cursor.bin 15 1 1x21
if %errorlevel% neq 0 exit /b %errorlevel%

tools\x65 src\screens\field_screen.s bin\field_screen.prg
if %errorlevel% neq 0 exit /b %errorlevel%
tools\exomizer mem -q bin\field_screen.prg -o bin\field_screen.exo

tools\x65 src\screens\witch_house_screen.s bin\witch_house_screen.prg
if %errorlevel% neq 0 exit /b %errorlevel%
tools\exomizer mem -q bin\witch_house_screen.prg -o bin\witch_house_screen.exo

