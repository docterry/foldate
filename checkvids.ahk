/*	CheckVids
		- Scan Photos/YYYY-MM/DD folders for video: MOV, AVI, MTS
		- Check file mod/created date
		- Check exiftool for creation date
		- Move and set Created and Modified dates if needed
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%
FileInstall, exiftool.exe, exiftool.exe

photoDir := A_MyDocuments "\..\Pictures\photos"

loop, Files, %photoDir%\*, FR
{
	if !(A_LoopFileExt~="i)MOV|AVI|MP4|MTS") {
		continue
	}
	Dir := strX(A_LoopFileDir,"photos\",1,7,"",0)
	DirYM := strX(Dir,"",1,0,"\",1,1)
	DirYYYY := strX(DirYM,"",1,0,"-",1,1)
	DirMM := strX(DirYM,"-",1,1,"",0)
	DirDD := strX(Dir,"\",1,1,"",0)
	
	fnam := A_LoopFileName
	fullname := A_LoopFileLongPath
	dt := getExifDate(fullname)
	
	if !(Dir = dt.YYYY "-" dt.MM "\" dt.DD) {
		FileDelete, text.txt
		FileAppend, % dt.txt, text.txt
		MsgBox,,% Dir "\" fnam
			, % dt.YYYY "-" dt.MM "-" dt.DD "`n"
			. dt.hr ":" dt.min ":" dt.sec
	}
}
ExitApp

Loop, Files, *, D
{
	idxDir := A_LoopFileName
	if !(idxDir~="^\d{4}-\d{2}-\d{2}$") {												; only process folders with name 2015-09-03 structure
		continue
	}
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
			SplashImage,,,%idxFile%, Processing MOV
			RunWait %A_ScriptDir%\exiftool.exe -w! txt -CreationDate -S %idxFull% ,, Hide
			exifTxt := RegExReplace(idxFull,"i)mov$") "txt"
			FileRead, cdate, %exifTxt%
			FileDelete %exifTxt%
			dt := ExifBreakDT(cdate)
		} 
		if !IsObject(dt) {																; no date, skip
			continue
		}
		
		destDir := dt.YR "-" dt.MO "-" dt.DY											; ensure there is a proper destDir
		
		if !instr(FileExist(destDir),"D") {
			FileCreateDir, %destDir%													; create destDir for each file as needed
		}
		
		FileSetTime, dt.YR . dt.MO . dt.DY . dt.HR . dt.MIN . dt.SEC, %idxFull%, M		; set Modified date
		FileSetTime, dt.YR . dt.MO . dt.DY . dt.HR . dt.MIN . dt.SEC, %idxFull%, C		; set Created date
		if (destDir=idxDir) { 															; already in correct folder, skip move
			continue
		}
		FileMove, %idxFull%, % destDir													; move file to proper folder
	}
}
SplashImage,,,, Cleaning folders

Loop, Files, *, D																		; Clean up empty dirs
{
	idxDir := A_LoopFileName															; ensure that we only process copied dirs
	if (idxDir~="^\d{4}-\d{2}-\d{2}$") {
		FileDelete, %idxDir%\.picasa.ini												; remove .picasa.ini files
		FileRemoveDir, %idxDir%															; remove completely empty folders
	}
}

loop, Files, * , D																		; move the yyyy-mm-dd folders into yy-mm/dd structure
{
	idxName := A_LoopFileName
	idxDir := A_LoopFileDir
	SplashImage,,,, Converting folder dates
	
	if RegExMatch(idxName,"^\d{4}\-\d{2}\-\d{2}$") {									; idxName matches yyyy-mm-dd
		newDir := SubStr(idxName,1,7)													; newDir is yyyy-mm
		newDirYR := "" . SubStr(idxName,1,4) . ""
		newDirMO := "" . SubStr(idxName,6,2) . ""
		newDirDY := "" . SubStr(idxName,9,2) . ""
		FileSetTime, newDirYR . newDirMO . newDirDY , %idxName% , C, 2					; set creation date of folder to match name
		
		IfNotExist %newDir% 															; newDir does not exist?
		{
			FileCreateDir, %newDir%														; create it
			FileSetTime, newDirYR . newDirMO , %newDir% , C, 2							; and set created date to yyyymm
			ctDir += 1																	; increment created dir counter
		}
		
		FileMoveDir, %idxName%, %newDir%\%newDirDY%, 2									; move proper dir into the newdir, don't fail if exists
		FileSetTime, newDirYR . newDirMO . newDirDY , %newDir%\%newDirDY% , M, 2		; adjust mod date for newDir\DY
		FileSetTime, newDirYR . newDIRMO , %newDir% , M, 2								; adjust mod date for newDir
		ctMove += 1																		; increment moved dir counter
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
SplashImage, off

MsgBox,,Summary
	, % "Dirs created: " ctDir "`n"
	. "Dirs moved: " ctMove "`n"
	. "`n"
	. "Dir dates changed: " chgDir "`n"
	. "Sub dates changed: " chgSub
Exit

getExifDate(fn) {
	SplashImage,,,%fn%, Processing file
	RunWait %A_ScriptDir%\exiftool.exe -f -w! txt -S %fn% ,, Hide
	fnTxt := strX(fn,"",1,0,".",0) ".txt"
	FileRead, txt, %fnTxt%
	FileDelete, %fnTxt%
	
	if (cdate := readVal("CreationDate",txt)) {
	} else if (cdate := readVal("CreateDate",txt)) {
	} else if (cdate := readVal("DateTimeOriginal",txt)) {
	}
	dt := BreakDate(trim(cdate))
	dt.txt := txt
	return dt
}

readVal(lbl,txt) {
	x := stregX(txt,"^" lbl ":",1,1,"[\r\n]+",1)
	return x
}

ExifBreakDT(dt) {
	if !RegExMatch(dt,"O)\b\d{4}[:/-]\d{2}[:/-]\d{2}\b",date) {
		return Error
	}
	if !RegExMatch(dt,"O)\b\d{2}[:/-]\d{2}[:/-]\d{2}\b",time) {
		return Error
	}
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

BreakDate(x) {
; Disassembles "2/9/2015" or "2/9/2015 8:31" into Yr=2015 Mo=02 Da=09 Hr=08 Min=31
	mo := ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
	
; 03 Jan 2016
	if (x~="i)(\d{1,2})[\-\s\.](Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[\-\s\.](\d{2,4})") {
		StringSplit, DT, x, %A_Space%-.
		return {"DD":zDigit(DT1), "MM":zDigit(objHasValue(mo,DT2)), "MMM":DT2, "YYYY":year4dig(DT3)}
	}
	
; 03_06_17 or 03_06_2017
	if (x~="\d{1,2}_\d{1,2}_\d{2,4}") {
		StringSplit, DT, x, _
		return {"MM":zDigit(DT1), "DD":zDigit(DT2), "MMM":mo[DT2], "YYYY":year4dig(DT3)}
	}
	
; 2017-02-11
	if (x~="\d{4}-\d{2}-\d{2}") {
		StringSplit, DT, x, -
		return {"YYYY":DT1, "MM":DT2, "DD":DT3}
	}
	
; 2017:03:17 (19:42:37)?
	if (x~="\d{4}:\d{2}:\d{2}") {
		StringSplit, DT, x, %A_Space%
		StringSplit, D, DT1, :
		StringSplit, T, DT2, :
		return {"YYYY":D1,"MM":D2,"DD":D3
				,"hr":T1,"min":T2,"sec":T3}
	}
; Mar 9, 2015 (8:33 am)?
	if (x~="i)^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) \d{1,2}, \d{4}") {
		StringSplit, DT, x, %A_Space%
		StringSplit, DHM, DT4, :
		return {"MM":zDigit(objHasValue(mo,DT1)),"DD":zDigit(trim(DT2,",")),"YYYY":DT3
			,	hr:zDigit((DT5~="i)p")?(DHM1+12):DHM1),min:DHM2}
	}
	
	StringSplit, DT, x, %A_Space%
	StringSplit, DY, DT1, /
	StringSplit, DHM, DT2, :
	return {"MM":zDigit(DY1), "DD":zDigit(DY2), "YYYY":year4dig(DY3), "hr":zDigit(DHM1), "min":zDigit(DHM2), "Date":DT1, "Time":DT2}
}

year4dig(x) {
	if (StrLen(x)=4) {
		return x
	}
	if (StrLen(x)=2) {
		return (x<50)?("20" x):("19" x)
	}
	return error
}

zDigit(x) {
; Add leading zero to a number
	return SubStr("0" . x, -1)
}

stRegX(h,BS="",BO=1,BT=0, ES="",ET=0, ByRef N="") {
/*	modified version: searches from BS to "   "
	h = Haystack
	BS = beginning string
	BO = beginning offset
	BT = beginning trim, TRUE or FALSE
	ES = ending string
	ET = ending trim, TRUE or FALSE
	N = variable for next offset
*/
	;~ BS .= "(.*?)\s{3}"
	rem:="^[OPimsxADJUXPSC(\`n)(\`r)(\`a)]+\)"										; All the possible regexmatch options
	
	pos0 := RegExMatch(h,((BS~=rem)?"Oim"BS:"Oim)"BS),bPat,((BO)?BO:1))
	/*	Ensure that BS begins with at least "Oim)" to return [O]utput, case [i]nsensitive, and [m]ultiline searching
		Return result in "bPat" (beginning pattern) object
		If (BO), start at position BO, else start at 1
	*/
	pos1 := RegExMatch(h,((ES~=rem)?"Oim"ES:"Oim)"ES),ePat,pos0+bPat.len())
	/*	Ensure that ES begins with at least "Oim)"
		Resturn result in "ePat" (ending pattern) object
		Begin search after bPat result (pos0+bPat.len())
	*/
	bmod := (BT) ? bPat.len() : 0
	emod := (ET) ? 0 : ePat.len()
	N := pos1+emod
	/*	Final position is start of ePat match + modifier
		If (ET), add nothing, else add ePat.len()
	*/
	return substr(h,pos0+bmod,(pos1+emod)-(pos0+bmod))
	/*	Start at pos0
		If (BT), add bPat.len(), else stay at pos0 (will include BS in result)
		substr length is position of N (either pos1 or include ePat) less starting pos0
	*/
}

ObjHasValue(aObj, aValue, rx:="") {
; modified from http://www.autohotkey.com/board/topic/84006-ahk-l-containshasvalue-method/	
	if (rx="med") {
		med := true
	}
    for key, val in aObj
		if (rx) {
			if (med) {													; if a med regex, preface with "i)" to make case insensitive search
				val := "i)" val
			}
			if (aValue ~= val) {
				return, key, Errorlevel := 0
			}
		} else {
			if (val = aValue) {
				return, key, ErrorLevel := 0
			}
		}
    return, false, errorlevel := 1
}

#Include strx.ahk
#Include Gdip_All.ahk
#Include Gdip_ImgProps.ahk