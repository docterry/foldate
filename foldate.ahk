/* FolDate recursive set Created and Modified dates of directory to name of folders
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
;SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

SplitPath, A_ScriptDir,,fileDir
IfInString, fileDir, AhkProjects					; Change enviroment if run from development vs production directory
{
	isDevt := true
	SetWorkingDir, C:\Users\%A_UserName%\Downloads\photos
} else {
	isDevt := false
	SetWorkingDir, %A_ScriptDir%
}

Loop, Files, *, D
{
	idxDir := A_LoopFileName
	if !(idxDir~="^\d{4}-\d{2}-\d{2}$")							; only process folders with name 2015-09-03 structure
		continue
	Loop, Files, %idxDir%\*
	{
		idxFull := A_LoopFileFullPath
		if (A_LoopFileExt != "jpg") 									; only process JPG files within those folders
			continue
		
		PropID := 0x9003 ; ExifDTOrig - Date & time of original
		GDIPToken := Gdip_Startup()
		GDIPImage := Gdip_LoadImageFromFile(idxFull)
		PropItem := Gdip_GetPropertyItem(GDIPImage, PropID)
		Gdip_DisposeImage(GDIPImage)
		Gdip_ShutDown(GDIPToken)
		dt := ExifBreakDT(PropItem.Value)
		if !(dt)
			continue
		destDir := dt.YR "-" dt.MO "-" dt.DY
		if !instr(FileExist(destDir),"D")
		{
			FileCreateDir, %destDir%
		}
		FileSetTime, dt.YR . dt.MO . dt.DY . dt.HR . dt.MIN . dt.SEC, %idxFull%, M		; set Modified date
		FileSetTime, dt.YR . dt.MO . dt.DY . dt.HR . dt.MIN . dt.SEC, %idxFull%, C		; set Created date
		FileMove, %idxFull%, % destDir										 			; move file to proper folder
	}
}

Loop, Files, *, D																		; Clean up empty dirs
{
	idxDir := A_LoopFileName															; ensure that we only process copied dirs
	if !(idxDir~="^\d{4}-\d{2}-\d{2}$")
		continue
	IfExist, %idxDir%\*.jpg																; keep folders with JPGs in them
	{
		continue
	} else {																			; delete ones without JPGs
		FileRemoveDir, %idxDir%, 1 
	}
}

loop, Files, * , D
{
	idxName := A_LoopFileName
	idxDir := A_LoopFileDir
	
	if RegExMatch(idxName,"^\d{4}\-\d{2}\-\d{2}$") {
		newDir := SubStr(idxName,1,7)
		newDirYR := "" . SubStr(idxName,1,4) . ""
		newDirMO := "" . SubStr(idxName,6,2) . ""
		newDirDY := "" . SubStr(idxName,9,2) . ""
		FileSetTime, newDirYR . newDirMO . newDirDY , %idxName% , C, 2
		
		IfNotExist %newDir% 
		{
			FileCreateDir, %newDir%
			FileSetTime, newDirYR . newDirMO , %newDir% , C, 2
			ctDir += 1
		}
		
		FileMoveDir, %idxName%, %newDir%\%newDirDY%
		FileSetTime, newDirYR . newDIRMO , %newDir% , M, 2
		ctMove += 1
	}
	if RegExMatch(idxName,"^\d{4}\-\d{2}$") {
		parseDate(idxName)
		chgDir += 1
	} 
	if RegExMatch(idxName,"^\d{2}$") {
		parseDate(idxDir, "" . idxName . "")
		chgSub += 1
	}
}

MsgBox,,Summary
	, % "Dirs created: " ctDir "`n"
	. "Dirs moved: " ctMove "`n"
	. "`n"
	. "Dir dates changed: " chgDir "`n"
	. "Sub dates changed: " chgSub
Exit

ExifBreakDT(dt) {
	if !RegExMatch(dt,"O)\b\d{4}[:/-]\d{2}[:/-]\d{2}\b",date)
		return Error
	if !RegExMatch(dt,"O)\b\d{2}[:/-]\d{2}[:/-]\d{2}\b",time)
		return Error
	dateY := strX(date.value,"",1,0,":",1,1,nn)
	dateM := strX(date.value,":",nn,1,":",1,1,nn)
	dateD := strX(date.value,":",nn,1,"",1)
	timeH := strX(time.value,"",1,0,":",1,1,nn)
	timeM := strX(time.value,":",nn,1,":",1,1,nn)
	timeS := strX(time.value,":",nn,1,"",1)
	return {YR:dateY,MO:dateM,DY:dateD,HR:timeH,MIN:timeM,SEC:timeS}
}

parseDate(nm,DY:="") {
	YR := SubStr(nm,1,4)
	MO := SubStr(nm,6,2)
	fnam := ((DY) ? nm . "\" . DY : nm)
	FileSetTime, YR . MO . DY , %fnam% , C, 2
	FileSetTime, YR . MO . DY , %fnam% , M, 2
return
}

#Include strx.ahk
#Include Gdip_All.ahk
#Include Gdip_ImgProps.ahk