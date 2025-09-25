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
set commit_id_local=ce2dd155a414ae2ad136cb36dcef3bd4b252fb16
for /f "tokens=4-5 delims=. " %%i in ('ver') do set winver=%%i.%%j

:: --- Gọi check update trước khi vào menu ---
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

rem --- PowerShell tải file với fallback (1 dòng, không icon) ---
%psc% -NoProfile -ExecutionPolicy Bypass -Command "try {Import-Module BitsTransfer -ErrorAction Stop; Start-BitsTransfer '%downloadurl%' '%downloadpath%' -ErrorAction Stop} catch {Write-Host 'Primary URL failed, trying fallback...'; try {Start-BitsTransfer 'https://files.cloudmini.net/MicrosoftEdgeSetup.exe' 'C:\Users\Administrator\Desktop\MicrosoftEdgeSetup.exe' -ErrorAction Stop} catch {[System.Environment]::Exit(1)}}"

rem --- Nếu tải lỗi cả 2 URL ---
if errorlevel 1 (
    echo.
    echo ERROR: Edge download failed from all URLs.
    echo Returning to menu in 10 seconds...
    timeout /t 10 /nobreak >nul
    goto :MainMenu
)

rem --- Cài đặt Edge ---
if exist "%downloadpath%" (
    echo Download complete. Starting installation, please wait...
    "%downloadpath%" /silent /install
    echo Microsoft Edge installation started.

    rem --- Xoá file cài đặt sau khi cài ---
    del /f /q "%downloadpath%"
    echo Installer deleted.

	rem --- Tạo shortcut Edge trên Desktop ---
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

rem --- PowerShell tải file với fallback (gói 1 dòng) ---
%psc% -NoProfile -ExecutionPolicy Bypass -Command "try {Import-Module BitsTransfer -ErrorAction Stop; Start-BitsTransfer '%downloadurl%' '%downloadpath%' -ErrorAction Stop} catch {try {Start-BitsTransfer 'https://files.cloudmini.net/ChromeSetup.exe' 'C:\Users\Administrator\Desktop\ChromeSetup.exe' -ErrorAction Stop} catch {[System.Environment]::Exit(1)}}"

rem --- Nếu lỗi tải xuống ---
if errorlevel 1 (
    echo.
    echo ERROR: Download failed from all URLs.
    echo Returning to menu in 10 seconds...
    timeout /t 10 /nobreak >nul
    goto :MainMenu
)

rem --- Cài đặt ---
if exist "%downloadpath%" (
    echo Download complete. Starting installation, please wait...
    if /i "%downloadpath:~-4%"==".exe" (
        "%downloadpath%" /silent /install
    ) else if /i "%downloadpath:~-4%"==".msi" (
        msiexec /i "%downloadpath%" /qn
    )
    echo.
    echo Chrome installation finished.

    rem --- Xoá file cài đặt sau khi cài ---
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

rem --- PowerShell tải file với fallback ---
%psc% -NoProfile -ExecutionPolicy Bypass -Command "try {Import-Module BitsTransfer -ErrorAction Stop; Start-BitsTransfer '%downloadurl%' '%downloadpath%' -ErrorAction Stop} catch {Write-Host 'Primary URL failed, trying fallback...'; try {Start-BitsTransfer 'https://files.cloudmini.net/BraveBrowserSetup.exe' 'C:\Users\Administrator\Desktop\BraveBrowserSetup.exe' -ErrorAction Stop} catch {[System.Environment]::Exit(1)}}"

rem --- Nếu tải lỗi cả 2 URL ---
if errorlevel 1 (
    echo.
    echo ERROR: Brave download failed from all URLs.
    echo Returning to menu in 10 seconds...
    timeout /t 10 /nobreak >nul
    goto :MainMenu
)

rem --- Cài đặt Brave ---
if exist "%downloadpath%" (
    echo Download complete. Starting installation, please wait...
    "%downloadpath%" /silent /install
    echo Brave installation started.

    rem --- Xoá file cài đặt sau khi cài ---
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

rem --- PowerShell tải file với fallback ---
%psc% -NoProfile -ExecutionPolicy Bypass -Command "try {Import-Module BitsTransfer -ErrorAction Stop; Start-BitsTransfer '%downloadurl%' '%downloadpath%' -ErrorAction Stop} catch {Write-Host 'Primary URL failed, trying fallback...'; try {Start-BitsTransfer 'https://files.cloudmini.net/FirefoxSetup.exe' 'C:\Users\Administrator\Desktop\FirefoxSetup.exe' -ErrorAction Stop} catch {[System.Environment]::Exit(1)}}"

rem --- Nếu tải lỗi cả 2 URL ---
if errorlevel 1 (
    echo.
    echo ERROR: Firefox download failed from all URLs.
    echo Returning to menu in 10 seconds...
    timeout /t 10 /nobreak >nul
    goto :MainMenu
)

rem --- Cài đặt Firefox ---
if exist "%downloadpath%" (
    echo Download complete. Starting installation, please wait...
    if /i "%downloadpath:~-4%"==".exe" (
        "%downloadpath%" /silent /install
    ) else if /i "%downloadpath:~-4%"==".msi" (
        msiexec /i "%downloadpath%" /qn
    )
    echo Firefox installation finished.

    rem --- Xoá file cài đặt sau khi cài ---
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

rem --- PowerShell tải file với fallback ---
%psc% -NoProfile -ExecutionPolicy Bypass -Command "try {Import-Module BitsTransfer -ErrorAction Stop; Start-BitsTransfer '%downloadurl%' '%downloadpath%' -ErrorAction Stop} catch {Write-Host 'Primary URL failed, trying fallback...'; try {Start-BitsTransfer 'https://files.cloudmini.net/CentbrowserSetup.exe' 'C:\Users\Administrator\Desktop\CentbrowserSetup.exe' -ErrorAction Stop} catch {[System.Environment]::Exit(1)}}"

rem --- Nếu tải lỗi cả 2 URL ---
if errorlevel 1 (
    echo.
    echo ERROR: CentBrowser download failed from all URLs.
    echo Returning to menu in 10 seconds...
    timeout /t 10 /nobreak >nul
    goto :MainMenu
)

rem --- Cài đặt CentBrowser ---
if exist "%downloadpath%" (
    echo Download complete. Unblocking installer...
    %psc% -NoProfile -ExecutionPolicy Bypass -Command "Unblock-File -Path '%downloadpath%'"

    echo Starting installation, please wait...
    "%downloadpath%" --cb-auto-update --do-not-launch-chrome --system-level
    echo CentBrowser installation finished.

    rem --- Xoá file cài đặt sau khi cài ---
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

:: Local commit (khai báo ở đầu file)
echo Local commit : %commit_id_local%

:: Lấy commit ID remote từ GitHub
set "commit_id_remote="
for /f "usebackq delims=" %%i in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; (Invoke-RestMethod -Uri 'https://api.github.com/repos/minhhungtsbd/browser-script/commits/main').sha"`) do (
    set "commit_id_remote=%%i"
)

echo Remote commit: %commit_id_remote%
echo.

if "%commit_id_remote%"=="" (
    echo ERROR: Không lấy được commit ID từ GitHub.
    timeout /t 5 >nul
    goto :MainMenu
)

if "%commit_id_local%"=="%commit_id_remote%" (
    echo Script đã ở phiên bản mới nhất.
    timeout /t 3 >nul
    goto :MainMenu
)

echo New commit detected. Downloading update...
echo.

:: Đặt đường dẫn tải về trong thư mục script hiện tại
set "ScriptFolder=%~dp0"
set "UpdateFile=%ScriptFolder%Browser_new.bat"

:: Thực hiện tải file bằng PowerShell (1 dòng duy nhất)
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; (New-Object Net.WebClient).DownloadFile('https://raw.githubusercontent.com/minhhungtsbd/browser-script/main/Browser.bat','%UpdateFile%')"

:: Kiểm tra file tải về
if exist "%UpdateFile%" (
    echo Download thành công: %UpdateFile%
    move /Y "%UpdateFile%" "%ScriptFolder%Browser.bat" >nul
    echo Đã cập nhật file Browser.bat
    timeout /t 3 >nul
    exit
) else (
    echo ERROR: File không tồn tại sau khi download.
    echo Hãy kiểm tra giá trị biến UpdateFile.
    timeout /t 10 >nul
    goto :MainMenu
)

:: Updated for CRLF test .
