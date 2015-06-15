;global ALF := new CustomButton(hWnd)
;ALF.Draw



gui_orginaly := gui_y
gui_y += 20
gui_x = 30
height = 0
SiteTop_Array := []

;Read from DVR.txt about what DVRs to monitor
Loop, Read, %A_ScriptDir%\plugins\Sites.txt
{
	;Grab the Name and Url out of each line.
	The_SiteName := Fn_QuickRegEx(A_LoopReadLine,"Name:(\w+)")
	The_SiteURL := Fn_QuickRegEx(A_LoopReadLine,"URL:([\w:\/\.]+)")
	;Create the DVR Object for each
	If (The_SiteName != "null" && The_SiteURL != "null") {
		Site%A_Index% := New SiteMonitor(The_SiteName, The_SiteURL)
		
		;Create GUI box for each DVR
		Gui, Add, Progress, x%gui_x% y%gui_y% w100 h100 hWndhWnd, 100
		Gui, Show, w630 , %The_ProjectName%
		gui_x += 120
		
		;Change to a re-drawable gui for the Site
		Site%A_Index%.CreateButton(hWnd)
		
		;Add object to array for enumeration
		SiteTop_Array[A_Index] := Site%A_Index%
	}
}
gui_y += 160

;Draw Box around this plugin
height += 130
Gui, Add, GroupBox, x6 y%gui_orginaly% w510 h%height%, Sites


Gui, Show, h600 w530 , %The_ProjectName%

;Debug options
;Clipboard := Fn_JSONfromOBJ(DVRTop_Array)
;FileAppend, %Alf%, %A_ScriptDir%\HUGE.JSON
;Array_GUI(DVRTop_Array)



SetTimer, CheckSites, 2000

;OnMessage(0xF, "WM_PAINT")
;OnMessage(0x200, "WM_MOUSEMOVE")
;OnMessage(0x201, "WM_LBUTTONDOWN")
;OnMessage(0x202, "WM_LBUTTONUP")



Sb_CheckSites()
{
	
	CheckSites:
	SetTimer, CheckSites, -60000
	global SiteTop_Array
	
	;Go through the list of sites
	Loop, % SiteTop_Array.MaxIndex() {
		
		;Get Status and Statistics of each
		Site%A_Index%.CheckStatus()
		
		;Update GUI Box of each
		Site%A_Index%.UpdateGUI()
	}
	;Clipboard := Fn_JSONfromOBJ(SiteTop_Array)
	Return
}



Class SiteMonitor {
	
	__New(para_Name, para_URL) {
		
		this.Info_Array := []
		this.Info_Array["Name"] := para_Name
		this.Info_Array["URL"] := para_URL
	}
	
	CreateButton(hWnd) {
		this.GDI := new GDI(hWnd)
		this.hWnd := hWnd
		this.DrawDefault()
	}
	
	UpdateGUI() {
		
		;Update the GUIBox depending on the status
		CombinedText := "`n" . this.Info_Array["Name"] . " " . this.Info_Array["CurrentStatus"]
		
		
		CurrentStatus := this.Info_Array["CurrentStatus"]
		
		If (CurrentStatus = "Online") {
			this.Draw("Online" . CombinedText, Fn_RGB("0x009900"), 0x000000, 18) ;Green Online
			Return
		}
		If (CurrentStatus = "MainenancePage") {
			this.Draw("MAINT PAGE" . CombinedText, Fn_RGB("0xFF6600"), 0x000000, 22) ;Orange MAINT PAGE
			Return
		}
		;All others failed
		this.Draw("Check Unsuccessful" . CombinedText, Fn_RGB("0xFFFFFF"), 0x000000, 18) ;White Check Unsuccessful
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
		this.GDI.DrawText(0, 0, 100, 50, this.Info_Array["Name"], TextColor, "Times New Roman", 33, "CC")
		this.GDI.DrawText(0, 20, 100, 50, TextArray[1], TextColor, "Impact", TextSize, "CC")
		this.GDI.BitBlt()
	}
	
	CheckStatus() {
		;Download the page and try to understand what state it is in. ONLINE / MAINTENANCE / OTHER
		HTMLFile_loc := % A_ScriptDir . "\Data\Temp\" . this.Info_Array["Name"] . ".html"
		
		/* 
			;Old slow way of downloading pages
			;FileDelete, % HTMLFile_loc
			;UrlDownloadToFile, % this.Info_Array["URL"], % HTMLFile_loc
			;Sleep 100
			;FileRead, The_MemoryFile, % HTMLFile_loc
		*/
		
		;Download Page to memory
		The_MemoryFile := ""
		The_MemoryFile := Fn_DownloadtoFile(this.Info_Array["URL"])
		
		;Try to understand what state the page is in
		this.Info_Array["CurrentStatus"] := "No Match"
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(http:\/\/maintenance\.tvg\.com\/)")
		If (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "MainenancePage"
		}
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(\/\/nodejs\.tvg\.com\/deposit\/quick)")
		If (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Online"
		}
	}
}