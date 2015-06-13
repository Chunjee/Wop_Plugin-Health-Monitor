;global ALF := new CustomButton(hWnd)
;ALF.Draw


gui_y += 200
gui_x = 40

DVRTop_Array := []
Loop, Read, %A_ScriptDir%\plugins\DVR.txt
{
	DVR%A_Index% := New DVR(A_LoopReadLine)
	DVRTop_Array[A_Index] := DVR%A_Index%
	
	;Create GUI box for each DVR
	Gui, Margin, 50, 50
	Gui, Add, Progress, x%gui_x% y%gui_y% w100 h100 hWndhWnd, 100
	Gui, Show
	gui_x += 120
	DVRButton%A_Index% := New CustomButton(hWnd)
	;Global DVRButton%A_Index% := New CustomButton(hWnd)
	
}



Gui, Add, Progress, x1 y1 w100 h50 hWndhWnd, 100
Gui, Show, h2000 w2000 , %The_ProjectName%

;SetTimer, CheckDVRs, 2000
;SetTimer, CheckDVRs, 60000

;Global MyButton := new CustomButton(hWnd)
;Return


;OnMessage(0xF, "WM_PAINT")
;OnMessage(0x200, "WM_MOUSEMOVE")
;OnMessage(0x201, "WM_LBUTTONDOWN")
;OnMessage(0x202, "WM_LBUTTONUP")




Sb_CheckDVRs()
{
	CheckDVRs:
	
	global DVRTop_Array
	
	Array_GUI(DVRTop_Array)
	;Update the status and stats of each DVR
	Loop, % DVRTop_Array.MaxIndex() {
		
		DVR%A_Index%.CheckStatus()
	}
	Return
}



Class DVR {
	
	__New(para_Name) {
		this.Info_Array := []
		this.Info_Array["Name"] := para_Name
		this.Info_Array["JSON_Status"] := "null"
		this.Info_Array["JSON_Stats"] := "null"
		this.Info_Array["endpoint"] := "http://" para_Name ".tvgops.tvgnetwork.local/ivr/rest"
		;Msgbox, % para_Name . " created!"
	}
	
	CheckStatus() {
		;Gets the ONLINE / OFFLINE Status. Error stats too maybe?
		
		;Use /status Endpoint, save result to 
		Endpoint := this.Info_Array["endpoint"] . "/status"
		Msgbox, getting status of %Endpoint%
		Staging := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		Staging.Open("Get", Endpoint, False)
		Staging.SetRequestHeader("Accept", "application/json")
		Staging.Send()
		Response := Staging.ResponseText
		Return % Response
	}
	
	CheckAll() {
		Loop, % DVR_Array.MaxIndex() {
			Response := this.CheckStatus(DVR_Array[A_Index,"Name"])
			DVR_Array[A_Index,"JSON"] := Response
		}
	}
}


CheckDVR(para_DVRName)
{
	static Base := "http://" . para_DVRName . ".tvgops.tvgnetwork.local/ivr/rest/status"
	Staging := ComObjCreate("WinHttp.WinHttpRequest.5.1")
	Staging.Open("Get", Base, False)
	Staging.SetRequestHeader("Accept", "application/json")
	Staging.Send()
	Response := Staging.ResponseText
	Return % Response
}



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
		this.Draw("Hover", 0xFFFFFF, 0x000000)
	}
	
	Hovering()
	{
		this.Draw("Click", 0xC0C0C0, 0x000000)
	}
	
	Held()
	{
		this.Draw("Release", 0x000000, 0x0000FF)
	}
	
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