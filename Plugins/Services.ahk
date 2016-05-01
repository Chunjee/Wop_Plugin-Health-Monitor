TxtFile = %A_ScriptDir%\plugins\Services.txt
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
	ServicesTop_Array := []


	endboxsize := 100 * 1.4
	Services_BoxSize := endboxsize
	;Read from DVR.txt about what DVRs to monitor
	Loop, Read, % TxtFile
	{
		If(InStr(A_LoopReadLine,";")) {
			Continue
		}
		UserDefined_SystemType := Fn_QuickRegEx(A_LoopReadLine,"(.+)")


		;Add new line if max ammount of boxes reached
			if (gui_x >= 870) {
				gui_x = 30
				gui_y += endboxsize + 10
				height += endboxsize + 30
			}

		;Create GUI box for each Type
		Gui, Add, Progress, x%gui_x% y%gui_y% w%endboxsize% h%endboxsize% hWndhWnd, 100
		Gui, Show, w1000 , %The_ProjectName%
		gui_x += endboxsize + 10

		ServicesObj%A_Index% := New Services_Class(UserDefined_SystemType)
		
		;Change to a re-drawable gui for the DVR
		ServicesObj%A_Index%.CreateButton(hWnd)
		
		;Add object to array for enumeration
		ServicesTop_Array[A_Index] := ServicesObj%A_Index%
		
		;Might be needed later if we want clickable buttons
		;DVRButton%A_Index% := New CustomButton(hWnd)
	}
	gui_y += endboxsize + 20

	;Draw Box around this plugin
	height += endboxsize + 40
	Gui, Font, s12 w700, Arial
	Gui, Add, GroupBox, x6 y%gui_orginaly% w980 h%height%, Services
	Gui, Font


	SetTimer, CheckServices, 2000
}



SB_CheckServices()
{
	global
	CheckServices:
	SetTimer, CheckServices, -60000
	
	endboxsize := Services_BoxSize
	
	;Update the status and stats of each
	Loop, % ServicesTop_Array.MaxIndex() {
		
		;Get Status and Statistics of each
		ServicesObj%A_Index%.CheckStatus()
		
		;Update GUI Box of each
		ServicesObj%A_Index%.UpdateGUI()

		;Report any errors
		if (ServicesObj%A_Index%.ErrorCheck()) {
			Fn_ErrorCount(1)
		}
	}
	;Clipboard := Fn_JSONfromOBJ(ServicesTop_Array)
	Return
}



Class Services_Class {
	
	__New(para_Name) {
		this.Info_Array := []
		this.Label := para_Name
		X = 0
		Loop, Read, %A_ScriptDir%\plugins\services\%para_Name%.txt
		{
			If (InStr(A_LoopReadLine,";")) {
				Continue
			}
			If (A_Index = 1) {
				this.Services_Array := StrSplit(Fn_QuickRegEx(A_LoopReadLine,"(.+)"),",")

				;Remove any blanks
				Loop, % this.Services_Array.MaxIndex() {
					If (this.Services_Array[A_Index] = "" || this.Services_Array[A_Index] = " ") {
						this.Services_Array.RemoveAt(A_Index)
					}
				}
				Continue
			}
			X++
			If (StrLen(A_LoopReadLine) > 5) {
				this.Info_Array[X,"Name"] := Fn_QuickRegEx(A_LoopReadLine,"(.+)")
				this.Info_Array[X,"CurrentStatus"] := "UnChecked"	
			}
			
		}

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
	
	Draw(para_Text, para_Color, para_TextSize1 = 30, para_TextSize2 = 10)
	{
		global endboxsize
		TextArray := StrSplit(para_Text,"`n")
		
		critical
		this.GDI.FillRectangle(0, 0, this.GDI.CliWidth, this.GDI.CliHeight, para_Color, "0x000000")
		
		x := 30
		Loop, % TextArray.MaxIndex() {
			if (A_Index = 1) {
				;Always draw first line specifically and with para_TextSize1
				this.GDI.DrawText(0, 0, endboxsize, 50, TextArray[A_Index], "0x000000", "Times New Roman", para_TextSize1, "CC")
				Continue
			}
			;Following lines are drawn generically
			this.GDI.DrawText(0, x, endboxsize, 50, TextArray[A_Index], "0x000000", "Consolas", para_TextSize2, "CC")
			x += %para_TextSize2%
		}
		this.GDI.BitBlt()
	}
	

	CheckStatus() {
		X = 0
		Y = 0
		this.ErrorMessage := ""
		this.TotalRunning := 0
		Loop, % this.Info_Array.MaxIndex() {
			X++
			Loop, % this.Services_Array.MaxIndex() {
				Y++

				;;Get the service status
				this.Info_Array[X,"RAWSTATUS"] := Fn_QueryService(this.Info_Array[X,"Name"],this.Services_Array[A_Index])
				;msgbox, % this.Info_Array[X,"RAWSTATUS"]

				;;Parse the raw status
				this.Info_Array[X,"Status"] := Fn_ParseServiceResponse(this.Info_Array[X,"RAWSTATUS"])

				;;Convert the status to a human readable string
				this.Info_Array[X,"Status_HumanReadable"] := Fn_ServiceResponseHumanReadable(this.Info_Array[X,"Status"])
				;msgbox, % this.Info_Array[X,"Status"] . "  -  " this.Info_Array[X,"Status_HumanReadable"]

				If (this.Info_Array[X,"Status"] != "4") { ;If not running
					this.ErrorMessage := "Check " . this.Services_Array[A_Index] . " on " . this.Info_Array[X,"Name"] . ": " . this.Info_Array[X,"Status_HumanReadable"]
				} Else {
					this.TotalRunning += 1
				}
			}
		}
		this.TotalCheckedServices := Y
		;msgbox, % this.ErrorMessage
	}
	
	
	UpdateGUI() {
		
		;Update the GUIBox depending on the status of the Services
		;Orange 0xFF6600

		;Cut up error message into sizes that will fit
		this.ErrorMessage := RegexReplace(this.ErrorMessage, ".{23}\K", "`n")


		CombinedText := "`n" this.Services_Array[1] "`n" this.TotalRunning "/" this.TotalCheckedServices "`n" this.ErrorMessage

		;Understand the 
		this.HealthStatus := this.TotalRunning / this.TotalCheckedServices
		;msgbox, % this.HealthStatus
		If (this.HealthStatus = 1) {
			this.Draw(this.Label . "`n" this.TotalRunning "/" this.TotalCheckedServices " Running", Fn_RGB("0x009900"), 30, 20) ;Green
		}
		If (this.HealthStatus <= .99) {
			this.Draw(this.Label . "`nDegraded!" . CombinedText, Fn_RGB("0x669900"), 30, 12) ;Light Green
		}
		If (this.HealthStatus <= .90) {
			this.Draw(this.Label . "`nDegraded!" . CombinedText, Fn_RGB("0xFFCC00"), 30, 12) ;Light Orange
		}
		If (this.HealthStatus <= .75) {
			this.Draw(this.Label . "`nDegraded!" . CombinedText, Fn_RGB("0xFF6600"), 30, 12) ;Orange
		}
		If (this.HealthStatus <= .10) {
			this.Draw(this.Label . "`nDegraded!" . CombinedText, Fn_RGB("0xCC0000"), 30, 12) ;RED
		}


		;Old
		/*
		If (this.ErrorMessage != "") {
			this.Draw(this.Label . "`nDegraded!" . "`n" . this.ErrorMessage, Fn_RGB("0xCC0000"), 30, 7) ;RED
		} Else {
			
		}
		*/
	}


	ErrorCheck() {
		if (this.HealthStatus != 1) {
			Return 1
		}
	}
}

Fn_QueryService(para_Machine,para_Service)
{
	;msgbox, -%para_Machine% and %para_Service%-

	;Open cmd.exe with echoing of commands disabled
	shell := ComObjCreate("WScript.Shell")
	
	;Send the commands to execute, separated by newline
	exec := shell.Exec(ComSpec " /Q echo off")
	commands := " sc \\" . para_Machine . " query " . para_Service
	
	;Always exit at the end!
	exec.StdIn.WriteLine(commands "`nexit")  
	
	;Read and return the output of all commands
	return % exec.StdOut.ReadAll()
}


Fn_ParseServiceResponse(para_Reponse)
{
	ServiceStatus := Fn_QuickRegEx(para_Reponse,"STATE\s+: (\d+)")

	If (ServiceStatus != "null") {
		Return %ServiceStatus%
	}
	Return "000"


	/*
	If (ServiceStatus = 1) {
		Return "Stopped"
	}
	If (ServiceStatus = 2) {
		Return "Start Pending"
	}
	If (ServiceStatus = 3) {
		Return "Stop Pending"
	}
	If (ServiceStatus = 4) {
		Return "Running"
	}
	Return "Not Understood"
	*/
}


Fn_ServiceResponseHumanReadable(para_Reponse)
{
	If (para_Reponse = 1) {
		Return "Stopped"
	}
	If (para_Reponse = 2) {
		Return "Start Pending"
	}
	If (para_Reponse = 3) {
		Return "Stop Pending"
	}
	If (para_Reponse = 4) {
		Return "Running"
	}

	If (para_Reponse = 000) {
		Return "Query UnSuccessful"
	}

	Return "Not Understood"
}