#SingleInstance, force

;*****************************************
;* These hooks modify how idle time is measured
;* Search "A_TimeIdlePhysical" in documentation
;*****************************************

#InstallKeybdHook
#InstallMouseHook

;*****************************************
;* User settings in order of importance - change these :)
;*****************************************

uiIsVisible:=1 ; 0=Start invisible, 1=start visible
idleLimit:=300 ; Number of before considered idle
enableStayAwake:=1 ; If 1, the mouse will move a random direction every now and then
uiMoveWindowToLowerRight:=1 ; 1=always move to lower right, 0=centered start, but can be placed anywhere
uiIsAlwaysOnTop:=1 ; Makes the window topmost
saveTimeout:=30 ; Write file every n seconds 
filename:="idleking.txt" ; File to write
isDeveloper:=0 ; Show dbug varible + reload & test button

;*****************************************
;* Setup the tray
;*****************************************

Menu, Tray, Icon, %A_WinDir%\system32\shell32.dll, 44
Menu, Tray, Tip, IdleKing - A Simple Time Tracker`nPress numlock to see details

;*****************************************
;* Initialize global variables
;*****************************************

idleMilliSeconds:=0
workMilliSeconds:=0
state:="work"
measureTimeStart:=GetSystemTimeinMS()
dataSavedAt:=A_Now
uiHasBeenMovedToLowerRight:=0
FormatTime, currentDate, , yyyy-MM-dd
dbug:="Set variable dbug to print anything here..." ; Use to show anything

;*****************************************
;* Initialize gui
;*****************************************

LoadFromFile()			; Load previous measurements
Measure() 				; Populate variables before first UI render
InitializeWindow()
if (uiIsAlwaysOnTop==1)
    Gui,+AlwaysOnTop
UpdateWindow()
if (uiIsVisible==1)
    ShowHideUI(1) ; Enable ui and move to lower right

;*****************************************
;* Start the timer
;*****************************************

SetTimer, CheckTime, 900
return

CheckTime:

    Measure()

    if (uiIsVisible==1)
        UpdateWindow()

return

;*****************************************
;* Functions: Load and save from file
;*****************************************

LoadFromFile(){

    global currentDate, idleMilliSeconds, workMilliSeconds, filename
    IniRead, i, %filename%, %currentDate%, idleTime, 0
    IniRead, w, %filename%, %currentDate%, workTime, 0

    if (i)
        idleMilliSeconds:=StringToSeconds(i)*1000

    if (w)
        workMilliSeconds:=StringToSeconds(w)*1000

}

SaveToFile(){

    global currentDate, idleMilliSeconds, workMilliSeconds, filename
    global dataSavedAt

    dataSavedAt:=A_Now

    IniWrite, % ToDateString(idleMilliSeconds), %filename%, %currentDate%, idleTime
    IniWrite, % ToDateString(workMilliSeconds), %filename%, %currentDate%, workTime

}

;*****************************************
;* Functions: Measure
;*****************************************

Measure() {

    global currentDate, dataSavedAt,
    global idleLimit, workMilliSeconds, idleMilliSeconds, measureTimeStart, state
    global dbug

    ;*****************************************
    ;* Make sure the app works overnight
    ;*****************************************

    FormatTime, currentDate, , yyyy-MM-dd

    ;*****************************************
    ;* Calculate passed ms since last call to Measure()
    ;*****************************************

    now:=GetSystemTimeinMS()
    passedMs:=now-measureTimeStart
    if (passedMs>60*1000) ; more than one minute since last measurement? Probably the computer has been hibernated or similar
        passedMs:=0
    measureTimeStart:=now 	; Reset

    ;*****************************************
    ;* Stay awake
    ;*****************************************

    ; dbug=%A_TimeIdlePhysical% %A_TimeIdle% %enableStayAwake%
    if (enableStayAwake==1){
        if (A_TimeIdlePhysical>60000 && A_TimeIdle>30000) 
            StayAwake()
    }

    ;*****************************************
    ;* Store
    ;*****************************************

    if (state=="idle")
        idleMilliSeconds+=passedMs
    else
        workMilliSeconds+=passedMs

    ;*****************************************
    ;* State change?
    ;*****************************************

    if (A_TimeIdlePhysical > (idleLimit*1000))
        state:="idle"
    else
        state:="work"

    ;*****************************************
    ;* Store measured data every 10 seconds
    ;*****************************************

    timeToSave:=A_Now - dataSavedAt
    if (timeToSave>saveTimeout)
        SaveToFile()

}

;*****************************************
;* Functions: GUI Functions
;*****************************************

InitializeWindow(){

    global ; Enable global access of all variables
    Gui, Add, Text, x10 y10 vcurrentDateLabel, Date: %currentDate%
    Gui, Add, Text, xs y+2 vcurrentWorkLabel, Idle: 00:00:00 ; Create placeholder for text
    Gui, Add, Text, xs y+2 vcurrentIdleLabel, Work: 00:00:00

    Gui, Add, Text, x100 ys , Current Idle
    Gui, Add, Text, x100 y+2 vtimePassedLabel, 00:00:00
    Gui, Add, Text, x100 y+2 vstayAwakeIsOnLabel, StayAwake: %enableStayAwake%

    if (isDeveloper==1){
        Gui, Add, Text, x0 y60 , _________________________________________
        Gui, Add, Text, x10 y80 , Developer mode
        Gui, Add, Button, x10 y100 gReload_Button_Click, Reload	
        Gui, Add, Button, x60 y100 gTest, Test	
        Gui, Add, Text, xs y+0 vcurrentDbugLabel, DBUG: %dbug% ______
    }

    Menu, FileMenu, Add, Open log 'idleking.txt', loadFileIntoNotepad
    Menu, FileMenu, Add, Stay Awake (toggle with F11), F11
    Menu, FileMenu, Add, Hide UI (toggle with F12), F12
    Menu, FileMenu, Add, , DoNothingHandler
    Menu, FileMenu, Add, Written by Tomas Nilsson, DoNothingHandler
    Menu, FileMenu, Add, Source: https://github.com/tomnil, DoNothingHandler
    Menu, MyMenuBar, Add, &File, :FileMenu
    Gui, Menu, MyMenuBar

}

DoNothingHandler:
return

UpdateWindow(){

    global ; Enable global access of all variables
    GuiControl,,currentDateLabel, %currentDate%
    GuiControl,,currentWorkLabel, % "Idle: " ToDateString(idleMilliSeconds)
    GuiControl,,currentIdleLabel, % "Work: " ToDateString(workMilliSeconds)
    GuiControl,,timePassedLabel, % ToDateString(A_TimeIdlePhysical)
    GuiControl,,stayAwakeIsOnLabel, StayAwake: %enableStayAwake%

    if (isDeveloper==1){
        GuiControl,,currentDbugLabel, % dbug
    }

}

MoveWindowToLowerRight(){

    Gui +LastFound
    WinGetPos, x, y, w, h
    x1 := A_ScreenWidth - w - 30
    y1 := A_ScreenHeight - h - 50
    WinMove, x1, y1

}

ShowHideUI(iShow:=1){

    global uiIsVisible, uiHasBeenMovedToLowerRight, uiMoveWindowToLowerRight
    if (iShow==1){

        if (uiMoveWindowToLowerRight==1)
            MoveWindowToLowerRight() 
        Gui, Show, w210 , IdleKing ; Will auto resize if show is after adding controls. Example with specific size: "Gui, Show, w200 h235, IdleKing"
        if (uiMoveWindowToLowerRight==1)
            MoveWindowToLowerRight() ;   Called twice to try to remove centered popup

        uiIsVisible:=1

    }
    else{
        Gui, Hide ; Will auto resize if show is after adding controls. Example with specific size: "Gui, Show, w200 h235, IdleKing"
        uiIsVisible:=0
    }

}

;*****************************************
;* Functions: Date helper functions
;*****************************************

ToDateString(n, unit ="ms" ) ; Convert seconds to hh:mm:ss
{
    switch unit
    {
    case "ms":
        s:=n/1000
    case "s":
        s:=n
    case "h":
        s:=n*3600
    default:
        Msgbox "Not supported"
    }

    Time := 19990101 ; *Midnight* of an arbitrary date
    Time += %s%, seconds
    FormatTime, result, %Time%, HH':'mm':'ss
    Return result

}

StringToSeconds(iString){

    split := StrSplit(iString, ":")
    result := split.1 * 3600 + split.2 * 60 + split.3
    return result
}

GetSystemTimeinMS(){

  /*
   NOTE: Ignores regional settings, summer time settings and so forth
   SYSTEMTIME is definition: https://docs.microsoft.com/en-us/windows/win32/api/minwinbase/ns-minwinbase-systemtime
    */

    local SYSTEMTIME
    VarSetCapacity(SYSTEMTIME, 16, 0)
    DllCall("kernel32.dll\GetSystemTime", "Ptr", &SYSTEMTIME, "Ptr")

    seconds:=NumGet(SYSTEMTIME, 8, "UShort")*3600 + NumGet(SYSTEMTIME, 10, "UShort")*60 + NumGet(SYSTEMTIME, 12, "UShort")
    ms:=NumGet(SYSTEMTIME, 14, "UShort")

    return seconds * 1000 + ms

}

;*****************************************
;* Keyboard hooks
;*****************************************

StayAwake(){

    Random, randomX, -3, 3
    Random, randomY, -3, 3
    MouseMove, randomX, randomY, , R
}

;*****************************************
;* Keyboard hooks
;*****************************************

loadFileIntoNotepad:

    global filename

    Run, Notepad %filename%
    WinWaitActive, ahk_class Notepad

return

;*****************************************
;* Keyboard hooks
;*****************************************

F11::

    global enableStayAwake, dbug

    enableStayAwake:=enableStayAwake == 1 ? 0 : 1
return

F12::

    global uiIsVisible
    if (uiIsVisible==0)
        ShowHideUI(1)
    else
        ShowHideUI(0)

Return

;*****************************************
;* Shutdown handler
;*****************************************

GuiClose: 		; Automatically runs on close app
ExitApp
return

;*****************************************
;* Developer stuff
;*****************************************

Reload_Button_Click() {
    Reload
}

Test(){
    Msgbox Tripestep, triplestep, walk walk
}

;^r::
;    Reload
;Return
