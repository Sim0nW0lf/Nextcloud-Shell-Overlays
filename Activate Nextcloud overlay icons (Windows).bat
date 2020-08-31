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
REM Suche in allen mîglichen Festplatten nach Nextclouds Overlays.dll und springe zu :Overlays_gefunden
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
echo Nextclouds Overlays.dll wurde auf keinem Laufwerk gefunden.
echo.
echo Falls Nextcloud noch nicht installiert ist, tun Sie das bitte zuerst.
echo Ansonsten wenden Sie sich bitte an Simon Wolf fÅr weiteren Support.
echo.
call :end

:Overlays_gefunden
REM check which Nextcloud Overlay.dlls was installed and set the corresponting Registry entries
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

REM Alle existierenden Nextcloud Reg Keys lîschen, egal ob OC... oder Nextcloud... es wird nur nach Error, Ok, ... gesucht! (Auf Konflikte geprÅft https://en.wikipedia.org/wiki/List_of_shell_icon_overlay_identifiers)
for /f "delims=" %%k in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers /f "" /k') do (
	for %%v in ( Error OK Sync Warning ) do (
		REM Wenn ein Overlay Key von Nextcloud gefunden wird, wird er gelîscht
		echo %%~nk|find "%%v" >nul
		if errorlevel 1 (
			REM Error oder OK oder OKShared oder Sync oder Warning nicht gefunden
		) else (
			if exist "%%k" do (
				reg delete "%%k" /f
			)
		)
	)
)

REM Overlays.dll ausfÅhren als Admin --> Overlay Keys in Registry schreiben
regsvr32.exe "%Overlays_Pfad%" /s

echo Nextcloud Overlay Keys nach oben pushen
for /f "delims=" %%x in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers /f "" /k') do (
	
	REM kontrollieren ob alle Keys oben sind
	setlocal enableextensions enabledelayedexpansion
		set /A counter=0
		set /A found=0
	for /f "delims=" %%C in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers /f "" /k') do if not defined _CorrectBreak (
		echo %%~nC|find "%Error%"
		if errorlevel 1 (
			REM nothing to do
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
		REM Alle Nextcloud Keys sind ganz oben
		call :delete_remaining_Keys
	) else (
		REM call :push_Nextcloud_Keys
	)
	endlocal


	REM 3 Leerzeichen vor Nextcloud Keys machen, dann wieder kontrollieren ob jetzt alle oben sind
	for %%N in ( %Error% %OK% %OKShared% %Sync% %Warning% ) do (
	set _NextBreak=
	set _KeyBreak=
		for /f "delims=" %%k in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers /f "" /k') do if not defined _NextBreak (
			REM Wenn die erste Zeile nicht %Error% ist, wird ein Leerzeichen hinzugefÅgt
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
echo öberflÅssige Keys lîschen
for /f "skip=6 delims=" %%k in ('reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\ShellIconOverlayIdentifiers /f "" /k') do (
	for %%v in ( %Error% %OK% %Sync% %Warning% ) do (
		REM Wenn ein Overlay Key von Nextcloud gefunden wird, wird er gelîscht
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

REM Explorer neu starten
taskkill /f /im explorer.exe
start explorer.exe

cls
echo.
echo *****************************************************************************************************
echo *                                                                                                   *
echo *                                                                                                   *
echo *                                             FERTIG                                                *
echo *                      Jetzt sollten die Symbole von Nextcloud da sein                              *
echo *                                                                                                   *
echo *                                                                                                   *
echo *               Falls nicht, einfach an Simon Wolf wenden, fÅr weiteren Support.                    *
echo *****************************************************************************************************
echo.

:end
pause
exit