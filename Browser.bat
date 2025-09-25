@set masver=3.0
@setlocal DisableDelayedExpansion
@echo off

::============================================================================
::   Cloudmini Windows Browser Installer Tool
::============================================================================

cls
color 07
title  Cloudmini tool

set winbuild=1
set psc=powershell.exe
set commit_id_local=2ca6eddfc88f84e3b08e7f57630a06a7834b19bc
for /f "tokens=4-5 delims=. " %%i in ('ver') do set winver=%%i.%%j

:: --- Call to check for updates before entering the menu. ---
goto :CheckUpdate

::========================================================================================================================================
:MainMenu
cls
color 07
title  Windows Browser Installer %masver%
mode 76, 30

echo:
echo:       ______________________________________________________________
echo:
echo:                 Windows Browser Installation Tool:
echo:                     Windows version: %winver%
echo:
echo:             [1] Change VPS password (random)
echo:             [2] Install Microsoft Edge
echo:             [3] Install Google Chrome
echo:             [4] Install Brave
echo:             [5] Install Firefox
echo:             [6] Install CentBrowser
echo:             [7] Change RDP port
echo:            
echo:             __________________________________________________      
echo:
echo:             [0] Exit
echo:       ______________________________________________________________
echo:
choice /C:123456780 /N
set _erl=%errorlevel%

if %_erl%==9 exit /b
if %_erl%==7 setlocal & call :Changeportrdp   & endlocal & goto :MainMenu
if %_erl%==6 setlocal & call :Centbrowser     & endlocal & goto :MainMenu
if %_erl%==5 setlocal & call :Firefox         & endlocal & goto :MainMenu
if %_erl%==4 setlocal & call :Brave           & endlocal & goto :MainMenu
if %_erl%==3 setlocal & call :Chrome          & endlocal & goto :MainMenu
if %_erl%==2 setlocal & call :MicrosoftEdge   & endlocal & goto :MainMenu
if %_erl%==1 setlocal & call :Changepasswords & endlocal & goto :MainMenu
goto :MainMenu

::========================================================================================================================================
:Changeportrdp
echo -- Enter the port number or Press enter for default 3389
set /p rdp_port="Change RDP port to 1024-49151:"
if "%rdp_port%" EQU "" set rdp_port=3389
echo - Changing RDP port to: %rdp_port%
reg add "hklm\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" /v "PortNumber" /t REG_DWORD /d %rdp_port% /f
netsh advfirewall firewall add rule name="RDP Port %rdp_port%" profile=any protocol=TCP action=allow dir=in localport=%rdp_port%
timeout 5
net stop termservice /yes
net start termservice
echo ---------- Done, changed RDP port successfully...
pause
goto :MainMenu

::========================================================================================================================================
:Changepasswords
setlocal ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
set alfanum=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
set pwd=
FOR /L %%b IN (0, 1, 7) DO (
  SET /A rnd_num=!RANDOM! * 62 / 32768 + 1
  for /F %%c in ('echo %%alfanum:~!rnd_num!^,1%%') do set pwd=!pwd!%%c
)
net user %USERNAME% "VPS-%pwd%"
echo User name: %USERNAME%  Password: VPS-%pwd% > C:\Users\Administrator\Desktop\PassWords.txt
Start notepad "C:\Users\Administrator\Desktop\PassWords.txt"
goto :MainMenu

::========================================================================================================================================
:MicrosoftEdge
cls
echo ==========================================================
echo   Installing Microsoft Edge...
echo   Detected Windows version: %winver%
echo ==========================================================

set "downloadpath=C:\Users\Administrator\Desktop\MicrosoftEdgeSetup.exe"

if "%winver%"=="6.3" (
    set "downloadurl=https://archive.org/download/browser_02.05.2022/Browser/MicrosoftEdgeSetup.exe"
)
if "%winver%"=="10.0" (
    set "downloadurl=https://archive.org/download/browser_02.05.2022/19092025/MicrosoftEdgeSetup.exe"
)
if "%downloadurl%"=="" (
    set "downloadurl=https://archive.org/download/browser_02.05.2022/19092025/MicrosoftEdgeSetup.exe"
)

%psc% -NoProfile -ExecutionPolicy Bypass -Command "try {Import-Module BitsTransfer -ErrorAction Stop; Start-BitsTransfer '%downloadurl%' '%downloadpath%' -ErrorAction Stop} catch {Write-Host 'Primary URL failed, trying fallback...'; try {Start-BitsTransfer 'https://files.cloudmini.net/MicrosoftEdgeSetup.exe' 'C:\Users\Administrator\Desktop\MicrosoftEdgeSetup.exe' -ErrorAction Stop} catch {[System.Environment]::Exit(1)}}"

rem --- If both URLs fail to load ---
if errorlevel 1 (
    echo.
    echo ERROR: Edge download failed from all URLs.
    echo Returning to menu in 10 seconds...
    timeout /t 10 /nobreak >nul
    goto :MainMenu
)

rem --- Install Edge ---
if exist "%downloadpath%" (
    echo Download complete. Starting installation, please wait...
    "%downloadpath%" /silent /install
    echo Microsoft Edge installation started.

    rem --- Delete the installation file after installation ---
    del /f /q "%downloadpath%"
    echo Installer deleted.

	rem --- Create Edge shortcut on Desktop ---
	if "%winver%"=="6.3" (
		%psc% -NoProfile -ExecutionPolicy Bypass -Command " $WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut([Environment]::GetFolderPath('Desktop') + '\Microsoft Edge.lnk'); $Shortcut.TargetPath = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'; $Shortcut.IconLocation = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe,0'; $Shortcut.Save() "
	)
	echo Shortcut created on Desktop.
) else (
    echo ERROR: Edge installer not found after download.
)

echo Returning to menu in 3 seconds...
timeout /t 3 /nobreak >nul
goto :MainMenu

::========================================================================================================================================
:Chrome
cls
echo ==========================================================
echo   Installing Google Chrome...
echo   Detected Windows version: %winver%
echo ==========================================================

set "downloadpath=C:\Users\Administrator\Desktop\ChromeSetup.msi"

if "%winver%"=="6.3" (
    set "downloadurl=https://archive.org/download/browser_02.05.2022/Browser/ChromeSetup.exe"
    set "downloadpath=C:\Users\Administrator\Desktop\ChromeSetup.exe"
)
if "%winver%"=="10.0" (
    set "downloadurl=https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
    set "downloadpath=C:\Users\Administrator\Desktop\ChromeSetup.msi"
)
if "%downloadurl%"=="" (
    set "downloadurl=https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi"
)

rem --- PowerShell download file with fallback ---
%psc% -NoProfile -ExecutionPolicy Bypass -Command "try {Import-Module BitsTransfer -ErrorAction Stop; Start-BitsTransfer '%downloadurl%' '%downloadpath%' -ErrorAction Stop} catch {try {Start-BitsTransfer 'https://files.cloudmini.net/ChromeSetup.exe' 'C:\Users\Administrator\Desktop\ChromeSetup.exe' -ErrorAction Stop} catch {[System.Environment]::Exit(1)}}"

rem --- If there is a download error---
if errorlevel 1 (
    echo.
    echo ERROR: Download failed from all URLs.
    echo Returning to menu in 10 seconds...
    timeout /t 10 /nobreak >nul
    goto :MainMenu
)

rem --- Starting installation ---
if exist "%downloadpath%" (
    echo Download complete. Starting installation, please wait...
    if /i "%downloadpath:~-4%"==".exe" (
        "%downloadpath%" /silent /install
    ) else if /i "%downloadpath:~-4%"==".msi" (
        msiexec /i "%downloadpath%" /qn
    )
    echo.
    echo Chrome installation finished.

    rem --- Delete the installation file after installation. ---
    del /f /q "%downloadpath%"
    echo Installer deleted.
) else (
    echo ERROR: Chrome installer not found after download.
)

echo Returning to menu in 3 seconds...
timeout /t 3 /nobreak >nul
goto :MainMenu
::========================================================================================================================================
:Brave
cls
echo ==========================================================
echo   Installing Brave Browser...
echo   Detected Windows version: %winver%
echo ==========================================================

set "downloadpath=C:\Users\Administrator\Desktop\BraveBrowserSetup.exe"

if "%winver%"=="6.3" (
    set "downloadurl=https://archive.org/download/browser_02.05.2022/19092025/BraveBrowserSetup.exe"
)
if "%winver%"=="10.0" (
    set "downloadurl=https://laptop-updates.brave.com/latest/winx64"
)
if "%downloadurl%"=="" (
    set "downloadurl=https://referrals.brave.com/latest/BraveBrowserSetup.exe"
)

rem --- PowerShell download file with fallback ---
%psc% -NoProfile -ExecutionPolicy Bypass -Command "try {Import-Module BitsTransfer -ErrorAction Stop; Start-BitsTransfer '%downloadurl%' '%downloadpath%' -ErrorAction Stop} catch {Write-Host 'Primary URL failed, trying fallback...'; try {Start-BitsTransfer 'https://files.cloudmini.net/BraveBrowserSetup.exe' 'C:\Users\Administrator\Desktop\BraveBrowserSetup.exe' -ErrorAction Stop} catch {[System.Environment]::Exit(1)}}"

rem --- If both URLs fail to load ---
if errorlevel 1 (
    echo.
    echo ERROR: Brave download failed from all URLs.
    echo Returning to menu in 10 seconds...
    timeout /t 10 /nobreak >nul
    goto :MainMenu
)

rem --- Install Brave ---
if exist "%downloadpath%" (
    echo Download complete. Starting installation, please wait...
    "%downloadpath%" /silent /install
    echo Brave installation started.

    rem --- Delete the installation file after installation. ---
    del /f /q "%downloadpath%"
    echo Installer deleted.
) else (
    echo ERROR: Brave installer not found after download.
)

echo Returning to menu in 3 seconds...
timeout /t 3 /nobreak >nul
goto :MainMenu

::========================================================================================================================================
:Firefox
cls
echo ==========================================================
echo   Installing Mozilla Firefox...
echo   Detected Windows version: %winver%
echo ==========================================================

set "downloadpath=C:\Users\Administrator\Desktop\FirefoxSetup.exe"

if "%winver%"=="6.3" (
    set "downloadurl=https://download.mozilla.org/?product=firefox-esr115-latest-ssl&os=win64&lang=en-US"
)
if "%winver%"=="10.0" (
    set "downloadurl=https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
)
if "%downloadurl%"=="" (
    set "downloadurl=https://download.mozilla.org/?product=firefox-latest&os=win64&lang=en-US"
)

rem --- PowerShell download file with fallback ---
%psc% -NoProfile -ExecutionPolicy Bypass -Command "try {Import-Module BitsTransfer -ErrorAction Stop; Start-BitsTransfer '%downloadurl%' '%downloadpath%' -ErrorAction Stop} catch {Write-Host 'Primary URL failed, trying fallback...'; try {Start-BitsTransfer 'https://files.cloudmini.net/FirefoxSetup.exe' 'C:\Users\Administrator\Desktop\FirefoxSetup.exe' -ErrorAction Stop} catch {[System.Environment]::Exit(1)}}"

rem --- If both URLs fail to load ---
if errorlevel 1 (
    echo.
    echo ERROR: Firefox download failed from all URLs.
    echo Returning to menu in 10 seconds...
    timeout /t 10 /nobreak >nul
    goto :MainMenu
)

rem --- Install Firefox ---
if exist "%downloadpath%" (
    echo Download complete. Starting installation, please wait...
    if /i "%downloadpath:~-4%"==".exe" (
        "%downloadpath%" /silent /install
    ) else if /i "%downloadpath:~-4%"==".msi" (
        msiexec /i "%downloadpath%" /qn
    )
    echo Firefox installation finished.

    rem --- Delete the installation file after installation. ---
    del /f /q "%downloadpath%"
    echo Installer deleted.
) else (
    echo ERROR: Firefox installer not found after download.
)

echo Returning to menu in 3 seconds...
timeout /t 3 /nobreak >nul
goto :MainMenu

::========================================================================================================================================
:Centbrowser
cls
echo ==========================================================
echo   Installing CentBrowser...
echo   Detected Windows version: %winver%
echo ==========================================================

set "downloadpath=C:\Users\Administrator\Desktop\CentbrowserSetup.exe"

if "%winver%"=="6.3" (
    set "downloadurl=https://static.centbrowser.com/win_stable/5.2.1168.83/centbrowser_5.2.1168.83_x64.exe"
)
if "%winver%"=="10.0" (
    set "downloadurl=https://static.centbrowser.com/win_stable/5.2.1168.83/centbrowser_5.2.1168.83_x64.exe"
)
if "%downloadurl%"=="" (
    set "downloadurl=https://static.centbrowser.com/win_stable/5.2.1168.83/centbrowser_5.2.1168.83_x64.exe"
)

rem --- PowerShell download file with fallback ---
%psc% -NoProfile -ExecutionPolicy Bypass -Command "try {Import-Module BitsTransfer -ErrorAction Stop; Start-BitsTransfer '%downloadurl%' '%downloadpath%' -ErrorAction Stop} catch {Write-Host 'Primary URL failed, trying fallback...'; try {Start-BitsTransfer 'https://files.cloudmini.net/CentbrowserSetup.exe' 'C:\Users\Administrator\Desktop\CentbrowserSetup.exe' -ErrorAction Stop} catch {[System.Environment]::Exit(1)}}"

rem --- If both URLs fail to load ---
if errorlevel 1 (
    echo.
    echo ERROR: CentBrowser download failed from all URLs.
    echo Returning to menu in 10 seconds...
    timeout /t 10 /nobreak >nul
    goto :MainMenu
)

rem --- Install CentBrowser ---
if exist "%downloadpath%" (
    echo Download complete. Unblocking installer...
    %psc% -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -Path '%downloadpath%'"

    echo Starting installation, please wait...
    "%downloadpath%" --cb-auto-update --do-not-launch-chrome --system-level
    echo CentBrowser installation finished.

    rem --- Delete the installation file after installation. ---
    del /f /q "%downloadpath%"
    echo Installer deleted.
) else (
    echo ERROR: CentBrowser installer not found after download.
)

echo Returning to menu in 3 seconds...
timeout /t 3 /nobreak >nul
goto :MainMenu
::========================================================================================================================================
:CheckUpdate
echo Checking for updates...
echo.
timeout /t 3 >nul

:: Clean up old helper files if any remain.
set "HelperFile=%~dp0UpdateHelper.bat"
echo Checking: %HelperFile%
if exist "%HelperFile%" (
    echo Found UpdateHelper.bat
    del /f /q "%HelperFile%" >nul 2>&1
    if exist "%HelperFile%" (
        echo Delete FAILED.
    ) else (
        echo Delete SUCCESS.
    )
) else (
    echo UpdateHelper.bat not found.
)
timeout /t 3 >nul

:: Local commit
echo Local commit : %commit_id_local%

:: Get remote commit ID from GitHub
set "commit_id_remote="
for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { (Invoke-RestMethod -Uri 'https://api.github.com/repos/minhhungtsbd/browser-script/commits/main').sha } catch { '' }"`) do (
    set "commit_id_remote=%%i"
)

echo Remote commit: %commit_id_remote%
echo.

if "%commit_id_remote%"=="" (
    echo ERROR: Unable to get commit ID from GitHub.
    timeout /t 3 >nul
    goto :MainMenu
)

if /I "%commit_id_local%"=="%commit_id_remote%" (
    echo The script is already at the latest version.
    timeout /t 2 >nul
    goto :MainMenu
)

echo New commit detected. Downloading update...
echo.

:: Paths
set "ScriptFolder=%~dp0"
set "UpdateFile=%ScriptFolder%Browser_new.bat"
set "UpdateHelper=%ScriptFolder%UpdateHelper.bat"

:: Clean old
if exist "%UpdateFile%" del /f /q "%UpdateFile%" >nul 2>&1
if exist "%UpdateHelper%" del /f /q "%UpdateHelper%" >nul 2>&1

:: 1. Download new file
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { [Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/minhhungtsbd/browser-script/main/Browser.bat','%UpdateFile%') } catch { exit 1 }"
timeout /t 1 >nul
if errorlevel 1 (
    echo ERROR: Download failed.
    timeout /t 3 >nul
    goto :MainMenu
)

if not exist "%UpdateFile%" (
    echo ERROR: Update file missing after download.
    timeout /t 3 >nul
    goto :MainMenu
)
echo Download complete.

:: 2. Normalize line endings + ASCII
powershell -NoProfile -ExecutionPolicy Bypass -Command "$text = Get-Content -Raw -Encoding UTF8 '%UpdateFile%' -ErrorAction Stop; $text = $text -replace \"`r?`n\", \"`r`n\"; Set-Content -Path '%UpdateFile%' -Value $text -Encoding ASCII"
echo Normalize complete.

:: 3. Update commit_id_local
powershell -NoProfile -ExecutionPolicy Bypass -Command "$commit='%commit_id_remote%'; $content = Get-Content '%UpdateFile%'; $replacement = 'set commit_id_local=' + $commit; $updated = $content -replace 'set commit_id_local=.*', $replacement; Set-Content -Path '%UpdateFile%' -Value $updated -Encoding ASCII"
echo Commit ID injected.

:: 4. Generate UpdateHelper.bat
echo @echo off > "%UpdateHelper%"
echo timeout /t 2 ^>nul >> "%UpdateHelper%"
echo move /Y "%%~dp0Browser_new.bat" "%%~dp0Browser.bat" ^>nul >> "%UpdateHelper%"
echo cmd /c start "" "%%~dp0Browser.bat" >> "%UpdateHelper%"
echo exit >> "%UpdateHelper%"

echo UpdateHelper.bat created.

:: 5. Call UpdateHelper to do replacement and restart
echo Launching UpdateHelper...
start "" "%UpdateHelper%"
exit
