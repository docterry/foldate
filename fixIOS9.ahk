/* fixIOS9 fixes broken IOS9 downloads
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
FileInstall, exiftool.exe, exiftool.exe

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
		dt :=
		idxFull := A_LoopFileFullPath
		idxFile := A_LoopFileName
		idxExt := A_LoopFileExt
		if (idxExt = "jpg") { 															; process JPG files within those folders
			SplashImage,,,%idxFile%, Processing JPG
			PropID := 0x9003 ; ExifDTOrig - Date & time of original
			GDIPToken := Gdip_Startup()
			GDIPImage := Gdip_LoadImageFromFile(idxFull)
			PropItem := Gdip_GetPropertyItem(GDIPImage, PropID)
			Gdip_DisposeImage(GDIPImage)
			Gdip_ShutDown(GDIPToken)
			dt := ExifBreakDT(PropItem.Value)
		} 
		if (idxExt = "mov") {															; process MOV files
			SplashImage,,,%idxFile%, Processing JPG
			RunWait %A_ScriptDir%\exiftool.exe -w! txt -CreateDate -S %idxFull% ,, Hide
			exifTxt := RegExReplace(idxFull,"i)mov$") "txt"
			FileRead, cdate, %exifTxt%
			FileDelete %exifTxt%
			dt := ExifBreakDT(cdate)
		} 
		if !(dt)																		; no date, skip
			continue
		
		destDir := dt.YR "-" dt.MO "-" dt.DY
		
		if !instr(FileExist(destDir),"D")
		{
			FileCreateDir, %destDir%
		}
		FileSetTime, dt.YR . dt.MO . dt.DY . dt.HR . dt.MIN . dt.SEC, %idxFull%, M		; set Modified date
		FileSetTime, dt.YR . dt.MO . dt.DY . dt.HR . dt.MIN . dt.SEC, %idxFull%, C		; set Created date
		if (destDir=idxDir) 															; already in correct folder, skip move
			continue
		FileMove, %idxFull%, % destDir													; move file to proper folder
	}
}
SplashImage, off

Loop, Files, *, D																		; Clean up empty dirs
{
	idxDir := A_LoopFileName															; ensure that we only process copied dirs
	if (idxDir~="^\d{4}-\d{2}-\d{2}$") {
		FileDelete, %idxDir%\.picasa.ini												; remove .picasa.ini files
		FileRemoveDir, %idxDir%															; remove completely empty folders
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
