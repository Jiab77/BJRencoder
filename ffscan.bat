@echo off
:: ffscan - Content scan Script
:: Made by Jonathan Barda <jonathan.barda@gmail.com>
:: Tested by Alexandre Panchout <alexandre.panchout@gmail.com>
:: Last Modification: 07/01/2017 - 00:51

mode con:cols=160 lines=60
setlocal EnableDelayedExpansion
for %%a in (cls echo) do %%a.

set file=%*

for %%f in (%file%) do (
	set fext=%%~xf
	set flname=%%~nxf
	set flpath=%%~dpf
	set fsname=%%~nf
)

if /i "!fext!"==".vob" (
	REM set probe_size=1000000k
	set probe_size=1G
) else (
	set probe_size=50M
)

title Analyzing [!flname! ^| Probe size: !probe_size!]...
set read_cmd=ffprobe -hide_banner -loglevel quiet -show_streams -show_format -print_format csv -probesize !probe_size! -analyzeduration !probe_size! -i %file%
for /f "tokens=1-26* delims=," %%a in ('!read_cmd!') do (
	if not "%%a"=="format" (
		set stream_%%f=%%b
		set codec_%%f=%%c

		echo Stream ID: [%%b] ^| Type: %%f
		echo ^   ^Codec ID: %%c
		echo ^   ^Codec name: %%d
		if /i "%%f"=="audio" (
			if /i not "%%e"=="unknown" (
				echo ^   ^Profile: %%e
			)
			echo ^   ^Rate: %%k Hz
			echo ^   ^Channels: %%l
			echo ^   ^Placement: %%m
		)
		if /i "%%f"=="video" (
			echo ^   ^Width: %%j pixels
			echo ^   ^Height: %%k pixels
			echo ^   ^Aspect ratio: %%p
			echo ^   ^Pixel format: %%q
			if /i not "%%e"=="unknown" (
				echo ^   ^Profile: %%e@L%%r
			)
			echo ^   ^Scan type: %%x
		)
	) else (
		echo.
		echo Path: !flpath!
		echo Filename: !flname!
		echo Container: %%g
		echo Duration: %%i second^(s^)
	)
)
title Analyzing [!flname! ^| Done]
echo. & pause
