;global ALF := new CustomButton(hWnd)
;ALF.Draw



gui_orginaly := gui_y
gui_y += 20
gui_x = 30
height = 0
SpeedTop_Array := []

endboxsize := 100 * 1.4
Speed_BoxSize := endboxsize
;Read from Speed.txt about what Speeds to monitor
Loop, Read, %A_ScriptDir%\plugins\Speed.txt
{
	if (InStr(A_LoopReadLine,";")) {
		Continue
	}

	;Create the Speed Object for each
	Name := Fn_QuickRegEx(A_LoopReadLine,"Name:(\w+)")
	Type := Fn_QuickRegEx(A_LoopReadLine,"Type:(\w+)")
	URL := Fn_QuickRegEx(A_LoopReadLine,"URL:([\w+\.\/\\]+)")


	;Create the Object for each
	Speed%A_Index% := New Speed(Name,Type,URL)
		
		;Add new line if max ammount of boxes reached
		if (gui_x >= 870) {
			gui_x = 30
			gui_y += endboxsize + 10
			height += endboxsize + 30
		}

		;Create GUI box for each DVR
		Gui, Add, Progress, x%gui_x% y%gui_y% w%endboxsize% h%endboxsize% hWndhWnd, 100
		Gui, Show, w1000 , %The_ProjectName%
		gui_x += endboxsize + 10
		
		;Change to a re-drawable gui for the Site
		Speed%A_Index%.CreateButton(hWnd)
		
		;Add object to array for enumeration
		SpeedTop_Array[A_Index] := Speed%A_Index%
}

gui_y += endboxsize + 20

;Draw Box around this plugin
height += endboxsize + 40
Gui, Font, s12 w700, Arial
Gui, Add, GroupBox, x6 y%gui_orginaly% w980 h%height%, Speed
Gui, Font


;Debug options
;Clipboard := Fn_JSONfromOBJ(SpeedTop_Array)
;FileAppend, %Alf%, %A_ScriptDir%\HUGE.JSON
;Array_GUI(SpeedTop_Array)



SetTimer, CheckSpeeds, 2000
;Sb_CheckSpeeds()
;OnMessage(0xF, "WM_PAINT")
;OnMessage(0x200, "WM_MOUSEMOVE")
;OnMessage(0x201, "WM_LBUTTONDOWN")
;OnMessage(0x202, "WM_LBUTTONUP")



Sb_CheckSpeeds()
{
	global
	CheckSpeeds:
	SetTimer, CheckSpeeds, -60000
	
	endboxsize := Speed_BoxSize
	
	;Update the status and stats of each Speed
	Loop, % SpeedTop_Array.MaxIndex() {
		
		;Get Status and Statistics of each Speed 
		Speed%A_Index%.Ping()
		
		;Update GUI Box of each Speed
		Speed%A_Index%.UpdateGUI()
	}
	;Clipboard := Fn_JSONfromOBJ(SpeedTop_Array)
	Return
}



Class Speed {
	
	__New(para_Name,para_Type,para_Location) {
		this.Info_Array := []
		this.Info_Array["Name"] := para_Name
		this.Info_Array["Type"] := para_Type
		this.Info_Array["endpoint"] := para_Location
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
	
	Ping() {
		;RTT := Ping4(this.Info_Array["endpoint"],Result)

		/*Do not try this until ping is improved*/
		if (this.Info_Array["Type"] = "fast") {
			RTT := Ping4(this.Info_Array["endpoint"],Result)
		}
		if (this.Info_Array["Type"] = "ip") {
			RTT := PingAsync(this.Info_Array["endpoint"])
			msgbox, % RTT
		}
		

		this.Info_Array["Time"] := Result.RTTime
		this.Info_Array["IP"] := Result.IPAddr

	}

	CheckStatus() {

	}
	
	
	UpdateGUI() {
		
		;Update the GUIBox depending on the status of the Speed
		ResponseTime := this.Info_Array["Time"]
		CombinedText := this.Info_Array["IP"] . "`nDelay:" . this.Info_Array["Time"]

		;Draw box depending on response time of the site
		if (ResponseTime = "-1" || ResponseTime = "") {
			this.Draw("NO REPLY" . CombinedText, Fn_RGB("0xCC0000"), 30) ;RED
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