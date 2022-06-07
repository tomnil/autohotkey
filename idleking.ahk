#SingleInstance, force

;*****************************************
;* These hooks modify how idle time is measured
;* Search "A_TimeIdlePhysical" in documentation
;*****************************************

#InstallKeybdHook
#InstallMouseHook

;*****************************************
;* User settings - change these :)
;*****************************************

filename:="idleking.txt" ; File to write
saveTimeout:=1 ; Write file every n seconds 
idleLimit:=300 ; Number of before considered idle
uiIsVisible:=1 ; 0=Start invisible, 1=start visible
uiIsCentered:=0 ; 0=use lower right, 1=centered
uiIsAlwaysOnTop:=0 ; Makes the window topmost

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

;*****************************************
;* Developer variables
;*****************************************

isDeveloper:=0 ; Show dbug varible + reload & test button
dbug:="Hello world" ; Use to show anything
if (uiIsAlwaysOnTop==1)
    Gui,+AlwaysOnTop

;*****************************************
;* Initialize gui
;*****************************************

LoadFromFile()			; Load previous measurements
Measure() 				; Populate variables before first UI render
InitializeWindow()
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
    measureTimeStart:=now 	; Reset

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
    dbug=%dataSavedAt% _ %timeToSave% _ %workTime%
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

    Gui, Add, Text, x100 ys , numlock=ui on/off
    Gui, Add, Button, x100 y+0 gloadFileIntoNotepad, %filename%	
    Gui, Add, Text, x100 y+0 vtimePassed, LastMove: 00:00:00

    if (isDeveloper==1){
        Gui, Add, Text, x0 y60 , _________________________________________
        Gui, Add, Text, x10 y80 , Developer mode
        Gui, Add, Button, x10 y100 gReload_Button_Click, Reload	
        Gui, Add, Button, x60 y100 gTest, Test	
        Gui, Add, Text, xs y+0 vcurrentDbugLabel, DBUG: %dbug% ______
    }

}

UpdateWindow(){

    global ; Enable global access of all variables
    GuiControl,,currentDateLabel, %currentDate%
    GuiControl,,currentWorkLabel, % "Idle: " ToDateString(idleMilliSeconds)
    GuiControl,,currentIdleLabel, % "Work: " ToDateString(workMilliSeconds)
    GuiControl,,timePassed, % "LastMove: " ToDateString(A_TimeIdlePhysical)
    GuiControl,,currentDbugLabel, % dbug

}

MoveWindowToLowerRight(){

    Gui +LastFound
    WinGetPos, x, y, w, h
    x1 := A_ScreenWidth - w - 30
    y1 := A_ScreenHeight - h - 50
    WinMove, x1, y1

}

ShowHideUI(iShow:=1){

    global uiIsVisible, uiHasBeenMovedToLowerRight, uiIsCentered
    if (iShow==1){

        if (uiIsCentered==0)
            MoveWindowToLowerRight() 
        Gui, Show, w210 , IdleKing ; Will auto resize if show is after adding controls. Example with specific size: "Gui, Show, w200 h235, IdleKing"
        if (uiIsCentered==0)
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

loadFileIntoNotepad:

    global filename

    Run, Notepad %filename%
    WinWaitActive, ahk_class Notepad

return

;*****************************************
;* Keyboard hooks
;*****************************************

numlock::

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

; ^r::
;     Reload
; Return

Reload_Button_Click() {
    Reload
}

Test(){
    Msgbox Tripestep, triplestep, walk walk
}
