@echo off
if not "%1"=="am_admin" (powershell start -verb runas '%0' am_admin & exit /b)

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
echo *                                Nextcloud icons have been deleted                                  *
echo *                                                                                                   *
echo *                                       Please report issues                                        *
echo *                       https://github.com/iPwnWolf/Nextcloud-Shell-Overlays/                       *
echo *****************************************************************************************************
echo.

:end
pause
exit