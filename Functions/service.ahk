/*
http://msdn.microsoft.com/en-us/library/bb540474%28VS.85%29.aspx

-i Computername* <- Install service
-r Computername* <- Start service
-s Computername* <- Stop service
-d Computername* <- Delete service

*/

#NoEnv
#SingleInstance Ignore
#Persistent
#NoTrayIcon

SendMode Input
SetWorkingDir %A_ScriptDir%
SetBatchLines -1

Version = 1.0
StartProgram = Notepad.exe						; Notepad.exe is used as an example for checking this using windows taskmanager. Enter any normal executable to start as a windows service

SERVICE_AUTO_START = 0x00000002
SERVICE_BOOT_START = 0x00000000
SERVICE_DEMAND_START = 0x00000003
SERVICE_DISABLED = 0x00000004
SERVICE_SYSTEM_START = 0x00000001

SERVICE_ERROR_CRITICAL = 0x00000003
SERVICE_ERROR_IGNORE = 0x00000000
SERVICE_ERROR_NORMAL = 0x00000001
SERVICE_ERROR_SEVERE = 0x00000002

SERVICE_CONTROL_CONTINUE = 0x00000003
SERVICE_CONTROL_INTERROGATE = 0x00000004
SERVICE_CONTROL_NETBINDADD = 0x00000007
SERVICE_CONTROL_NETBINDDISABLE = 0x0000000A
SERVICE_CONTROL_NETBINDENABLE = 0x00000009
SERVICE_CONTROL_NETBINDREMOVE = 0x00000008
SERVICE_CONTROL_PARAMCHANGE = 0x00000006
SERVICE_CONTROL_PAUSE = 0x00000002
SERVICE_CONTROL_STOP = 0x00000001

SERVICE_STOPPED = 0x00000001
SERVICE_START_PENDING = 0x00000002
SERVICE_STOP_PENDING = 0x00000003
SERVICE_RUNNING = 0x00000004
SERVICE_CONTINUE_PENDING = 0x00000005
SERVICE_PAUSE_PENDING = 0x00000006
SERVICE_PAUSED = 0x00000007
SERVICE_ACTIVE = 0x00000001
SERVICE_INACTIVE = 0x00000002
SERVICE_STATE_ALL = 0x00000003

SERVICE_ACCEPT_STOP = 0x00000001
SERVICE_ACCEPT_PAUSE_CONTINUE = 0x00000002
SERVICE_ACCEPT_SHUTDOWN = 0x00000004
SERVICE_ACCEPT_PARAMCHANGE = 0x00000008
SERVICE_ACCEPT_NETBINDCHANGE = 0x00000010
SERVICE_ACCEPT_HARDWAREPROFILECHANGE = 0x00000020
SERVICE_ACCEPT_POWEREVENT = 0x00000040
SERVICE_ACCEPT_SESSIONCHANGE = 0x00000080
SERVICE_ACCEPT_PRESHUTDOWN = 0x00000100

SERVICE_ADAPTER = 0x00000004
SERVICE_FILE_SYSTEM_DRIVER = 0x00000002
SERVICE_KERNEL_DRIVER = 0x00000001
SERVICE_RECOGNIZER_DRIVER = 0x00000008
SERVICE_WIN32_OWN_PROCESS = 0x00000010
SERVICE_WIN32_SHARE_PROCESS = 0x00000020

SERVICE_ALL_ACCESS = 0xF01FF
SERVICE_INTERROGATE = 0x0080
SERVICE_PAUSE_CONTINUE = 0x0040
SERVICE_QUERY_CONFIG = 0x0001
SERVICE_QUERY_STATUS = 0x0004
SERVICE_START = 0x0010
SERVICE_STOP = 0x0020

SERVICE_CONFIG_DESCRIPTION = 1
NO_ERROR = 0x0

SSP =
DesAccess = 0x2
DesiredAccess = 0xF003F
ServiceType := SERVICE_WIN32_OWN_PROCESS			; Change service type
StartType := SERVICE_AUTO_START						; Change service start type 
ErrorControl := SERVICE_ERROR_IGNORE
LoadOrderGroup =
TagId =
Dependencies =
ServiceStartName = 0								; Use 0 for service run as Local System
Password =											; Leave empty for service run as Local System

Description = AutoHotkey Service					; Change the service description
db_Name = AHK_Service								; Change the sevice name
Display_Name = AutoHotkey Service					; Change the service display name

StringTrimRight, s_NameValue, A_ScriptName, 4
p_NameValue = %A_WinDir%\%s_NameValue%.exe run		; Change the service location

If A_IsCompiled <> 1
	{
	MsgBox, Program is not compiled!
	ExitApp
	}

LinePar = %1%
m_Name = %2%

; ------------------------------------------------------------< Install Service >------------------------------------------------------------ 
If LinePar = -i
	{
	Open_SCManager(m_Name, db_Name, DesAccess)
	If Open_Service(sc_Handle, s_NameValue, SERVICE_INTERROGATE)
		ExitApp
	Else
		{
		Create_Service(sc_Handle, s_NameValue, Display_Name, DesiredAccess, ServiceType, StartType, ErrorControl, p_NameValue, LoadOrderGroup, TagId, Dependencies, ServiceStartName, Password)
		Description_Service(s_Handle, Description)
		Close_Service(sc_Handle, s_Handle)
		ExitApp
		}
	}

; ------------------------------------------------------------< Start Service >------------------------------------------------------------ 
If LinePar = -r
	{
	Open_SCManager(m_Name, db_Name, DesAccess)
	Open_Service(sc_Handle, s_NameValue, SERVICE_START)
	Start_Service(s_Handle)
	Close_Service(sc_Handle, s_Handle)
	ExitApp
	}

; ------------------------------------------------------------< Stop Service >------------------------------------------------------------ 
If LinePar = -s
	{
	Open_SCManager(m_Name, db_Name, DesAccess)
	Open_Service(sc_Handle, s_NameValue, SERVICE_STOP)
	Stop_Service(s_Handle)
	Close_Service(sc_Handle, s_Handle)
	ExitApp
	}

; ------------------------------------------------------------< Delete Service >------------------------------------------------------------ 
If LinePar = -d
	{
	Open_SCManager(m_Name, db_Name, DesAccess)
	Open_Service(sc_Handle, s_NameValue, SERVICE_ALL_ACCESS)
	Delete_Service(s_Handle)
	Close_Service(sc_Handle, s_Handle)	
	ExitApp
	}

; ------------------------------------------------------------< Run as Service >------------------------------------------------------------ 
If LinePar = run
	{
	VarSetCapacity(DispatchTable, 16, 0)		; Use for 32-bit Unicode compiler 
;	VarSetCapacity(DispatchTable, 32, 0)		; Use for 64-bit Unicode compiler
	SvcMainAddress := RegisterCallback("SvcMain")
	NumPut(&s_NameValue, DispatchTable, 0)
	NumPut(SvcMainAddress, DispatchTable, 4) 	; Use for 32-bit Unicode compiler
;	NumPut(SvcMainAddress, DispatchTable, 8)	; Use for 64-bit Unicode compiler
	cResult := DllCall("Advapi32\StartServiceCtrlDispatcher"
				, "UInt", &DispatchTable)
	KillResult := DllCall("User32.dll\KillTimer"
				, "UInt", 0
				, "UInt", UINT_PTR)
	ExitApp
	}

MsgBox, 64, %Description% %Version%, Usage %Description%:`n`n%s_NameValue%.exe -i Computername* `t <- Install service`n%s_NameValue%.exe -r Computername* `t <- Start service`n%s_NameValue%.exe -s Computername* `t <- Stop service`n%s_NameValue%.exe -d Computername* `t <- Delete service`n`n*Computername is optional.`n`nMake sure the file %A_WinDir%\%s_NameValue%.exe exists in on the (remote) machine running this service.
ExitApp

;-------------------------------------------------------------------------------------------------------------------------------------------------

SvcMain(dwArgc = 0, lpszArgv = 0)
	{
	Global
	Critical
	SvcCtrlHandlerAddress := RegisterCallback("SvcCtrlHandler")
	SvcStatusHandle := DllCall("Advapi32\RegisterServiceCtrlHandler"
				, "Str", s_NameValue
				, "UInt", SvcCtrlHandlerAddress)
	NumPut(SERVICE_WIN32_OWN_PROCESS, SvcStatus, 0)
	NumPut(0, SvcStatus, 16)
	ReportSvcStatus(SERVICE_START_PENDING, NO_ERROR, 3000)
	hSvcStopEvent := DllCall("CreateEvent"
				, "UInt", 0   
				, "UInt", TRUE
				, "UInt", FALSE 
				, "UInt", 0)   
	If hSvcStopEvent = 0
		{
		ReportSvcStatus(SERVICE_STOPPED, NO_ERROR, 0)
		Return
		}
    ReportSvcStatus(SERVICE_RUNNING, NO_ERROR, 0)
	ProgAddr := RegisterCallback("UserProg")
	UINT_PTR := DllCall("User32.dll\SetTimer"
				, "UInt", 0
				, "UInt", Timer_1
				, "UInt", 1000					; Change timer in ms
				, "UInt", ProgAddr)
	Sleep, 1000 								; Sleep is needed to activate timer (UserProg)
	cResult := DllCall("WaitForSingleObject"
				, "UInt", hSvcStopEvent
				, "UInt", -1)
	ReportSvcStatus(SERVICE_STOPPED, NO_ERROR, 0)
	Return   
	}

UserProg()
	{
	Global
	Critical
	Process, Exist, %StartProgram%
	If ErrorLevel = 0
		Run, %StartProgram%
	Return
	}

ReportSvcStatus(CurrentState, Win32ExitCode, WaitHint)
	{
	Global
	Static CheckPoint = 1
	NumPut(CurrentState, SvcStatus, 4)
	NumPut(Win32ExitCode, SvcStatus, 12)
	NumPut(WaitHint, SvcStatus, 24)
	If (CurrentState = SERVICE_START_PENDING)
		NumPut(0, SvcStatus, 8)
	Else
		NumPut(SERVICE_ACCEPT_STOP, SvcStatus, 8)
	If (CurrentState = SERVICE_RUNNING Or CurrentState = SERVICE_STOPPED)
		NumPut(0, SvcStatus, 20)
	Else
		NumPut(NumGet(SvcStatus, 20)+1, SvcStatus, 20)
	cResult := DllCall("Advapi32\SetServiceStatus"
				, "UInt", SvcStatusHandle
				, "UInt", &SvcStatus)
	CurState := NumGet(SvcStatus, 4)
	Return
	}

SvcCtrlHandler(dwCtrl)
	{
	Global
	Critical
	If (dwCtrl = SERVICE_CONTROL_STOP)
		{ 
		ReportSvcStatus(SERVICE_STOP_PENDING, NO_ERROR, 0)       
		CurrentState := NumGet(SvcStatus, 4)
		cResult := DllCall("SetEvent"
				, "UInt", hSvcStopEvent)
		ReportSvcStatus(SERVICE_STOPPED, NO_ERROR, 0)
		Return
	    }   
	Return
	}

SvcReportEvent(ByRef szFunction)
	{
	Global
	hEventSource = DllCall("Advapi32/RegisterEventSource"
				, "UInt", 0
				, "Str", s_Name)
	If hEventSource <> 0
		{
		DllCall("Advapi32/ReportEvent"
				, "UInt", hEventSource
				, "UInt", EVENTLOG_ERROR_TYPE
				, "UInt", 0
				, "UInt", SVC_ERROR
				, "UInt", NULL
				, "UInt", 2
				, "UInt", 0
				, "UInt", lpszStrings
				, "UInt", NULL)
		DllCall("Advapi32/DeregisterEventSource"
				, "UInt", hEventSource)
	    }
	Return
	}

Open_SCManager(m_Name, db_Name, DesAccess)
	{
	Global sc_Handle
	sc_Handle := DllCall("Advapi32\OpenSCManager"
				,"Str", m_Name
				,"UInt", db_Name
				,"Uint", DesAccess)
	Return sc_Handle
	}

Create_Service(sc_Handle, s_Name, d_Name, DesiredAccess, ServiceType, StartType, ErrorControl, p_Name, LoadOrderGroup = 0, TagId = 0, Dependencies = "", ServiceStartName = 0, Password = "")
	{
	Global s_Handle
	s_Handle := DllCall("Advapi32\CreateService"
				,"UInt", sc_Handle
				,"Str", s_Name
				,"Str", d_Name
				,"UInt", DesiredAccess
				,"Uint", ServiceType
				,"UInt", StartType
				,"UInt", ErrorControl
				,"Str", p_Name
				,"UInt", LoadOrderGroup
				,"UInt", TagId
				,"Str", Dependencies
				,"UInt", ServiceStartName
				,"Str", Password)
	Return s_Handle
	}

Start_Service(s_Handle)
	{
	Global
	cResult := DllCall("Advapi32\StartService"
				, "Uint", s_Handle
				, "Uint", 0
				, "Str", "")
	Return cResult
	}

Stop_Service(s_Handle)
	{
	Global
	VarSetCapacity(@SSP, 36)
	cResult := DllCall("Advapi32\ControlService"
				, "Uint", s_Handle
				, "Uint", 0x1
				, "Uint", &@SSP) 
	Return cResult
	}

Delete_Service(s_Handle)
	{
	Global
	cResult := DllCall("Advapi32\DeleteService"
				, "Uint", s_Handle)
	Return cResult
	}

Description_Service(s_Handle, Description)
	{
	Global
	cResult := DllCall("Advapi32\ChangeServiceConfig2"
				, "UInt", s_Handle
				, "UInt", 1               
				, "Str*", Description)
	Return cResult
	}

Open_Service(sc_Handle, s_NameValue, DesAccess)
	{
	Global
	s_Handle := DllCall("Advapi32\OpenService"
				, "UInt", sc_Handle
				, "Str", s_NameValue
				, "UInt", DesAccess )
	Return s_Handle
	}
	
Close_Service(sc_Handle, s_Handle)
	{
	DllCall("Advapi32\CloseServiceHandle"
				, "Uint", s_Handle)
	DllCall("Advapi32\CloseServiceHandle"
				, "Uint", sc_Handle)
	Return
	}