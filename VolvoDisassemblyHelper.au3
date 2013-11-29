;Originally developed by prj and the community of NefMoto
;Edited to work for Volvo BINs by guitar24t

If WinExists("[TITLE:IDA; CLASS:QWidget]") Then
   WinActivate("[TITLE:IDA; CLASS:QWidget]")
Else
   WinWaitActive("About")
   Send("{ENTER}")
Endif

Sleep(100)

If WinExists("IDA: Quick start") Then
   WinActivate("IDA: Quick start")
   Send("{UP}")
   Sleep(1)
   Send("{ENTER}")
EndIf

#include <GUIConstantsEx.au3>
#include <GUIConstants.au3>
#include <WindowsConstants.au3>

GUICreate("Analysis Toolset", 150, 175, (@DeskTopWidth - 150 - 50))
$loadrbutton = GUICtrlCreateButton("Load BIN", 12, 15, 125, 25)
$startbutton = GUICtrlCreateButton("Start Analysis", 12, 45, 125, 25)
$startcbutton = GUICtrlCreateButton("Start Cleanup", 12, 75, 125, 25)
$stopbutton = GUICtrlCreateButton("Stop All", 12, 105, 125, 25)
$loadbutton = GUICtrlCreateButton("Load .ecu", 12, 135, 125, 25)
GUICtrlSetOnEvent($loadrbutton, "LoadROM")
GUICtrlSetOnEvent($startbutton, "StartAn")
GUICtrlSetOnEvent($stopbutton, "StopAll")
GUICtrlSetOnEvent($startcbutton, "StartClean")
GUICtrlSetOnEvent($loadbutton, "LoadEcu")
GuiSetState(@SW_SHOW)
Opt("GUIOnEventMode", 1)
GUISetOnEvent($GUI_EVENT_CLOSE, "ExitTool")
$analysis = False
$cleanup = False
WinSetOnTop("Analysis", "", 1)

Func LoadROM()
   StopAll()
   WinActivate("[TITLE:IDA; CLASS:QWidget]")
   Send("!fo")
   WinWaitActive("Load a new file")
   Send("{TAB}Siemens C166{ENTER}")
   Sleep(200)
   Send("{ENTER}")
   
   If WinExists("Please confirm") Then
	  WinActivate("Please confirm")
	  Send("{ENTER}")
   EndIf
   
   WinWaitActive("Disassembly memory organization")
   
   Send("{SPACE}") ; create RAM section
   ; RAM start/size
   Send("{TAB}0x300000{SPACE}{TAB}0x10000{SPACE}{TAB}")
   ; ROM start/size
   Send("{TAB}0x0{SPACE}{TAB}0x100000{SPACE}{TAB}")
   ; Load address
   Send("0x0{SPACE}{TAB}{ENTER}")

   WinWaitActive("Choose the device name")
   Send("C167CS{ENTER}")
   Send("{ENTER}")
   
   Sleep(200)
   
   If WinExists("Information") Then
	  WinActivate("Information")
	  Send("{ENTER}")
   EndIf
   
   WinWaitActive("[TITLE:IDA; CLASS:QWidget]")

   ; set up DPPs
   Send("!es")
   Sleep(200)
   Send("u")
   WinWaitActive("Segment Default")
   Send("{UP}{UP}{UP}!a!v4{TAB}{SPACE}{ENTER}")
   Send("!es")
   Sleep(200)
   Send("u")
   WinWaitActive("Segment Default")
   Send("{DOWN}!a!v5{TAB}{SPACE}{ENTER}")
   Send("!es")
   Sleep(200)
   Send("u")
   WinWaitActive("Segment Default")
   Send("{DOWN}!a!vC0{TAB}{SPACE}{ENTER}")
   Send("!es")
   Sleep(200)
   Send("u")
   WinWaitActive("Segment Default")
   Send("{DOWN}!a!v3{TAB}{SPACE}{ENTER}")
   
   WinWaitActive("[TITLE:IDA; CLASS:QWidget]")
   
   Send("g")
   WinWaitActive("Jump")
   Send("0x8000{SPACE}{ENTER}")
   
   MsgBox(0,"Load BIN","Setup completed. Please begin analysis now.")
EndFunc

While True
   Sleep(1000)
   While $analysis
	  Send("pc^u")
	  Sleep(1)

	  If WinExists("Please confirm") Then
	      WinActivate("Please confirm")
	      Send("{ENTER}")
	  Endif
   WEnd
   While $cleanup
	  Send("!hfuy")
	  Sleep(1)
   WEnd
WEnd

Func StartAn()
   StopAll()
   $analysis = True
   WinActivate("[TITLE:IDA; CLASS:QWidget]")
EndFunc

Func StopAll()
   $analysis = False
   $cleanup = False
EndFunc

Func StartClean()
   StopAll()
   $cleanup = True
   WinActivate("[TITLE:IDA; CLASS:QWidget]")
EndFunc

Func LoadEcu()
   StopAll()
   Local $ecufile = FileOpenDialog("Select .ecu file...", @WorkingDir, "ME7Logger ECU files (*.ecu)");
   If Not @error Then
	  WinActivate("[TITLE:IDA; CLASS:QWidget]")
	  Local $openedfile = FileOpen($ecufile)
	  Local $line
	  While $line <> "[Measurements]"
		 $line = FileReadLine($openedfile)
		 if @error = -1 then ExitLoop
	  WEnd

	  AutoItSetOption("SendKeyDelay", 0)
	  While 1
		 $line = FileReadLine($openedfile)
		 If @error = -1 Then ExitLoop
		 If StringLeft($line, 1) = ";" or $line = "" Then
			ContinueLoop
		 EndIf
		 Local $data = StringSplit($line, ",")
		 If (StringStripWS($data[5], 8) = "0x0000") Then
			SetVarName(StringStripWS($data[1], 8), StringStripWS($data[3], 8))
		 EndIf
	  WEnd
	  AutoItSetOption("SendKeyDelay", 5)
	  FileClose($ecufile)
   EndIf
EndFunc

Func SetVarName($name, $addr)
   ControlFocus("IDA", "", "[CLASSNN:TMemo1]");
   Send("MakeNameEx(" & $addr & ", """ & $name & """, 0x01){ENTER}")
EndFunc

Func ExitTool()
   Exit
EndFunc
