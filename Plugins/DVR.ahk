;global ALF := new CustomButton(hWnd)
;ALF.Draw



gui_orginaly := gui_y
gui_y += 20
gui_x = 30
height = 0
DVRTop_Array := []
Loop, Read, %A_ScriptDir%\plugins\DVR.txt
{
	;Create GUI box for each DVR
	Gui, Add, Progress, x%gui_x% y%gui_y% w100 h100 hWndhWnd, 100
	Gui, Show, w630 , %The_ProjectName%
	gui_x += 120
	
	DVR%A_Index% := New DVR(A_LoopReadLine)
	;Create re-drawable gui for the DVR
	DVR%A_Index%.CreateButton(hWnd)
	
	DVRTop_Array[A_Index] := DVR%A_Index%
	
	
	;DVRButton%A_Index% := New CustomButton(hWnd)
	;Global DVRButton%A_Index% := New CustomButton(hWnd)
}
height += 130
Gui, Add, GroupBox, x6 y%gui_orginaly% w510 h%height%, DVR


Loop, % DVRTop_Array.MaxIndex() {
	
	DVR%A_Index%.CheckStatus()
	DVR%A_Index%.CheckStatistics()
}


Gui, Show, h1000 w530 , %The_ProjectName%

;Debug options
;Alf := Fn_JSONfromOBJ(DVRTop_Array)
;Clipboard := Alf
;FileAppend, %Alf%, %A_ScriptDir%\HUGE.JSON
;Array_GUI(DVRTop_Array)



SetTimer, CheckDVRs, 2000

;OnMessage(0xF, "WM_PAINT")
;OnMessage(0x200, "WM_MOUSEMOVE")
;OnMessage(0x201, "WM_LBUTTONDOWN")
;OnMessage(0x202, "WM_LBUTTONUP")



Fn_CurrentUnixTime()
{
	TimeStamp := A_NowUTC
	TimeStamp -= 19700101000000,seconds
	Return % TimeStamp
}


Sb_CheckDVRs()
{
	
	CheckDVRs:
	SetTimer, CheckDVRs, -60000
	global DVRTop_Array
	
	;Update the status and stats of each DVR
	Loop, % DVRTop_Array.MaxIndex() {
		
		;Get Status and Statistics of each DVR 
		DVR%A_Index%.CheckStatus()
		DVR%A_Index%.CheckStatistics()
		
		;Update GUI Box of each DVR
		DVR%A_Index%.UpdateGUI()
		
	}
	Return
}



Class DVR {
	
	__New(para_Name) {
		this.GUIBox := M
		
		this.Info_Array := []
		this.Info_Array["Name"] := para_Name
		this.Info_Array["endpoint"] := "http://" para_Name ".tvgops.tvgnetwork.local/ivr/rest"
		
		this.Info_Array["JSON_Status"] := "null"
		this.Info_Array["JSON_Statistics"] := "null"
		this.Info_Array["CurrentStatus"] := "null"
		;Msgbox, % para_Name . " created!"
	}
	
	CreateButton(hWnd) {
		this.GDI := new GDI(hWnd)
		this.hWnd := hWnd
		this.DrawDefault()
	}
	
	UpdateGUI() {
		
		;Update the GUIBox depending on the status of the DVR
		SecondsSinceLastError := this.Info_Array["SecondsSinceLastError"]
		
		SinceLastError := SecondsSinceLastError
		Measurement = seconds
		
		
		If (SecondsSinceLastError > 60) {
			SinceLastError := floor(SecondsSinceLastError / 60)
			Measurement = mins
		}
		If (SecondsSinceLastError > 3600) {
			SinceLastError := floor(SecondsSinceLastError / 3600)
			Measurement = hours
		}
		If (SecondsSinceLastError > 86400) {
			SinceLastError := floor(SecondsSinceLastError / 86400)
			Measurement = days
		}
		If (SecondsSinceLastError = "") {
			SinceLastError := "No Errors"
			Measurement =
		}
		
		CurrentUsage := this.Info_Array["UsagePercent"]
		
		CombinedText := "`n" . SinceLastError . " " . Measurement . "`n" . CurrentUsage . "%"
		
		
		
		CurrentStatus := this.Info_Array["CurrentStatus"]
		If (CurrentStatus = 2) {
			this.Draw("Online" . CombinedText, Fn_RGB("0x009900"), 0x000000, 18) ;Green Online
		} Else {
			this.Draw("???" . CombinedText, Fn_RGB("0xCC0000"), 0x000000, 18) ;RED ???
		}
		
	}
	
	DrawDefault()
	{
		this.Draw("UnChecked", Fn_RGB("0xFFFFFF"), 0x000000, 18) ;White Unchecked
	}
	
	Draw(Text, Color, TextColor, TextSize = 18)
	{
		TextArray := StrSplit(Text,"`n")
		
		critical
		this.GDI.FillRectangle(0, 0, this.GDI.CliWidth, this.GDI.CliHeight, Color, TextColor)
		this.GDI.DrawText(0, 0, 100, 50, this.Info_Array["Name"], TextColor, "Times New Roman", 12, "CC")
		this.GDI.DrawText(0, 20, 100, 50, TextArray[1], TextColor, "Impact", TextSize, "CC")
		this.GDI.DrawText(0, 40, 100, 50, TextArray[2], TextColor, "Impact", TextSize, "CC")
		this.GDI.DrawText(0, 60, 100, 50, TextArray[3], TextColor, "Impact", TextSize, "CC")
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
		If (Response.ResultCode.Name = "Success") {
			this.Info_Array["TotalChannels"] := Response.ReturnResult.TotalChannels
			this.Info_Array["ActiveChannels"] := Response.ReturnResult.ActiveChannels
			this.Info_Array["UsagePercent"] := floor((this.Info_Array["ActiveChannels"] / this.Info_Array["TotalChannels"]) * 100)
		}
	}
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




Class Proof {
	
	something := "Hello World!"
	
	__New() {
		this.Array := []
		Loop, read, %A_ScriptDir%\Bacon.txt
		{
			this.Array[A_Index,"Name"] := A_LoopReadLine
		}
	}
	
	FillOne(para_term) {
		
		Base := "https://mashape-community-urban-dictionary.p.mashape.com/define?term=" . para_term
		Staging := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Staging.Open("Get", Base, False)
		Staging.SetRequestHeader("X-Mashape-Key", "PF7pavFH0ymsheIScndtHbijovmXp1cFH5ljsn7WRBajvDLmhR")
		Staging.SetRequestHeader("Accept", "text/plain")
		Staging.Send()
		Response := Staging.ResponseText
		Return % Response
	}
	
	FillAll() {
		Loop, % this.Array.MaxIndex() {
			Response := this.FillOne(this.Array[A_Index,"Name"])
			this.Array[A_Index,"JSON"] := Response
		}
	}
	
	ConvertJSON() {
		Loop, % this.Array.MaxIndex() {
			Obj := Fn_JSONtoOBJ(this.Array[A_Index,"JSON"])
			this.Array[A_Index,"Text"] := Obj.list.1.definition
		}
		
	}
	
	
	GiveArray() {
		Return % this.Array
	}
	
	
}