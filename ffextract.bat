@echo off
:: BJRencoder - Encoding Script
:: Made by Jonathan Barda <jonathan.barda@gmail.com>
:: Tested by Alexandre Panchout <alexandre.panchout@gmail.com>
:: Last Modification: 07/01/2017 - 00:06

:: Shell settings
setlocal EnableDelayedExpansion
set debug=true
if /i not "%debug%"=="true" (
	mode con:cols=160 lines=60
)
for %%a in (cls echo) do %%a.

:: Script settings
set file=%*
set iteration=0
set tracks=0

:: Reading file information
for %%f in (%file%) do (
	set fext=%%~xf
	set flname=%%~nxf
	set flpath=%%~dpf
	set fsname=%%~nf
)

:: Define probe size
if /i "!fext!"==".vob" (
	REM set probe_size=1000000k
	set probe_size=1G
) else (
	set probe_size=50M
)

:: Reading file structure
title Analyzing [!flname! ^| Probe size: !probe_size!]...
set read_cmd=ffprobe -hide_banner -loglevel quiet -show_streams -show_format -print_format csv -probesize !probe_size! -analyzeduration !probe_size! -i %file%
for /f "tokens=1-26* delims=," %%a in ('!read_cmd!') do (
	REM Looking for streams
	if not "%%a"=="format" (
		REM Init stream counter
		set /a tracks += 1

		REM Reading stream properties
		set stream_%%f=%%b
		set codec_%%f=%%c
		set ext_%%f=%%c

		REM Adjusting on stream codec
		if /i "%%c"=="subrip" (
			set ext_subtitle=srt
			set stream_subtitle=%%b
		) else if /i "%%c"=="dvdsub" (
			set ext_subtitle=srt
			set stream_subtitle=%%b
		) else if /i "%%c"=="mpeg2video" (
			set ext_video=mpg
		) else if /i "%%c"=="truehd" (
			set ext_audio=thd
		)

		REM Now showing stream informations
		echo Stream ID: [%%b] ^| Type: %%f
		echo ^   ^Codec ID: %%c
		echo ^   ^Codec name: %%d

		REM Adjusting on stream type
		REM -- Audio stream
		if /i "%%f"=="audio" (
			if /i "!ext_audio!"=="dts" (
				if /i "%%e"=="DTS-HD MA" (
					set audio_profile=-profile:a dts_hd_ma
				) else if /i "%%e"=="DTS-HD HRA" (
					set audio_profile=-profile:a dts_hd_hra
				) else (
					set audio_profile=-profile:a dts
				)
				set audio_options=-strict -2
			) else (
				set audio_options=
				set audio_profile=
			)

			set ext_cmd_audio_%%b=ffmpeg -y -i %file% -map 0:!stream_audio! -vn !audio_profile! -c:a copy !audio_options! -threads 0 !flpath!%%b_!fsname!.!ext_audio!

			if /i not "%%e"=="unknown" (
				echo ^   ^Profile: %%e
			)

			echo ^   ^Rate: %%k Hz
			echo ^   ^Channels: %%l
			echo ^   ^Placement: %%m
			if /i "%debug%"=="true" (
				echo ^   ^Command:
				if defined stream_audio echo !ext_cmd_audio_%%b!
			)
		)

		REM -- Video stream
		if /i "%%f"=="video" (
			set ext_cmd_video_%%b=ffmpeg -y -i %file% -map 0:!stream_video! -an -c:v copy -threads 0 !flpath!%%b_!fsname!.!ext_video!

			echo ^   ^Width: %%j pixels
			echo ^   ^Height: %%k pixels
			echo ^   ^Aspect ratio: %%p
			echo ^   ^Pixel format: %%q
			if /i not "%%e"=="unknown" (
				echo ^   ^Profile: %%e@L%%r
			)
			echo ^   ^Scan type: %%x
			if /i "%debug%"=="true" (
				echo ^   ^Command:
				echo !ext_cmd_video_%%b!
			)
		)

		REM -- Subtitle stream
		if /i "%%f"=="subtitle" (
			set ext_cmd_subtitle_%%b=ffmpeg -y -i %file% -map 0:!stream_subtitle! -an -vn -c:s copy -threads 0 !flpath!%%b_!fsname!.!ext_subtitle!

			if /i "%debug%"=="true" (
				echo ^   ^Command:
				if defined stream_subtitle echo !ext_cmd_subtitle_%%b! 
			)
		)
		echo.
	) else (
		REM Reading container informations

		REM Main duration value
		set stream_duration=%%i

		REM Duration converted from seconds to minutes
		set /a stream_duration_in_minutes=stream_duration / 60

		REM Now, converting duration from seconds to hour:min
		REM Will try later to compute seconds
		set /a s_hours=stream_duration / 3600
		set /a s_mins=stream_duration_in_minutes %% 60

		REM Doing some time clean up
		if !s_ms! lss 0 set /a s_secs = s_secs - 1 & set /a s_ms = 100s_ms
		if !s_secs! lss 0 set /a s_mins = s_mins - 1 & set /a s_secs = 60s_secs
		if !s_mins! lss 0 set /a s_hours = s_hours - 1 & set /a s_mins = 60s_mins
		if !s_hours! lss 0 set /a s_hours = 24s_hours
		if 1!s_ms! lss 100 set s_ms = 0!s_ms!

		REM Now showing container information
		echo Path: !flpath!
		echo Filename: !flname!
		echo Container: %%g
		if /i "%debug%"=="true" (
			echo Duration: %%is ^| !stream_duration_in_minutes!m ^| !s_hours!h!s_mins!m
		) else (
			echo Duration: !s_hours!h!s_mins!m
		)
	)
)

:: Dumping variables (for debugging purposes)
if /i "%debug%"=="true" (
	set > %~dp0vars
)

:: Small break before starting the process
echo. & pause

:: Ok, everythings good, so starting the process
set state=Extraction start.
title !state! & echo. & echo !date! - !time! : !state!

:: Extract all tracks in same time, so it may be quite intensive for your CPU...
:: Add '/wait' before the 'start' command to work track by track.
for /l %%t in (0,1,50) do (
	set /a iteration += 1
	if defined ext_cmd_video_%%t (
		set state=Extracting ^| Track [%%t] - Video ^| !flname!...
		title Reading track [%%t] from [!flname!]...
		start /wait "!state!" !ext_cmd_video_%%t!
		echo ^  ^- Extracted track [%%t] - Video ^| !date! - !time!
	)
	if defined ext_cmd_audio_%%t (
		set state=Extracting ^| Track [%%t] - Audio ^| !flname!...
		title Reading track [%%t] from [!flname!]...
		start /wait "!state!" !ext_cmd_audio_%%t!
		echo ^  ^- Extracted track [%%t] - Audio ^| !date! - !time!
	)
	if defined ext_cmd_subtitle_%%t (
		set state=Extracting ^| Track [%%t] - Subtitle ^| !flname!...
		title Reading track [%%t] from [!flname!]...
		start /wait "!state!" !ext_cmd_subtitle_%%t!
		echo ^  ^- Extracted track [%%t] - Subtitle ^| !date! - !time!
	)
	if !iteration! EQU !tracks! exit /b 0
)

:: Process finished
set state=Extraction end.
title !state! & echo. & echo !date! - !time! : !state!
echo. & echo Press any key to exit... & pause>NUL & exit 0