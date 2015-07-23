;global ALF := new CustomButton(hWnd)
;ALF.Draw



gui_orginaly := gui_y
gui_y += 20
gui_x = 30
height = 0
SiteTop_Array := []

endboxsize := 100 * 1.4
Site_BoxSize := endboxsize
;Read from DVR.txt about what DVRs to monitor
Loop, Read, %A_ScriptDir%\plugins\Sites.txt
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
		
		;Create GUI box for each DVR
		Gui, Add, Progress, x%gui_x% y%gui_y% w%endboxsize% h%endboxsize% hWndhWnd, 100
		Gui, Show, w1000 , %The_ProjectName%
		gui_x += endboxsize + 10
		
		if (gui_x >= 870) {
			gui_x = 30
			gui_y += endboxsize + 10
			height += endboxsize + 30
		}
		;Change to a re-drawable gui for the Site
		Site%A_Index%.CreateButton(hWnd)
		
		;Add object to array for enumeration
		SiteTop_Array[A_Index] := Site%A_Index%
	}
}
gui_y += endboxsize + 20

;Draw Box around this plugin
height += endboxsize

Gui, Font, s12 w700, Arial
Gui, Add, GroupBox, x6 y%gui_orginaly% w980 h%height%, Sites
Gui, Font

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
	global
	
	CheckSites:
	SetTimer, CheckSites, -60000
	;global SiteTop_Array
	
	endboxsize := Site_BoxSize
	
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
		If (CurrentStatus = "MainenancePage") {
			this.Draw("MAINT PAGE" . CombinedText, Fn_RGB("0xFF6600"), 22) ;Orange MAINT PAGE
			Return
		}
		;All others failed
		this.Draw("Check Unsuccessful" . CombinedText, Fn_RGB("0xFFFFFF"), 22) ;White Check Unsuccessful
	}
	
	DrawDefault()
	{
		this.Draw("Unchecked" . CombinedText, Fn_RGB("0xFFFFFF"), 22) ;White Unchecked
	}
	
	Draw(para_Text, para_Color, para_TextSize = 18)
	{
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

		;Try to download the page 4 times and quit on first success
		Loop, 4 {
			The_MemoryFile := Fn_DownloadtoFile(this.Info_Array["URL"])
			If (The_MemoryFile != "null" || A_Index = 4) {
				Break
			}
		}
		
		;Try to understand what state the page is in but assume "Check unsuccessful"
		this.Info_Array["CurrentStatus"] := "Unknown"
		
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(maintenance\.tvg\.com\/)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "MainenancePage"
		}
		PageCheck := Fn_QuickRegEx(The_MemoryFile, "(\/\/nodejs\.tvg\.com\/deposit\/quick)")
		if (PageCheck != "null") {
			this.Info_Array["CurrentStatus"] := "Online"
		}
		;SPECIAL CASES BELOW HERE: ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
		;Touch Sites
		if (InStr(this.Info_Array["Name"],"Touch")) {
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(!isAndroidApp)")
			Clipboard := PageCheck
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			}
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(null)")
			if (PageCheck = "null") {
				this.Info_Array["CurrentStatus"] := "MainenancePage"
				return
			}
		}
		;HRTV
		if (InStr(this.Info_Array["Name"],"HRTV")) {
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(Follow HRTV)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
			}
		}
		;Betfair
		if (InStr(this.Info_Array["Name"],"Betfair")) {
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(function openLobby)")
			if (PageCheck != "null") {
				this.Info_Array["CurrentStatus"] := "Online"
				return
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
		;Track Video Dropdown. Non-functional
		if (InStr(this.Info_Array["Name"],"Dropdown")) {
			Msgbox, % The_MemoryFile
			PageCheck := Fn_QuickRegEx(The_MemoryFile, "(\[\])")
			if (PageCheck = "null") {
				this.Info_Array["CurrentStatus"] := "Online"
			} else if (PageCheck = "[]") {
				this.Info_Array["CurrentStatus"] := "Offline"
			}
		}
	}
}