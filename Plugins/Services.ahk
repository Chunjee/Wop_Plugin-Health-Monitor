
gui_orginaly := gui_y
gui_y += 20
gui_x = 30
height = 0
ServicesTop_Array := []


endboxsize := 100 * 1.4
Services_BoxSize := endboxsize
;Read from DVR.txt about what DVRs to monitor
Loop, Read, %A_ScriptDir%\plugins\Services.txt
{
	UserDefined_SystemType := Fn_QuickRegEx(A_LoopReadLine,"(.+)")

	;Create GUI box for each Type
	Gui, Add, Progress, x%gui_x% y%gui_y% w%endboxsize% h%endboxsize% hWndhWnd, 100
	Gui, Show, w1000 , %The_ProjectName%
	gui_x += endboxsize + 20

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


;Debug options
;Clipboard := Fn_JSONfromOBJ(ServicesTop_Array)
;FileAppend, %Alf%, %A_ScriptDir%\HUGE.JSON
;Array_GUI(ServicesTop_Array)



SetTimer, CheckServices, 2000

;OnMessage(0xF, "WM_PAINT")
;OnMessage(0x200, "WM_MOUSEMOVE")
;OnMessage(0x201, "WM_LBUTTONDOWN")
;OnMessage(0x202, "WM_LBUTTONUP")



SB_CheckServices()
{
	global
	CheckServices:
	SetTimer, CheckServices, -60000
	
	endboxsize := Services_BoxSize
	
	;Update the status and stats of each DVR
	Loop, % ServicesTop_Array.MaxIndex() {
		
		;Get Status and Statistics of each DVR 
		ServicesObj%A_Index%.CheckStatus()
		
		;Update GUI Box of each DVR
		ServicesObj%A_Index%.UpdateGUI()
		
		;Set Optimal
		;DVR%A_Index%.SetOptimal()
	}
	;Clipboard := Fn_JSONfromOBJ(ServicesTop_Array)
	Return
}



Class Services_Class {
	
	__New(para_Name) {
		this.Info_Array := []

		X = 0
		Loop, Read, %A_ScriptDir%\plugins\%para_Name%.txt
		{
			If (A_Index = 1) {
				this.Services_Array := StrSplit(Fn_QuickRegEx(A_LoopReadLine,"(.+)"),",")
				;Array_GUI(this.Services_Array)
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
	
	Draw(para_Text, para_Color, para_TextSize = 18)
	{
		global endboxsize
		TextArray := StrSplit(para_Text,"`n")
		
		critical
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
	
	CheckStatus() {
		X = 0
		Loop, % this.Info_Array.MaxIndex() {
			X++
			Loop, % this.Services_Array.MaxIndex() {


				this.Info_Array[X,"RAWSTATUS"] := Fn_QueryService(this.Info_Array[X,"Name"],this.Services_Array[A_Index])
				;Msgbox, % this.Info_Array[X,"RAWSTATUS"] . "   on " . this.Info_Array[X,"Name"]
				this.Info_Array[X,"Status"] := Fn_ParseServiceResponse(this.Info_Array[X,"RAWSTATUS"])
				;Msgbox, % this.Info_Array[X,"Status"]
			}
			
		}
	}
	
	
	UpdateGUI() {
		
		;Update the GUIBox depending on the status of the DVR
		SecondsSinceLastError := this.Info_Array["SecondsSinceLastError"]
		
		SinceLastError := SecondsSinceLastError
		Measurement = seconds
		
		if (SecondsSinceLastError > 60) {
			SinceLastError := floor(SecondsSinceLastError / 60)
			Measurement = mins
		}
		if (SecondsSinceLastError > 3600) {
			SinceLastError := floor(SecondsSinceLastError / 3600)
			Measurement = hours
		}
		if (SecondsSinceLastError > 86400) {
			SinceLastError := floor(SecondsSinceLastError / 86400)
			Measurement = days
		}
		if (SecondsSinceLastError = "") {
			SinceLastError := "No Errors"
			Measurement =
		}
		
		CurrentUsage := this.Info_Array["UsagePercent"]
		
		CombinedText := "`n" . SinceLastError . " " . Measurement . "`n Usage: " . CurrentUsage . "%"
		
		
		
		CurrentStatus := this.Info_Array["CurrentStatus"]
		if (CurrentStatus = 2) {
			this.Draw("Online" . CombinedText, Fn_RGB("0x009900"), 30) ;Green Online
		} else {
			this.Draw("???" . CombinedText, Fn_RGB("0xCC0000"), 30) ;RED ???
			this.SetOptimal()

			;Record error to text file
			MachineName := this.Info_Array["Name"]
			FileAppend, %A_YYYY%%A_MM%%A_DD% [%A_Hour%:%A_Min%] <%MachineName%> %CurrentStatus%`n`r, %A_ScriptDir%\Data\Errors.txt
		}
		
	}
	
	SetOptimal() {
		;Use /statistics Endpoint, save raw result to JSON_Statistics
		Endpoint := this.Info_Array["endpoint"] . "/control?operation=SetStatusToOptimal"
		Staging := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Staging.Open("Get", Endpoint, False)
		Staging.SetRequestHeader("Accept", "application/json")
		Staging.Send()
		
		;Save Raw just for later viewing
		this.Info_Array["JSON_Optimal"] := Staging.ResponseText
	}
}

Fn_QueryService(para_Machine,para_Service)
{
	shell := ComObjCreate("WScript.Shell")
	; Open cmd.exe with echoing of commands disabled
	exec := shell.Exec(ComSpec " /Q /C echo off")
	commands := " sc \\" . para_Machine . " query " . para_Service
	; Send the commands to execute, separated by newline
	exec.StdIn.WriteLine(commands "`nexit")  ; Always exit at the end!
	; Read and return the output of all commands
	return exec.StdOut.ReadAll()
}


Fn_ParseServiceResponse(para_Reponse)
{
	ServiceStatus := Fn_QuickRegEx(para_Reponse,"STATE\s+: (\d+)")
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
}