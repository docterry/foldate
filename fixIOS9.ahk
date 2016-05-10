/* fixIOS9 fixes broken IOS9 downloads
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.

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
		FileMove, %idxFull%, % destDir													; move file to proper folder
		;FileDelete, %idxDir%\.picasa.ini												; remove .picasa.ini files
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
		FileRemoveDir, %idxDir%
	}
}

MsgBox Done!
ExitApp

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

#Include strx.ahk
#Include Gdip_All.ahk
#Include Gdip_ImgProps.ahk