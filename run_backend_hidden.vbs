Set WshShell = CreateObject("WScript.Shell")
' Run the batch file silently (0 means hidden window)
WshShell.Run chr(34) & "E:\flutter\V2.34\run_backend.bat" & Chr(34), 0
Set WshShell = Nothing
