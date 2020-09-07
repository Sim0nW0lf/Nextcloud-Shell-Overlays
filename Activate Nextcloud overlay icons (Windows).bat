@echo off
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)

set Overlays_Pfad=C:\Program Files\Nextcloud\shellext\

REM In case the Overlay.dll name changes, add the new name here, also in :sucheOverlays and in :Overlays_gefunden!
for %%O in ( NCOverlays.dll OCOverlays.dll ) do (
	if exist "%Overlays_Pfad%%%O" (
		set Overlays_Pfad=%Overlays_Pfad%%%O
		call :Overlays_gefunden
	)
)

:sucheOverlays
REM Search in all your disks for Nextcloud Overlays.dll and continue with :Overlays_gefunden
for %%O in ( NCOverlays.dll OCOverlays.dll ) do (
	echo Suche nach %%O auf deinem PC...
	for %%i in ( a b c d e f g h i j k l m n o p q r s t u v w x y z ) do (
		if exist "%%i:\" (
			echo searching on disk %%i:\
			set mainDrive=%%i
			for /f "delims=" %%a in ('dir %%i:\%%O /b/o/s') do set "Overlays_Pfad=%%a" & call :Overlays_gefunden
		)
	)
	echo.
)
echo.
echo ERROR:
echo Nextcloud Overlays.dll was not found on any disk
echo.
echo Please install the Nextcloud Windows Client first, if you didn't do that already
echo Otherwise report your issue on GitHub and I will try to fix it
echo https://github.com/iPwnWolf/Nextcloud-Shell-Overlays/
echo.
call :end

:Overlays_gefunden
REM check which Nextcloud Overlays.dll will be installed and set the corresponding Registry entries
echo %Overlays_Pfad%|find "NCOverlays.dll"
if errorlevel 1 (
	REM not found
) else (
	set Error=NextcloudError
	set OK=NextcloudOK
	set OKShared=NextcloudOKShared
	set Sync=NextcloudSync
	set Warning=NextcloudWarning
)
echo %Overlays_Pfad% |find "OCOverlays.dll"
if errorlevel 1 (
	REM not found
) else (
	set Error=OCError
	set OK=OCOK
	set OKShared=OCOKShared
	set Sync=OCSync
	set Warning=OCWarning
)

REM Delete all NC Keys, also old ones (OC Keys and Nextcloud Keys (Function checked for conflicting overlay identifiers: https://en.wikipedia.org/wiki/List_of_shell_icon_overlay_identifiers)
for /f "delims=" %%k in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers /f "" /k') do (
	REM the Key OKShared is included with the Key OK
	for %%v in ( NextcloudError NextcloudOK NextcloudSync NextcloudWarning OCError OCOK OCSync OCWarning ) do (
		REM if a NC Key is found, it will be deleted
		echo %%~nk|find "%%v" >nul
		if errorlevel 1 (
			REM Error or OK or OKShared or Sync or Warning not found
		) else (
			if exist "%%k" do (
				reg delete "%%k" /f
			)
		)
	)
)

REM execute Overlays.dll with admin privileges --> Write NCOverlay Keys in Registry
regsvr32.exe "%Overlays_Pfad%" /s

echo Push NC Keys on Top
for /f "delims=" %%x in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers /f "" /k') do (
	
	REM check if all NC keys are on top
	setlocal enableextensions enabledelayedexpansion
		set /A counter=0
		set /A found=0
	for /f "delims=" %%C in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers /f "" /k') do if not defined _CorrectBreak (
		echo %%~nC|find "%Error%"
		if errorlevel 1 (
			REM nothing to do (%Error% not found)
		) else (
			set /A found+=1
		)
		echo %%~nC|find "%OK%"
		if errorlevel 1 (
			REM nothing to do
		) else (
			echo  %%~nC|find "%OKShared%"
			if errorlevel 1 (
				set /A found+=1
			) else (
				REM nothing to do
			)
		)
		echo %%~nC|find "%OKShared%"
		if errorlevel 1 (
			REM nothing to do
		) else (
			set /A found+=1
		)
		echo %%~nC|find "%Sync%"
		if errorlevel 1 (
			REM nothing to do
		) else (
			set /A found+=1
		)
		echo %%~nC|find "%Warning%"
		if errorlevel 1 (
			REM nothing to do
		) else (
			set /A found+=1
		)
		set /A counter+=1
		if !counter! EQU 5 (
			set _CorrectBreak=now
		)
	)
	if !found! EQU !counter! (
		REM All Nextcloud Keys are on top
		call :delete_remaining_Keys
	) else (
		REM call :push_Nextcloud_Keys
	)
	endlocal


	REM Put spaces in front of NC Keys and check again if the keys are on top of the list now
	for %%N in ( %Error% %OK% %OKShared% %Sync% %Warning% ) do (
	set _NextBreak=
	set _KeyBreak=
		for /f "delims=" %%k in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers /f "" /k') do if not defined _NextBreak (
			REM If the first Reg Key is not %Error%, spaces will be put in front of every NC Key
			echo %%~nk|find "%%N" >nul
			if errorlevel 1 (
				for /f "delims=" %%E in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers /f "%%N" /k') do if not defined _KeyBreak (
					REG COPY "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\  %%N" "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers\   %%~nE" /s /f
					REM Loop Beenden
					set _KeyBreak=now
					set _NextBreak=now
				)
			) else (
				set _NextBreak=now
			)
		)
	)
)


:delete_remaining_Keys
echo delete remaining extra registry keys
REM Skip the NC Keys which are on top, delete the rest
for /f "skip=6 delims=" %%k in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers /f "" /k') do (
	for %%v in ( %Error% %OK% %Sync% %Warning% ) do (
		REM If an Overlay Key from Nextcloud is found, it will be deleted
		echo %%~nk|find "%%v" >nul
		if errorlevel 1 (
			REM %Error% oder %OK% oder %OKShared% oder %Sync% oder %Warning% nicht gefunden
		) else (
			if exist "%%k" do (
				reg delete "%%k" /f
			)
		)
	)
)

REM Optionally disable OneDrive notification
:OneDriveNotifications
set OneDriveNotify=HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Notifications\Settings\Microsoft.SkyDrive.Desktop
cls
echo.
echo OneDrive will regularely inform you, that their icons must be updated.
echo That will undo what this script has done.
echo.
CHOICE /C YN /M "Do you want to disable OneDrive notifications now"
IF ERRORLEVEL ==2 GOTO refresh
IF ERRORLEVEL ==1 GOTO YES

:YES
echo OneDriveNotify: %OneDriveNotify%
if exist "%OneDriveNotify%" do (
	REG ADD %OneDriveNotify% /v Enabled /t REG_DWORD /d 0 /f
)

:refresh
REM Restart Explorer
taskkill /f /im explorer.exe
start explorer.exe

cls
echo.
echo *****************************************************************************************************
echo *                                                                                                   *
echo *                                                                                                   *
echo *                                             FINISHED                                              *
echo *                              Nextcloud icons should be visible now                                *
echo *                                                                                                   *
echo *                                       Please report issues                                        *
echo *                       https://github.com/iPwnWolf/Nextcloud-Shell-Overlays/                       *
echo *****************************************************************************************************
echo.

:end
pause
exit
