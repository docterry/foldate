/*	FixMOV
		- Scan Pictures/Photos/YYYY-MM/DD folders for video: MOV, AVI, MTS
		- Convert to MP4
		- Maintain metadata and/or creation timestamp
		- Delete original file
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir%
FileInstall, exiftool.exe, exiftool.exe

photoDir := A_MyDocuments "\..\Pictures\photos"
ffmpeg := "c:\Programs\ffmpeg\ffmpeg.exe"

loop, Files, %photoDir%\*, FR
{
	fext := A_LoopFileExt
	if !(fext~="i)AVI|MOV|MTS") {													; skip non-video types
		continue
	}
	
	fnam := A_LoopFileName																; fnam = filename only
	fullname := A_LoopFileLongPath														; fullname = full path + filename
	Dir := strX(A_LoopFileDir,"Pictures\",1,9,"",0)										; dir = 2017-03\11
	SplashImage,,,% dir "\" fnam, Processing file

	DirY := strX(Dir,"",1,0,"-",1,1)													; 2017
	DirM := strX(Dir,"-",1,1,"\",1,1)													; 03
	DirD := strX(Dir,"\",1,1,"",0)														; 11
	
	FileGetTime, fileDT, %fullname%, C													; fileDT = file creation DT
	
	dt := getExifDate(fullname)															; fetch CreationDate > CreateDate > DateTimeOriginal
	exifTS := dt.YYYY . dt.MM . dt.DD . dt.hr . dt.min . dt.sec
	ffcodec := 
	
	SplashImage, off
	FileDelete, dump.txt
	FileAppend, % dt.txt, dump.txt
	if (readVal("CompressorID",dt.txt)) {												; proper MOV files
		ffcodec := "-vcodec h264 -map_metadata 0 "
	}
	if (readVal("VideoStreamType",dt.txt)) {											; MTS has no metadata
		ffcodec := "-vcodec h264 -metadata ""creation_time=" dt.YYYY "-" dt.MM "-" dt.DD " " dt.hr ":" dt.min ":" dt.sec """ "
	}
	if (readVal("VideoCodec",dt.txt)) {													; AVI files
		ffcodec := "-vcodec h264 -pix_fmt yuv420p -crf 18 -map_metadata 0 "
	}
	if (ffcodec="") {
		MsgBox no codec
		continue
	}
	
	newName := RegExReplace(fullname,fExt,"mp4")
	
	RunWait, %ffmpeg% -i %fullname% %ffcodec% -hide_banner -strict -2 %newName%
	FileSetTime, exifTS, %newName%, C
	FileSetTime, exifTS, %newName%, M
	
	MsgBox, 52, Delete, % "Remove original?`n`n" Dir "\" fnam
	IfMsgBox, Yes
	{
		FileDelete, %fullname%
	}
}
ExitApp

getExifDate(fn) {
	RunWait %A_ScriptDir%\exiftool.exe -f -w! txt -S %fn% ,, Hide
	fnTxt := strX(fn,"",1,0,".",0) ".txt"
	FileRead, txt, %fnTxt%
	FileDelete, %fnTxt%
	
	if (cdate := readVal("CreationDate",txt)) {
	} else if (cdate := readVal("MediaCreateDate",txt)) {
	} else if (cdate := readVal("CreateDate",txt)) {
	} else if (cdate := readVal("DateTimeOriginal",txt)) {
	}
	dt := BreakDate(trim(cdate))
	dt.txt := txt
	return dt
}

readVal(lbl,txt) {
	x := stregX(txt,"^" lbl ":",1,1,"[-\r\n]+",1)
	return x
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
#Include CMsgBox.ahk
#Include Gdip_All.ahk
#Include Gdip_ImgProps.ahk