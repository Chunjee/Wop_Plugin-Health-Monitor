;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;Description
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/
; Monitors several TVG systems
; 

;Hide CMD window
DllCall("AllocConsole")
WinHide % "ahk_id " DllCall("GetConsoleWindow", "ptr")

;~~~~~~~~~~~~~~~~~~~~~
;Compile Options
;~~~~~~~~~~~~~~~~~~~~~
SetBatchLines -1 ;Go as fast as CPU will allow
#NoTrayIcon ;No tray icon
#SingleInstance Force ;Do not allow running more then one instance at a time
ComObjError(False) ; Ignore any http timeouts

The_ProjectName := "TVG Argus"
The_VersionName = v1.1.0

;Dependencies
#Include %A_ScriptDir%\Functions
#Include inireadwrite.ahk
#Include class_GDI.ahk
#Include util_misc.ahk
#Include util_json.ahk
;#Include ping.ahk
#Include ping4.ahk
#Include internet_fileread.ahk

;For Debug Only
#Include util_arrays.ahk

Sb_InstallFiles() ;Install Included Files
Sb_RemoteShutDown() ;Allows for remote shutdown

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;StartUp
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

GUI_x := 24
GUI_y := 50
;; Create GUI based off plugins
#Include %A_ScriptDir%\Plugins
#Include DVR.ahk
#Include Sites.ahk
#Include Sites2.ahk
#Include Speed.ahk
#Include UptimeRobot.ahk
#Include Services.ahk
#Include SVC.ahk

;GUI_x += 50 ;Box
;GUI_y += 50 ;Text


;;Show GUI if all creation was successful
GUI_Build()
if(A_IsCompiled) {
	Gui +AlwaysOnTop
}

;Actual End. All processes are handled in plugins
Return

;does nothing
Update:
Return

;/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\
;Misc Functions
;\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/--\--/

Fn_UpdateProgressBar(para_ProgressBarVar,para_Max,para_Current,para_Index,para_ColorThreshold) {
	If (para_Current = para_Max)
	{
		Return %para_Current%
	}
	
	If (para_Max > para_Current)
	{
		para_Current += 1
	}
	If (para_Max < para_Current)
	{
		para_Current += -1
	}
	
	l_Color := Fn_Percent2Color(para_Current, para_ColorThreshold)
	GuiControl,+c%l_Color%, %para_ProgressBarVar%%para_Index%, ;Change the color
	GuiControl,, %para_ProgressBarVar%%para_Index%, %para_Current% ;Change the progressbar percentage
	
	Return %para_Current%
}


Fn_PercentCheck(para_Input) {
	;Checks to ensure that the input var is not under 1 or over 100, essentially for percentages
	para_Input := Ceil(para_Input)
	If (para_Input >= 100)
	{
		Return 100
	}
	If (para_Input <= 0)
	{
		Return 1
	}
	Return %para_Input%
}


Fn_Percent2Color(para_InputNumber,para_ThresholdPercent) {
	;Returns a color code for progress bar percentages. Kinda reverse order because otherwise it will return the first encountered Return
	
	If (para_InputNumber <= para_ThresholdPercent) ;Green
	{
		Return "22b14c"
	}
	If (para_InputNumber > para_ThresholdPercent + 20) ;Red
	{
		Return "ed1c24"
	}
	If (para_InputNumber > para_ThresholdPercent + 18) {
		Return "ff3627"
	}
	If (para_InputNumber > para_ThresholdPercent + 18) {
		Return "ff3b27"
	}
	If (para_InputNumber > para_ThresholdPercent + 18) {
		Return "ff4027"
	}
	If (para_InputNumber > para_ThresholdPercent + 17) {
		Return "ff5027"
	}
	If (para_InputNumber > para_ThresholdPercent + 16) {
		Return "ff5f27"
	}
	If (para_InputNumber > para_ThresholdPercent + 15) {
		Return "ff6427"
	}
	If (para_InputNumber > para_ThresholdPercent + 14) {
		Return "ff6927"
	}
	If (para_InputNumber > para_ThresholdPercent + 13) {
		Return "ff6e27"
	}
	If (para_InputNumber > para_ThresholdPercent + 12) {
		Return "ff7327"
	}
	If (para_InputNumber > para_ThresholdPercent + 11) {
		Return "ff7827"
	}
	If (para_InputNumber > para_ThresholdPercent + 10) ;Orange
	{
		Return "ff7f27"
	}
	If (para_InputNumber > para_ThresholdPercent + 9) {
		Return "ff8827"
	}
	If (para_InputNumber > para_ThresholdPercent + 8) {
		Return "ff9727"
	}
	If (para_InputNumber > para_ThresholdPercent + 7) {
		Return "ffa127"
	}
	If (para_InputNumber > para_ThresholdPercent + 6) {
		Return "ffab27"
	}
	If (para_InputNumber > para_ThresholdPercent + 5) {
		Return "ffb027"
	}
	If (para_InputNumber > para_ThresholdPercent + 4) {
		Return "ffbf27"
	}
	If (para_InputNumber > para_ThresholdPercent + 3) {
		Return "ffbc04"
	}
	If (para_InputNumber > para_ThresholdPercent + 2) {
		Return "ffbe03"
	}
	If (para_InputNumber > para_ThresholdPercent + 1) {
		Return "ffc002"
	}
	If (para_InputNumber > para_ThresholdPercent) { ;Yellow
		Return "ffc300"
	}
	If (para_InputNumber > para_ThresholdPercent - 1) {
		Return "cabf12"
	}
	If (para_InputNumber > para_ThresholdPercent - 2) {
		Return "99bb23"
	}
	If (para_InputNumber > para_ThresholdPercent - 3) {
		Return "6db732"
	}
	
	Return ERROR
}


Fn_Percent2ColorLight(para_InputNumber,para_ThresholdPercent) {
	;Same as the other function but has lighter colors
	
	If (para_InputNumber <= para_ThresholdPercent) ;Green
	{
		Return "a3edb9"
	}
	If (para_InputNumber > para_ThresholdPercent + 20) ;Red
	{
		Return "f7999d"
	}
	If (para_InputNumber > para_ThresholdPercent + 10) ;Orange
	{
		Return "ffbd91"
	}
	If (para_InputNumber > para_ThresholdPercent) ;Yellow
	{
		Return "fff991"
	}
	
	Return ERROR
}


Fn_ConvertSecondstoMili(para_Seconds) {
	RegExMatch(para_Seconds, "(\d+)", RE_Match)
	If (RE_Match1 != "")
	{
		Return % RE_Match1 * 1000
	}
	Return
}


Fn_ErrorCount(para_input) {
static ErrorCounter
	if (para_input = "report") {
		;check if there are any errors to report
		if (ErrorCounter > 0) {
			;play an error sound if one exists
			ErrorFile := A_ScriptDir . "\Data\Assets\error.mp3"
			if (FileExist(ErrorFile)) {
				SoundPlay, % ErrorFile
			}

			;send post/get if there are errors to report
			static Base := "http://wogutilityd01/api/wallboarderror"
			l_XHR := ComObjCreate("WinHttp.WinHttpRequest.5.1")
			l_XHR.Open("POST", Base, False) ;do not wait for reply
			l_XHR.Send()

			ErrorCounter := 0
			return
		}
	}
	;set Counter to 0 if not set
	if (ErrorCounter = "") {
		ErrorCounter := 0
	}
	if (Abs(para_input) > 0) { ;only true when number is entered and bigger than 0
		ErrorCounter += para_input
	}
}


UriEncode(Uri) {
	VarSetCapacity(Var, StrPut(Uri, "UTF-8"), 0), StrPut(Uri, &Var, "UTF-8")
	f := A_FormatInteger
	SetFormat, IntegerFast, H
	While Code := NumGet(Var, A_Index - 1, "UChar")
		If (Code >= 0x30 && Code <= 0x39 ; 0-9
			|| Code >= 0x41 && Code <= 0x5A ; A-Z
	|| Code >= 0x61 && Code <= 0x7A) ; a-z
	Res .= Chr(Code)
	Else
		Res .= "%" . SubStr(Code + 0x100, -1)
	SetFormat, IntegerFast, %f%
	Return, Res
}


Fn_DataFileInfoTime(para_File) {
	l_FileModified := 
	
	;Do normal filesize checking if the file exists
	IfExist, %para_File%
	{
		FileGetTime, l_FileModified, %para_File%, M
		If (l_FileModified != "")
		{
			FormatTime, l_FileModified, %l_FileModified%, h:mm
			Return %l_FileModified%
		}
	}
	
	Return "ERROR"
}

Fn_SeparateArguments(para_Arguments) {
Arguemnts_Array := []

}

;/--\--/--\--/--\--/--\--/--\
; Subroutines
;\--/--\--/--\--/--\--/--\--/


Sb_GlobalNameSpace() {
	
}


Sb_InstallFiles() {
	FileCreateDir, %A_ScriptDir%\Data\Temp\
}

Sb_EmailOps() {
	;Currently Does nothing
}


GUI_Build() {
	global
	
	;GUI Always on top variable
	;GUI_AOT := 1
	;Gui +AlwaysOnTop
	
	;Title
	Gui, Font, s14 w70, Arial
	Gui, Add, Text, x300 y4 w300 h40 +Center, %The_ProjectName%
	Gui, Font, s10 w70, Arial
	Gui, Add, Text, x946 y0 w50 h20 +Right, %The_VersionName%
	
	;Menu
	Menu, FileMenu, Add, &Update Now, Update
	Menu, FileMenu, Add, Window &Always Top, SwitchOnOff
	Menu, FileMenu, Add, R&estart`tCtrl+R, Menu_File-Restart
	Menu, FileMenu, Add, E&xit`tCtrl+Q, Menu_File-Exit
	Menu, MyMenuBar, Add, &File, :FileMenu  ; Attach the sub-menu that was created above
	Menu, FileMenu, Check, Window &Always Top
	;Menu, Default , FileMenu
	
	Menu, HelpMenu, Add, &About, Menu_About
	Menu, HelpMenu, Add, &Confluence`tCtrl+H, Menu_Confluence
	Menu, MyMenuBar, Add, &Help, :HelpMenu
	Gui, Menu, MyMenuBar
	
	;Create the final size of the GUI
	;h%GUI_y% w330
	Gui, Show, h%gui_y% w1000 , %The_ProjectName%
	Return
	
	;Menu Shortcuts
	Menu_Confluence:
	Run http://confluence.tvg.com/
	Return
	
	Menu_About:
	Msgbox, Monitors many things in a plugin format
	Return
	
	SwitchOnOff:
	If (GUI_AOT = 0)
	{
		Gui +AlwaysOnTop
		GUI_AOT := 1
		Menu, FileMenu, Check, Window &Always Top
	}
	else
	{
		Gui -AlwaysOnTop
		GUI_AOT := 0
		Menu, FileMenu, UnCheck, Window &Always Top
	}
	Gui, submit, NoHide
	Return
	
	Menu_File-Restart:
	Reload
	Menu_File-Exit:
	ExitApp
	GuiClose:
	ExitApp, 1
}
