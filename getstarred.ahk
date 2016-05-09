/* 	GetStarred - creates symlink folder structure of starred photos from Picasa
	must be run as administrator!
*/
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
Clipboard = 	; Empty the clipboard
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.

slistpath := "C:\Users\TC\AppData\Local\Google\Picasa2\db3\starlist.txt"
path := "C:\Users\TC\Pictures\"
SetWorkingDir %path%

FileRemoveDir, starred, 1
FileCreateDir, starred

FileRead, starlist, %slistpath%
StringReplace, slLines, starlist, `n, `n, UseErrorLevel
slLines := ErrorLevel

loop, parse, starlist, `n
{
	picname := A_LoopField
	SplitPath, picname, picFname, picDir
	StringReplace, slDir, picDir, %path%photos\
	FileCreateDir, starred\%slDir%
	run, %ComSpec% /c mklink starred\%slDir%\%picFname% %picname%,, Hide
	Progress,% 100*(A_Index/slLines),%picFname%,%slDir%
}
Progress, Hide
MsgBox DONE!
