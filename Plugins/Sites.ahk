;; This plugin uses the slower download to file. Use Sites2 whenever possible
TxtFile = %A_WorkingDir%\plugins\Sites.txt
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
	SiteTop_Array := []

	endboxsize := 100 * 1.4
	Site_BoxSize := endboxsize
	;Read from .txt about what to monitor
	Loop, Read, % TxtFile
	{
		If (InStr(A_LoopReadLine,";")) {
			Continue
		}
		;Grab the Name and Url out of each line.
		The_SiteName := Fn_QuickRegEx(A_LoopReadLine,"Name:(\S+)")
		The_SiteURL := Fn_QuickRegEx(A_LoopReadLine,"URL:([\w:\/\.]+)")
		;Create the DVR Object for each
		If (The_SiteName != "null" && The_SiteURL != "null") {
			Site%A_Index% := New SiteMonitor(The_SiteName, The_SiteURL)
			
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
			Site%A_Index%.CreateButton(hWnd)
			
			;Add object to array for enumeration
			SiteTop_Array[A_Index] := Site%A_Index%
		}
	}
	gui_y += endboxsize + 20

	;Draw Box around this plugin
	height += endboxsize + 30

	Gui, Font, s12 w700, Arial
	Gui, Add, GroupBox, x6 y%gui_orginaly% w980 h%height%, Sites
	Gui, Font


	SetTimer, CheckSites, -2000
}




;Plugin functions and classes-------------------------------



Sb_CheckSites()
{
	global
	
	CheckSites:
	endboxsize := Site_BoxSize
	
	;Go through the list of sites
	Loop, % SiteTop_Array.MaxIndex() {
		
		;Get Status and Statistics of each
		Site%A_Index%.CheckStatus()
		
		;Update GUI Box of each
		Site%A_Index%.UpdateGUI()

		;Report any errors
		if (Site%A_Index%.ErrorCheck()) {
			Fn_ErrorCount(1)
		}
	}
	SetTimer, CheckSites, -60000
	Return
}



Class SiteMonitor {
	
	__New(para_Name, para_URL) {
		
		this.Info_Array := []
		this.Info_Array["Name"] := para_Name
		this.Info_Array["URL"] := para_URL
		this.DrawDefault()
	}
	
	CreateButton(hWnd) {
		this.GDI := new GDI(hWnd)
		this.hWnd := hWnd
		this.DrawDefault()
	}
	
	UpdateGUI() {
		
		;Update the GUIBox depending on the status
		CombinedText := "`n" . ""
		
		CurrentStatus := this.Info_Array["CurrentStatus"]
		
		If (CurrentStatus = "Online") {
			this.Draw("Online" . CombinedText, Fn_RGB("0x009900"), 30) ;Green Online
			Return
		}
		If (CurrentStatus = "MaintenancePage") {
			this.Draw("MAINT PAGE" . CombinedText, Fn_RGB("0xFF6600"), 22) ;Orange MAINT PAGE
			Return
		}
		If (CurrentStatus = "CheckFailed") {
			this.Draw("Download Failed" . CombinedText, Fn_RGB("0xFFF79A"), 22) ;Yellow "Download Failed"
			Return
		}
		If (CurrentStatus = "Offline") {
			this.Draw("OUTAGE" . CombinedText, Fn_RGB("0xCC0000"), 22) ;Red Offline Page
			Return
		}
		If (CurrentStatus = "Outage") {
			this.Draw("OUTAGE" . CombinedText, Fn_RGB("0x990000"), 22) ;DarkRed Outage Page
			Return
		}
		;All others failed
		this.Draw("Unsuccessful" . CombinedText, Fn_RGB("0xFFFFFF"), 22) ;White Check Unsuccessful
	}
	
	DrawDefault()
	{
		this.Draw("Starting..." . CombinedText, Fn_RGB("0xFFFFFF"), 22) ;White Unchecked
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
		;Download the page and try to understand what state it is in. ONLINE / MAINTENANCE / OTHER
		;HTMLFile_loc := % A_WorkingDir . "\Data\Temp\" . this.Info_Array["Name"] . ".html"
		;Msgbox, HTMLFile_loc
		/* 
			;Old slow way of downloading pages
			;FileDelete, % HTMLFile_loc
			;UrlDownloadToFile, % this.Info_Array["URL"], % HTMLFile_loc
			;Sleep 100
			;FileRead, The_MemoryFile, % HTMLFile_loc
		*/
		
		;Download Page to memory
		The_MemoryFile := ""


		;Try to download the page 4 times and quit on first success
		Loop, 4 {
			The_MemoryFile := Fn_IOdependantDownload(this.Info_Array["URL"])
			if (The_MemoryFile != "null") {
				Break
			}
			If (A_Index >= 4) { ;quit after max tries exeeded
				this.Info_Array["CurrentStatus"] := "CheckFailed"
			}
		}
		;Debug, check the downloaded HTML
			;Clipboard = %The_MemoryFile%
			;Msgbox, % The_MemoryFile
		
		;Try to understand what state the page is in but assume "Check unsuccessful"
		this.Info_Array["CurrentStatus"] := "Unknown"

		;Outage Message
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(inconvenience)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Outage"
			Return
		}
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(Service Unavailable)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Outage"
			Return
		}
		/*PageCheck := Fn_QuickRegEx(The_MemoryFile, "(503)") ;HTTP 503 
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Outage"
			Return
		}
		*/

		;Normal Mainenance
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(Important Notice)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "MaintenancePage"
			Return
		}
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(currently unavailable)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "MaintenancePage"
			Return
		}

		;Online Status
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(<\/script>)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Online"
			Return
		}
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(races-navigation-skeleton)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Online"
			Return
		}PageCheck := Fn_QuickRegEx(The_MemoryFile, "(setCSSLoaded)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Online"
			Return
		}


		;SPECIAL CASES BELOW HERE: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		;Clipboard := The_MemoryFile
		;Touch Sites
		if (InStr(this.Info_Array["Name"],"Touch")) {
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(touch-revamp)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				Return
			}
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(please)")
			if (PageCheck = "please") {
				this.Info_Array["CurrentStatus"] := "MaintenancePage"
				Return
			}
		}
	}

	ErrorCheck() {
		if (this.Info_Array["CurrentStatus"] != "Online") {
			Return 1
		}
	}
}