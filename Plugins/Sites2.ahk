﻿;; This plugin uses the faster download directly to memory
TxtFile = %A_WorkingDir%\plugins\Sites2.txt
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
	SiteDirect_Array := []

	endboxsize := 100 * 1.4
	SiteDirect_BoxSize := endboxsize
	;Read from DVR.txt about what DVRs to monitor
	Loop, Read, %A_WorkingDir%\plugins\Sites2.txt
	{
		if (InStr(A_LoopReadLine,";")) {
			Continue
		}
		;Grab the Name and Url out of each line.
		The_SiteName := Fn_QuickRegEx(A_LoopReadLine,"Name:(\S+)")
		The_SiteURL := Fn_QuickRegEx(A_LoopReadLine,"URL:([\w:\/\.]+)")
		;Create the DVR Object for each
		if (The_SiteName != "null" && The_SiteURL != "null") {
			SiteDirect%A_Index% := New SiteMonitorDirect(The_SiteName, The_SiteURL)
			
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
			SiteDirect%A_Index%.CreateButton(hWnd)
			
			;Add object to array for enumeration
			SiteDirect_Array[A_Index] := SiteDirect%A_Index%
		}
	}
	gui_y += endboxsize + 20

	;Draw Box around this plugin
	height += endboxsize + 30

	Gui, Font, s12 w700, Arial
	Gui, Add, GroupBox, x6 y%gui_orginaly% w980 h%height%, Sites2
	Gui, Font

	SetTimer, CheckSitesDirect, -2000
}






;Plugin functions and classes-------------------------------


Sb_CheckSitesDirect()
{
	global
	
	CheckSitesDirect:
	endboxsize := SiteDirect_BoxSize
	;Go through the list of sites
	Loop, % SiteDirect_Array.MaxIndex() {
		;Get Status and Statistics of each
		SiteDirect%A_Index%.CheckStatus()
		
		;Decypher the status of each based on the retrieved html/data
		SiteDirect%A_Index%.UnderstandStatus()

		;Update GUI Box of each
		SiteDirect%A_Index%.UpdateGUI()

		;Report any errors
		if (SiteDirect%A_Index%.ErrorCheck()) {
			Fn_ErrorCount(1)
		}
	}
	Fn_ErrorCount("report")
	SetTimer, CheckSitesDirect, -60000
Return
}


Class SiteMonitorDirect {
	
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
		If (CurrentStatus = "Unknown") {
			this.Draw("Unknown" . CombinedText, Fn_RGB("0xFFFFFF"), 22) ;White "Unknown" Reply
			Return
		}
		If (CurrentStatus = "CheckFailed") {
			this.Draw("Download Failed" . CombinedText, Fn_RGB("0xFFF79A"), 22) ;Yellow "Download Failed"
			Return
		}
		If (CurrentStatus = "MaintenancePage") {
			this.Draw("MAINT" . CombinedText, Fn_RGB("0xFF6600"), 22) ;Orange MAINT PAGE
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
	
	DrawDefault() {
		this.Draw("Starting..." . CombinedText, Fn_RGB("0xFFFFFF"), 22) ;White Unchecked
	}
	
	Draw(para_Text, para_Color, para_TextSize = 18)	{
		global endboxsize
		TextArray := StrSplit(para_Text,"`n")
		
		critical
		Sleep, -1 ; Let the scrollbar redraw before painting over it
		this.GDI.FillRectangle(0, 0, this.GDI.CliWidth, this.GDI.CliHeight, para_Color, "0x000000")
		
		x := 30
		Loop, % TextArray.MaxIndex() {
			If (A_Index = 1) {
				;figure out text size for the first row
				if (StrLen(this.Info_Array["Name"]) > 4) {
					TextSize := 40 - (StrLen(this.Info_Array["Name"])*1.2)
				} else {
					TextSize := 40
				}
				;Always draw first line specifically and with para_TextSize
				this.GDI.DrawText(0, 0, endboxsize, 50, this.Info_Array["Name"], "0x000000", "Times New Roman", TextSize, "CC")
			}
			;Following lines are drawn generically
			this.GDI.DrawText(0, x, endboxsize, 50, TextArray[A_Index], "0x000000", "Consolas", para_TextSize, "CC")
			x += 26
		}
		this.GDI.BitBlt()
	}
	

	CheckStatus() {
		;;Download the page and try to understand what state it is in. ONLINE / MAINTENANCE / OTHER
		
		;Download Page to memory
		The_MemoryFile := ""

		;Try to download the page 4 times and quit on first success
		maxtries := 3
		Loop, % maxtries {
			The_MemoryFile := Fn_DownloadtoFile(this.Info_Array["URL"])
			this.Info_Array["CurrentStatus"] := "Unknown"
			If (A_Index = (maxtries)) {
				The_MemoryFile := Fn_IOdependantDownload(this.Info_Array["URL"])
			}
			If (The_MemoryFile != "null") { ;quit after success
				this.Info_Array["MemoryFile"] := The_MemoryFile
				Break
			}
			If (A_Index >= maxtries) { ;quit after max tries exeeded
				this.Info_Array["CurrentStatus"] := "CheckFailed"
			}
		}
	}

	UnderstandStatus() {
		;Debug, check the response
			;Clipboard := The_MemoryFile
			;Msgbox, % this.Info_Array["Name"] . "`n`r" The_MemoryFile
		
		;;Try to understand what state the page is in but assume "Check unsuccessful"
		this.Info_Array["CurrentStatus"] := "Unknown"
		
		;Normal Mainenance
		PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(maintenance\.tvg\.com\/)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "MaintenancePage"
		}

		;Outage
		PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(Service Unavailable)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Outage"
		}
		PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(503)") ;HTTP 503
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Outage"
		}

		;Online Status
		PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(<\/script>)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Online"
		}

		;Micro Services: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		if (InStr(this.Info_Array["URL"],"health")) {
			;convert JSON resoponse to Object
			Response := Fn_JSONtoOBJ(this.Info_Array["MemoryFile"])
			if (Response.Status = "BAD" || Response.Status = "DOWN") {
				this.Info_Array["CurrentStatus"] := "Outage"
				return
			}
			if (Response.Status = "OK" || Response.Status = "UP") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			} else {
				FileAppend, % "`n" . this.Info_Array["URL"] . "     -    " . this.Info_Array["MemoryFile"], % A_ScriptDir . "\MicroserviceErrors.txt"
				return
				;this.Info_Array["CurrentStatus"] := "Unknown"
			}
		}


		;SPECIAL CASES BELOW HERE: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		;Touch Sites
		if (InStr(this.Info_Array["Name"],"Touch")) {
			PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(!isAndroidApp)")

			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			}
			PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(please)")
			if (PageCheck = "please") {
				this.Info_Array["CurrentStatus"] := "MaintenancePage"
				return
			}
		}
		;HRTV
		if (InStr(this.Info_Array["Name"],"HRTV")) {
			PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(TVG2)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			}
		}
		if (InStr(this.Info_Array["Name"],"HRTV")) {
			PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(maintenance)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "MaintenancePage"
				return
			}
		}
		;Betfair
		if (InStr(this.Info_Array["Name"],"Betfair")) {
			PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(function)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			}
			PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"],"(maintenance)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "MaintenancePage"
				return
			}
		}
		;CMS
		if (InStr(this.Info_Array["Name"],"cms")) {
			PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(Drupal)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			} else {
				this.Info_Array["CurrentStatus"] := "Offline"
			}
		}
		;Equibase Store
		if (InStr(this.Info_Array["Name"],"Eq-Store")) {
			PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(TRACK_ID=)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			} else {
				this.Info_Array["CurrentStatus"] := "Offline"
				return
			}
		}
		;Exchange
		if (InStr(this.Info_Array["Name"],"Exchange")) {
			PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(accountDetails)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			} else {
				this.Info_Array["CurrentStatus"] := "Offline"
			}
		}
		;Event Collector
		if (InStr(this.Info_Array["Name"],"Event")) {
			PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(Untitled Page)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			} else {
				this.Info_Array["CurrentStatus"] := "Offline"
				return
			}
		}
		;Neulion
		if (InStr(this.Info_Array["Name"],"Neulion")) {
			PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(<track name=)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			}
		}
		;Track Video Dropdown. Non-functional~~~~~~~~~~
		if (InStr(this.Info_Array["Name"],"Dropdown")) {
			PageCheck := Fn_QuickRegEx(this.Info_Array["MemoryFile"], "(\[\])")
			if (PageCheck = "null") {
				this.Info_Array["CurrentStatus"] := "Online"
			} else if (PageCheck = "[]") {
				this.Info_Array["CurrentStatus"] := "Offline"
				return
			}
		}

		;If any possible errors were encountered
		if (this.Info_Array["CurrentStatus"] != "Online") {
			;send error count to a seprate function
			Fn_ErrorCount(1)
		}
	}


	ErrorCheck() {
		if (this.Info_Array["CurrentStatus"] != "Online") {
			Return 1
		}
	}
}