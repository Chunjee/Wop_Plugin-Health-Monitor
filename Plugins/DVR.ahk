TxtFile = %A_ScriptDir%\plugins\DVR.txt
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
	DVRTop_Array := []


	endboxsize := 100 * 2.0
	DVR_BoxSize := endboxsize
	;Read from DVR.txt about what DVRs to monitor
	Loop, Read, % TxtFile
	{
		;Create the DVR Object for each
		Name := Fn_QuickRegEx(A_LoopReadLine,"Name:(\w+)")
		BaseURL := Fn_QuickRegEx(A_LoopReadLine,"Location:(\w+)")
		
		DVR%A_Index% := New DVR(Name,BaseURL)
		
		;Create GUI box for each DVR
		Gui, Add, Progress, x%gui_x% y%gui_y% w%endboxsize% h%endboxsize% hWndhWnd, 100
		Gui, Show, w1000 , %The_ProjectName%
		gui_x += endboxsize + 20
		
		;Change to a re-drawable gui for the DVR
		DVR%A_Index%.CreateButton(hWnd)
		
		;Add object to array for enumeration
		DVRTop_Array[A_Index] := DVR%A_Index%
		
		;Might be needed later if we want clickable buttons
		;DVRButton%A_Index% := New CustomButton(hWnd)
	}
	;Draw Box around this plugin
	height += endboxsize + 40
	Gui, Font, s12 w700, Arial
	Gui, Add, GroupBox, x6 y%gui_orginaly% w980 h%height%, DVR
	Gui, Font

	gui_y += endboxsize + 20

	SetTimer, CheckDVRs, 2000
}






;Plugin functions and classes-------------------------------



Sb_CheckDVRs()
{
	global
	CheckDVRs:
	SetTimer, CheckDVRs, -60000
	
	endboxsize := DVR_BoxSize
	
	;Update the status and stats of each DVR
	Loop, % DVRTop_Array.MaxIndex() {
		
		;Get Status and Statistics of each DVR 
		DVR%A_Index%.CheckStatus()
		DVR%A_Index%.CheckStatistics()
		
		;Update GUI Box of each DVR
		DVR%A_Index%.UpdateGUI()
		
		;Set Optimal
		;DVR%A_Index%.SetOptimal()
	}
	;Clipboard := Fn_JSONfromOBJ(DVRTop_Array)
	Return
}



Class DVR {

	__New(para_Name,para_Location) {
		this.Info_Array := []
		this.Info_Array["Name"] := para_Name
		this.Info_Array["endpoint"] := "http://" . para_Location . ".tvgops.tvgnetwork.local/ivr/rest"
		
		;Not really needed... consider removal
		this.Info_Array["JSON_Status"] := "null"
		this.Info_Array["JSON_Statistics"] := "null"
		this.Info_Array["CurrentStatus"] := "null"
	}

	CreateButton(hWnd) {
		this.GDI := new GDI(hWnd)
		this.hWnd := hWnd
		this.DrawDefault()
	}
	
	DrawDefault() {
		this.Draw("UnChecked", Fn_RGB("0xFFFFFF"), 18) ;White Unchecked
	}
	
	Draw(para_Text, para_Color, para_TextSize = 18) {
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
		;Gets the ONLINE / OFFLINE Status. Error stats too maybe?
		
		;Use /status Endpoint, save raw result to JSON_Status
		Endpoint := this.Info_Array["endpoint"] . "/status"
		Staging := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Staging.Open("Get", Endpoint, False)
		Staging.SetRequestHeader("Accept", "application/json")
		Staging.Send()
		
		;Save Raw just for later viewing
		this.Info_Array["JSON_Status"] := Staging.ResponseText
		
		;Convert Response to an Object and extract the CurrentStatus
		Response := Fn_JSONtoOBJ(Staging.ResponseText)
		this.Info_Array["CurrentStatus"] := Response.ReturnResult.CurrentStatus
		
		;Extract the Last Error Reported TimeStamp. Note "LastErrorRepored" is a typo in API
		this.Info_Array["LastErrorReported"] := Fn_QuickRegEx(Response.ReturnResult.LastErrorRepored,"Date\((\d{10})\d+\)")
		this.Info_Array["TimeStamp"] := Fn_QuickRegEx(Response.TimeStamp,"Date\((\d{10})\d+\)")
		this.Info_Array["SecondsSinceLastError"] := this.Info_Array["TimeStamp"] - this.Info_Array["LastErrorReported"]
	}
	
	CheckStatistics() {
		;Gets the statistics response
		
		;Use /statistics Endpoint, save raw result to JSON_Statistics
		Endpoint := this.Info_Array["endpoint"] . "/statistics"
		Staging := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Staging.Open("Get", Endpoint, False)
		Staging.SetRequestHeader("Accept", "application/json")
		Staging.Send()
		
		;Save Raw just for later viewing
		this.Info_Array["JSON_Statistics"] := Staging.ResponseText
		
		;Convert Response to an Object and extract the CurrentStatus
		Response := Fn_JSONtoOBJ(Staging.ResponseText)
		if (Response.ResultCode.Name = "Success") {
			this.Info_Array["TotalChannels"] := Response.ReturnResult.TotalChannels
			this.Info_Array["ActiveChannels"] := Response.ReturnResult.ActiveChannels
			this.Info_Array["UsagePercent"] := floor((this.Info_Array["ActiveChannels"] / this.Info_Array["TotalChannels"]) * 100)
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
			this.Draw("???" . CombinedText, Fn_RGB("0xCC0000"), 30) ;RED Error
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



Fn_CurrentUnixTime()
{
	TimeStamp := A_NowUTC
	TimeStamp -= 19700101000000,seconds
	Return % TimeStamp
}

;-------------------------------------------------------------------


WM_PAINT()
{
	Sleep, -1 ; Let the scrollbar redraw before painting over it
	MyButton.BitBlt()
}

WM_MOUSEMOVE(wParam, lParam, Msg, hWnd)
{
	static LasthWnd
	if (hWnd != LasthWnd)
	{
		if (hWnd == MyButton.hWnd) {
			MyButton.Hovering()
		} else if (lasthWnd == MyButton.hWnd) {
			MyButton.Default()
		}
		LasthWnd := hWnd
	}
}

WM_LBUTTONDOWN(wParam, lParam, Msg, hWnd)
{
	if (hWnd == MyButton.hWnd) {
		MyButton.Held()	
	}
}

WM_LBUTTONUP(wParam, lParam, Msg, hWnd)
{
	if (hWnd == MyButton.hWnd) {
		MyButton.Hovering()
	}
	
}

class CustomButton
{
	__New(hWnd)
	{
		this.GDI := new GDI(hWnd)
		this.hWnd := hWnd
		this.Default()
	}
	
	Default()
	{
		this.Draw("", 0xFFFFFF, 0x000000)
	}
	
	/*
		Hovering()
		{
			this.Draw("Click", 0xC0C0C0, 0x000000)
		}
		
		Held()
		{
			this.Draw("Release", 0x000000, 0x0000FF)
		}
	*/
	
	Draw(Text, Color, TextColor)
	{
		critical
		this.GDI.FillRectangle(0, 0, this.GDI.CliWidth, this.GDI.CliHeight, Color, TextColor)
		this.GDI.DrawText(0, 0, 100, 50, Text, TextColor, "Courier New", 20, "CC")
		this.GDI.BitBlt()
	}
	
	BitBlt()
	{
		this.GDI.BitBlt()
	}
}