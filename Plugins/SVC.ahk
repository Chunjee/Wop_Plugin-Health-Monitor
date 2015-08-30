;global ALF := new CustomButton(hWnd)
;ALF.Draw



gui_orginaly := gui_y
gui_y += 20
gui_x = 30
height = 0
SVCTop_Array := []

endboxsize := 100 * .6
SVC_BoxSize := endboxsize
;Read from DVR.txt about what DVRs to monitor
Loop, Read, %A_ScriptDir%\plugins\SVC.txt
{
	;Grab the Name and Url out of each line.
	The_Name := Fn_QuickRegEx(A_LoopReadLine,"Name:(\w+\d+)")
	;Create the SVC Object for each
	If (The_Name != "null") {
		SVC%A_Index% := New SVC(The_Name)
		
		;Create GUI box for each DVR
		Gui, Add, Progress, x%gui_x% y%gui_y% w%endboxsize% h%endboxsize% hWndhWnd, 100
		Gui, Show, w1000 , %The_ProjectName%
		gui_x += endboxsize + 10
		
		if(gui_x >= 870) {
			gui_x = 30
			gui_y += endboxsize + 10
			height += endboxsize + 30
		}
		;Change to a re-drawable gui for the SVC
		SVC%A_Index%.CreateButton(hWnd)
		
		;Add object to array for enumeration
		SVCTop_Array[A_Index] := SVC%A_Index%
	}
}
gui_y += endboxsize

;Draw Box around this plugin
height += endboxsize + 30

Gui, Font, s12 w700, Arial
Gui, Add, GroupBox, x6 y%gui_orginaly% w980 h%height%, SVC
Gui, Font

;Debug options
;Clipboard := Fn_JSONfromOBJ(DVRTop_Array)
;FileAppend, %Alf%, %A_ScriptDir%\HUGE.JSON
;Array_GUI(DVRTop_Array)



SetTimer, CheckSVCs, 2000

;OnMessage(0xF, "WM_PAINT")
;OnMessage(0x200, "WM_MOUSEMOVE")
;OnMessage(0x201, "WM_LBUTTONDOWN")
;OnMessage(0x202, "WM_LBUTTONUP")



Sb_CheckSVCs()
{
	global
	
	CheckSVCs:
	SetTimer, CheckSVCs, -60000
	;global SVCTop_Array
	
	endboxsize := SVC_BoxSize
	
	;Go through the list of SVCs
	Loop, % SVCTop_Array.MaxIndex() {
		
		;Get Status and Statistics of each
		SVC%A_Index%.CheckStatus()
		
		;Parse Status
		SVC%A_Index%.ParseStatus()
		
		;Update GUI Box of each
		SVC%A_Index%.UpdateGUI()
	}
	;Clipboard := Fn_JSONfromOBJ(SVCTop_Array)
	Return
}



Class SVC {
	
	__New(para_Name) {
		
		this.Info_Array := []
		this.Info_Array["Name"] := Fn_QuickRegEx(para_Name,"(\d+)")
		this.Info_Array["URL"] := "http://" . para_Name . "/wschk/"
	}
	
	CreateButton(hWnd) {
		this.GDI := new GDI(hWnd)
		this.hWnd := hWnd
		this.DrawDefault()
	}
	
	UpdateGUI() {
		
		;Update the GUIBox depending on the status
		CombinedText := "`n" . ""
		
		if (this.Info_Array["CurrentStatus"] = "HEALTHY") {
			this.Draw("Healthy" . CombinedText, Fn_RGB("0x009900"), 14) ;Green Online
			Return
		}
		if (this.Info_Array["CurrentStatus"] = "TROUBLE") {
			this.Draw("TROUBLE" . CombinedText, Fn_RGB("0xFF6600"), 14) ;Orange Offline
			Return
		}
		if (this.Info_Array["CurrentStatus"] = "ERROR") {
			CombinedText := "`n" . this.Info_Array["CurrentError"]
			this.Draw("ERROR" . CombinedText, Fn_RGB("0xFF0000"), 14) ;Red Offline
			Return
		}
		;All others failed
		this.Draw(" " . CombinedText, Fn_RGB("0xFFFFFF"), 14) ;White Check Unsuccessful
	}
	
	DrawDefault()
	{
		this.Draw("UnChecked", Fn_RGB("0xFFFFFF"), 18) ;White Unchecked
	}
	
	Draw(para_Text, para_Color, para_TextSize = 18)
	{
		global endboxsize
		TextArray := StrSplit(para_Text,"`n")
		
		critical
		this.GDI.FillRectangle(0, 0, this.GDI.CliWidth, this.GDI.CliHeight, para_Color, "0x000000")
		
		x := 30
		Loop, % TextArray.MaxIndex() {
			If (A_Index = 1) {
				;Always draw first line specifically and with para_TextSize
				this.GDI.DrawText(0, 0, endboxsize, 50, this.Info_Array["Name"], "0x000000", "Times New Roman", 40, "CC")
			}
			;Following lines are drawn generically
			this.GDI.DrawText(0, x, endboxsize, 50, TextArray[A_Index], "0x000000", "Consolas", para_TextSize, "CC")
			x += 26
		}
		this.GDI.BitBlt()
	}
	
	CheckStatus() {		
		;Download Page to memory
		this.Info_Array["HTMLPage"] := Fn_DownloadtoFile(this.Info_Array["URL"])
	}
	
	
	ParseStatus() {
		;Assume SVC is unknown
		this.Info_Array["CurrentStatus"] := "Unknown"
		
		;Put HTML into The_MemoryFile
		The_MemoryFile := this.Info_Array["HTMLPage"]
		
		;Match Healthy
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "\x22Status\x22>(\w+)<")
		if (PageCheck = "HEALTHY") {
			this.Info_Array["CurrentStatus"] := "HEALTHY"
		} Else {
			FileAppend, % "`n" . A_Now . "     -    " . this.Info_Array["HTMLPage"], % A_ScriptDir . "\SVCErrors.txt"
		}

		;Match Unavailable
		PageCheck := Fn_QuickRegEx(The_MemoryFile, ">(Service Unavailable)<")
		if (PageCheck = "Service Unavailable") {
			this.Info_Array["CurrentStatus"] := "TROUBLE"
		}
		;Match any listed error           Error">(.+)<\/span
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "Error\x22>(.+)<\/span")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "ERROR"
			this.Info_Array["CurrentError"] := PageCheck
		}
	}	
}