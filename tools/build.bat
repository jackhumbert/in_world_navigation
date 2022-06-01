if not exist "build" mkdir build
xcopy /y /d /s resources\packed\* build\
if not exist "build\r6\scripts" mkdir build\r6\scripts
xcopy /y /d /s src\redscript\* build\r6\scripts\
if not exist "build\red4ext" mkdir build\red4ext
if not exist "build\red4ext\plugins" mkdir build\red4ext\plugins
if not exist "build\red4ext\plugins\in_world_navigation" mkdir build\red4ext\plugins\in_world_navigation