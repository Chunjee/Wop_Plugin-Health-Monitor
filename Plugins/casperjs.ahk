TxtFile = %A_WorkingDir%\plugins\casperjs.txt
IfExist, % TxtFile
{
	PluginActive_Bool := True
} else {
	PluginActive_Bool := False
}

If (PluginActive_Bool) {
	gui_orginaly := gui_y
	gui_y += 20
	gui_x = 30
	height = 0
	AutoWagerTop_Array := []

	endboxsize := 100 * 0.5
	AutoWager_BoxSize := endboxsize
	;Read from AutoWager.txt about what AutoWagers to monitor
	Loop, Read, % TxtFile
	{
		if (InStr(A_LoopReadLine,";")) {
			Continue
		}

		;Create the AutoWager Object for each
		Name := Fn_QuickRegEx(A_LoopReadLine,"Name:(\w+)")
		URL := Fn_QuickRegEx(A_LoopReadLine,"URL:([\w+\.\/\\]+)")


		;Create the Object for each
		AutoWager%A_Index% := New AutoWager(Name,Type,URL)
			
			;Add new line if max ammount of boxes reached
			if (gui_x >= 10) {
				gui_x = 30
				gui_y += endboxsize + 10
				height += endboxsize + 30
			}

			;Create GUI box for each
			Gui, Add, Progress, x%gui_x% y%gui_y% w%endboxsize% h%endboxsize% hWndhWnd, 100
			Gui, Show, w1000 , %The_ProjectName%
			gui_x += endboxsize + 10
			
			;Change to a re-drawable gui for the Site
			AutoWager%A_Index%.CreateButton(hWnd)
			
			;Add object to array for enumeration
			AutoWagerTop_Array[A_Index] := AutoWager%A_Index%
	}

	gui_y += endboxsize + 20

	;Draw Box around this plugin
	height += endboxsize + 40
	Gui, Font, s12 w700, Arial
	Gui, Add, GroupBox, x6 y%gui_orginaly% w980 h%height%, AutoWager
	Gui, Font


	SetTimer, CheckAutoWagers, -2000
}




;Plugin functions and classes-------------------------------





Sb_CheckAutoWagers()
{
	global
	CheckAutoWagers:	
	endboxsize := AutoWager_BoxSize
	
	;Update the status and stats of each AutoWager
	Loop, % AutoWagerTop_Array.MaxIndex() {
		;Get Status and Statistics of each AutoWager 
		AutoWager%A_Index%.Run()
		
		;Figure out the results
		AutoWager%A_Index%.ParseResults()
		
		;Update GUI Box of each AutoWager
		AutoWager%A_Index%.UpdateGUI()

		;Report any errors
		if (AutoWager%A_Index%.ErrorCheck()) {
			Fn_ErrorCount(1)
		}
	}
	SetTimer, CheckAutoWagers, -60000
	Return
}



Class AutoWager {
	
	__New(para_Name,para_Type,para_Location) {
		this.Info_Array := []
		this.Info_Array["Name"] := para_Name
		this.Info_Array["Type"] := para_Type
		this.Info_Array["endpoint"] := para_Location

		this.AVGArray := []
	}
	
	CreateButton(hWnd) {
		this.GDI := new GDI(hWnd)
		this.hWnd := hWnd
		this.DrawDefault()
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
		Sleep, -1 ; Let the scrollbar redraw before painting over it
		this.GDI.FillRectangle(0, 0, this.GDI.CliWidth, this.GDI.CliHeight, para_Color, "0x000000")
		
		x := 30
		Loop, % TextArray.MaxIndex() {
			if (A_Index = 1) {
				;Always draw first line specifically and with para_TextSize
				this.GDI.DrawText(0, 0, endboxsize, 50, this.Info_Array["Name"], "0x000000", "Times New Roman", 40, "CC")
			}
			;Following lines are drawn generically
			this.GDI.DrawText(0, x, endboxsize, 50, TextArray[A_Index], "0x000000", "Consolas", para_TextSize, "CC")
			x += 26
		}
		this.GDI.BitBlt()
	}
	
	Run() {
		;Clean up png files first
		Loop, Files, % A_ScriptDir "\*.png*"
		{
			FileDelete, % A_LoopFileFullPath
		}
		this.Info_Array[A_Index,"RAWSTATUS"] := Fn_RunCasperjs()
		Msgbox, % this.Info_Array[A_Index,"RAWSTATUS"]

		
	}

	ParseResults() {

		;Understand cases of no repsonse or timeout as 0
		if (this.Info_Array["Time"] = "-1" || this.Info_Array["Time"] = "") {
			this.Info_Array["Time"] := 0
		}

		;Add latest ping to AVGArray
		this.AVGArray.Push(this.Info_Array["Time"])
	}
	
	
	UpdateGUI() {
		
		;Update the GUIBox depending on the status of the AutoWager
		ResponseTime := this.Info_Array["ResponseAVG"]
		CombinedText := this.Info_Array["IP"] . "`nDelay:" . this.Info_Array["ResponseAVG"]

		;Draw box depending on response time of the site
		if (ResponseTime = "-1" || ResponseTime = "") {
			this.Draw("NO REPLY " . CombinedText, Fn_RGB("0xCC0000"), 30) ;RED
			Return
		}

		if (ResponseTime < 60) {
			this.Draw(CombinedText, Fn_RGB("0x009900"), 20) ;Green
			Return
		}
		if (ResponseTime < 200) {
			this.Draw(CombinedText, Fn_RGB("0x669900"), 20) ;Light-Green
			Return
		}
		if (ResponseTime < 600) {
			this.Draw(CombinedText, Fn_RGB("0xFF9900"), 20) ;Orange
			Return
		}
		if (ResponseTime <= 1600) {
			this.Draw(CombinedText, Fn_RGB("0xFF6600"), 20) ;Dark-Orange
			Return
		}
		if (ResponseTime > 1600) {
			this.Draw(CombinedText, Fn_RGB("0xCC0000"), 30) ;RED
			Return
		}
		this.Draw("???" . CombinedText, Fn_RGB("0xFFFFFF"), 30) ;White check unsuccessful	
	}

	ErrorCheck() {
		if (this.Info_Array["CurrentStatus"] != "Online") {
			Return 1
		}
	}
}



Fn_RunCasperjs() { ;returns StdOut
	;Open cmd.exe with echoing of commands disabled
	shell := ComObjCreate("WScript.Shell")
	
	;Send the commands to execute, separated by newline
	exec := shell.Exec(ComSpec " /Q echo off")
	commands := " casperjs " . A_ScriptDir . "\Plugins\AutoWager.js"
	
	;Always exit at the end!
	exec.StdIn.WriteLine(commands "`nexit")  
	
	;Read and return the output of all commands
	return % exec.StdOut.ReadAll()
}