;; This plugin uses the faster download directly to memory
TxtFile = %A_ScriptDir%\plugins\UpTimeRobot.txt
IfExist, % TxtFile
{
	PluginActive_Bool := True
} else {
	PluginActive_Bool := False
}

If (PluginActive_Bool) {

	;Figure out GUI box size
	gui_orginaly := gui_y
	gui_y += 20
	gui_x = 30
	height = 0
	UptimeRobot_Array := []

	endboxsize := 100 * 1.4
	UptimeRobot_BoxSize := endboxsize


	;Read from .txt about what to monitor
	Loop, Read, % TxtFile
	{
		if (InStr(A_LoopReadLine,"UptimeRobotAPIKey:")) {
			APIKey := Fn_QuickRegEx(A_LoopReadLine,"UptimeRobotAPIKey:(\S+)")
		}
		if (InStr(A_LoopReadLine,";") || InStr(A_LoopReadLine,"//")) { ;Skip any ; or // line
			Continue
		}
		;Grab the Name and Url out of each line.
		The_SiteName := Fn_QuickRegEx(A_LoopReadLine,"Name:(\S+)")
		The_SiteURL := Fn_QuickRegEx(A_LoopReadLine,"KEY:(\S+)")
		;Create the Object for each
		msgbox, % The_SiteName "   " The_SiteURL
		if (The_SiteName != "null" && The_SiteURL != "null") {
			UptimeRobot%A_Index% := New UptimeRobot(APIKey)
			
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
			UptimeRobot%A_Index%.CreateButton(hWnd)
			
			;Add object to array for enumeration
			UptimeRobot_Array[A_Index] := UptimeRobot%A_Index%
		}
	}
	gui_y += endboxsize + 20

	;Draw Box around this plugin
	height += endboxsize + 30

	Gui, Font, s12 w700, Arial
	Gui, Add, GroupBox, x6 y%gui_orginaly% w980 h%height%, Sites2
	Gui, Font

	SetTimer, CheckUptimeRobot, 2000
}





;Plugin functions and classes-------------------------------


Sb_CheckUptimeRobot()
{
	global
	
	CheckUptimeRobot:
	SetTimer, CheckUptimeRobot, -60000
	;global SiteTop_Array
	
	endboxsize := UptimeRobot_BoxSize
	
	;Go through the list of sites
	Loop, % UptimeRobot_Array.MaxIndex() {
		;Get Status and Statistics of each
		UptimeRobot%A_Index%.SendRequest()
		
		;Update GUI Box of each
		UptimeRobot%A_Index%.UpdateGUI()

		;Report any errors
		if (UptimeRobot%A_Index%.ErrorCheck()) {
			Fn_ErrorCount(1)
		}
	}
	Fn_ErrorCount("report")
	Return
}



Class UptimeRobot {
	
	__New(para_APIKEY) {
		
		this.Info_Array := []
		this.Info_Array["Name"] := para_Name
		this.Info_Array["URL"] := para_URL
		this.APIKey := para_APIKEY ;Passed as parameter
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
	
	Draw(para_Text, para_Color, para_TextSize = 18) {
		global endboxsize
		TextArray := StrSplit(para_Text,"`n")
		
		critical
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
	
	SendRequest() {
		static BaseURL := "https://api.uptimerobot.com/getMonitors?apiKey=" UriEncode("u327426-ac75ccfb1e0b11a158f30e4d") "&responseTimes=1&responseTimesLimit=3" . "&format=json"
		
		msgbox, % BaseURL
		clipboard := BaseURL
		HTTP_Req := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		HTTP_Req.Open("GET", BaseURL, True)
		HTTP_Req.Send()
		Response := HTTP_Req.ResponseText
		
		File := FileOpen("temp.json", "w")
		File.Write(Response)
		File.Close()
		
		Result := Fn_JSONtoOBJ(Response)
		Array_GUI(Result)
		
		if !(Result := Fn_JSONtoOBJ(Response).responseData.results[1])
			return "No results found"
		Out := Fn_HtmlDecode(Result.titleNoFormatting)
	}

	CheckStatus() {
		;Download the page and try to understand what state it is in. ONLINE / MAINTENANCE / OTHER
		
		;Download Page to memory
		The_MemoryFile := ""

		;Try to download the page 4 times and quit on first success
		Loop, 4 {
			The_MemoryFile := Fn_DownloadtoFile(this.Info_Array["URL"])
			If (The_MemoryFile != "null" || A_Index = 4) {
				Break
			}
		}
		;Debug, check the downloaded HTML
			;Clipboard := The_MemoryFile
			;Msgbox, % this.Info_Array["Name"] . "`n`r" The_MemoryFile
		
		;Try to understand what state the page is in but assume "Check unsuccessful"
		this.Info_Array["CurrentStatus"] := "Unknown"
		
		;Normal Mainenance
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(maintenance\.tvg\.com\/)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "MaintenancePage"
		}

		;Outage
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(Service Unavailable)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Outage"
		}
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(503)") ;HTTP 503
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Outage"
		}

		;Online Status
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(<\/script>)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Online"
		}


		;SPECIAL CASES BELOW HERE: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		;Touch Sites
		if (InStr(this.Info_Array["Name"],"Touch")) {
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(!isAndroidApp)")

			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			}
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(please)")
			if (PageCheck = "please") {
				this.Info_Array["CurrentStatus"] := "MaintenancePage"
				return
			}
		}
		;HRTV
		if (InStr(this.Info_Array["Name"],"HRTV")) {
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(Wager NOW)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			}
		}
		if (InStr(this.Info_Array["Name"],"HRTV")) {
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(maintenance)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "MaintenancePage"
				return
			}
		}
		;Betfair
		if (InStr(this.Info_Array["Name"],"Betfair")) {
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(function)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			}
			PageCheck := Fn_QuickRegEx(The_MemoryFile,"(maintenance)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "MaintenancePage"
				return
			}
		}
		;CMS
		if (InStr(this.Info_Array["Name"],"cms")) {
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(Drupal)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			} else {
				this.Info_Array["CurrentStatus"] := "Offline"
			}
		}
		;Equibase Store
		if (InStr(this.Info_Array["Name"],"Eq-Store")) {
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(TRACK_ID=)")
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
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(accountDetails)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			} else {
				this.Info_Array["CurrentStatus"] := "Offline"
			}
		}
		;Event Collector
		if (InStr(this.Info_Array["Name"],"Event")) {
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(Untitled Page)")
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
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(<track name=)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			}
		}
		;Track Video Dropdown. Non-functional~~~~~~~~~~
		if (InStr(this.Info_Array["Name"],"Dropdown")) {
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(\[\])")
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