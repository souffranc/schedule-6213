@echo off
setlocal EnableExtensions
title Расписание 6213

cd /d "%~dp0"

set "PORT=%~1"
if not defined PORT set "PORT=8000"

call :findpython
if not defined PY goto nopython

set /a TRIES=0
:scan
call :portfree %PORT%
if errorlevel 1 goto launch
call :isours %PORT%
if errorlevel 1 goto already
set /a TRIES+=1
if %TRIES% geq 20 goto noport
set /a PORT+=1
goto scan

:launch
start "" /b %PY% -m http.server %PORT% --bind 127.0.0.1
set /a WAIT=0
:waitloop
ping -n 2 127.0.0.1 >nul
call :isours %PORT%
if errorlevel 1 goto started
set /a WAIT+=1
if %WAIT% lss 10 goto waitloop
echo.
echo  Сервер не отвечает на порту %PORT%.
echo  Закройте это окно и попробуйте запустить файл снова.
pause
exit /b 1

:started
start "" "http://127.0.0.1:%PORT%/"
echo.
echo  Расписание 6213 открыто: http://127.0.0.1:%PORT%/
echo  Если браузер не открылся, скопируйте адрес вручную.
echo  Сервер работает, пока открыто это окно.
echo.
pause >nul
exit /b 0

:already
start "" "http://127.0.0.1:%PORT%/"
echo.
echo  Сервер уже запущен: http://127.0.0.1:%PORT%/
echo  Страница открыта в браузере.
echo.
pause >nul
exit /b 0

:noport
echo.
echo  Не удалось найти свободный порт (8000-8019).
echo  Укажите другой порт: start.bat 9000
pause
exit /b 1

:nopython
echo.
echo  Python не найден.
echo  Установите Python 3 с python.org и запустите этот файл снова.
echo  Без сервера страница откроется и через index.html, но установка
echo  на телефон как приложение (PWA) работать не будет.
echo.
pause
exit /b 1

:findpython
set "PY="
where py >nul 2>nul || goto findpython_python
py -c "import http.server" >nul 2>nul || goto findpython_python
set "PY=py"
exit /b

:findpython_python
where python >nul 2>nul || exit /b
python -c "import http.server" >nul 2>nul || exit /b
set "PY=python"
exit /b

:portfree
netstat -an | findstr /c:":%1" | findstr /c:"LISTENING" >nul
if errorlevel 1 exit /b 1
exit /b 0

:isours
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; try { $r = Invoke-WebRequest -UseBasicParsing -TimeoutSec 3 'http://127.0.0.1:%1/index.html'; if ($r.StatusCode -eq 200 -and $r.Content -match 'daysStrip') { exit 1 } } catch {}; exit 0"
exit /b