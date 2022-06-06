#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, force
#Persistent

SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

;******************************************************
;* User settings
;******************************************************

elevate:=0 ; Set to true to force the script to run as admin
alertOnErrors:=1 ; Show errors
runForever:=0 ; Runs the script forever (making sure new processes get adressed as well)

;******************************************************
;* Load the script with elevated rights
;******************************************************

if (elevate!=0)
  CheckOrElevate()

;******************************************************
;* Get list of processes
;******************************************************

processArray:=[]
processArray:=% GetProcessList() ; { PID: number, ProcessName: string }[]

;******************************************************
;* Modify affinity on all processes
;******************************************************

r:=FixProcesses()
if (r!="" && alertOnErrors!=0)
  Msgbox %r%

if (runForever!=0){
  Sleep 60*1000 ; 1 minute
  Reload ; Ugly hack :)
}
Return

;******************************************************
;* Functions
;******************************************************

FixProcesses(){

  feedback:=[]
  feedback.Push(ModifyProcess("dropbox", 1))
  feedback.Push(ModifyProcess("googlecrashhandler", 1))
  feedback.Push(ModifyProcess("everything", 1))
  feedback.Push(ModifyProcess("raidrive", 1))
  feedback.Push(ModifyProcess("spotify", 1)) 
  feedback.Push(ModifyProcess("displayfusion", 1))
  feedback.Push(ModifyProcess("DisplayFusionHookApp32", 1))
  feedback.Push(ModifyProcess("DisplayFusionService", 1))
  feedback.Push(ModifyProcess("mailbird", 1))

  ;******************************************************
  ;* Process feedback from ModifyProcess
  ;******************************************************

  result:=""
  for k, v in feedback{
    if (v!="")
      result:=result . (result!="" ? "; " : "" ) . v
  }

  return result

}

;******************************************************
;* Functions
;******************************************************

ModifyProcess(iProcessName, iAffinityMask:=1){

  local result:=""
  local pidArray:=FindProcessPIDArray(iProcessName)

  for index, pid in pidArray 
  {
    if (SetProcessAffinity(pid, iAffinityMask)==0)
      result:= result == "" ? result . iProcessName . " PID=" . pid : result . ", " . pid 
  }

  return result

}

FindProcessPIDArray(iProcessName){

  global processArray
  result:=[]

  for index, item in processArray 
  {
    if (InStr(item["ProcessName"], iProcessName))
      result.Push(item["PID"])
  }

  return result

}

SetProcessAffinity(iPID=0x0, iNewAffinityMask=255) { 

  local result:=0

  Process, Exist, %iPID%
  local PID:=iPID
  if (PID != 0) {

    local processHandle := DllCall("OpenProcess","UInt",1536,"Int",0,"Int", iPID) 
    DllCall( "GetProcessAffinityMask", "Int", processHandle, "IntP", ProcessAffinityMask, "IntP", SystemAffinityMask)
    If (iNewAffinityMask >0 && iNewAffinityMask<=SystemAffinityMask)
      result := DllCall( "SetProcessAffinityMask", "Int", processHandle, "Ptr", iNewAffinityMask)

    DllCall( "CloseHandle", "Int", processHandle)

  }

  Return result == 1 ? 1 : 0

}

CheckOrElevate(){ ; Checks if the script is running as Admin, and if it's not - it elevates

  If Not A_IsAdmin {
    Run, *RunAs %A_ScriptFullPath% ; Requires v1.0.92.01+
    ExitApp
  }

}

GetProcessList() {

  Local tPtr, pPtr,currentPid, currentProcess
  Local result=[]

  enumerateResult:=DllCall("Wtsapi32\WTSEnumerateProcesses", "Ptr", 0,"Int", 0, "Int", 1, "PtrP", pPtr, "PtrP", count)
  if (enumerateResult!=1)
    return result

  tPtr := pPtr
  Loop % (count) {
    currentPid:=NumGet( tPtr + 4, "UInt" ) ; DWORD ProcessId;
    currentProcess:=StrGet(NumGet(tPtr + 8)) ; LPSTR pProcessName
    result.push(Object("PID", currentPid, "ProcessName", currentProcess))
    tPtr += ( A_PtrSize = 4 ? 16 : 24 ) ; sizeof(WTS_PROCESS_INFO)
  }

  DllCall( "Wtsapi32\WTSFreeMemory", "Ptr", pPtr)

  Return result

}

; ^r::
;   Reload
; Return
