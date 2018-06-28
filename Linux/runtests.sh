#!/bin/bash

target=$1 #target device (or devices)
trace=$2  #trace file to run
runs=$3   #times to run
bufferRuns=$4 #times to run before profiling
app=$5    #app to run trace on
outputFile=$6 #output file name to use (without extension)
trepnPath=$7 #Trepn directory on Android device 

#trepnPath=$trepnPath"/"$outputFile".csv"

for phone in $target
	adb -s $target shell am startservice com.quicinc.trepn/.TrepnService
done

if $# -eq 8
	for phone in $target
	adb -s $phone shell am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file -join($trepnPath ,"/saved_preferences/", $8)
	done
	Start-Sleep -s 1
fi
Write-Host "output file:"
Write-Host  $outputFile

#start with screen on - IMPORTANT


Start-Sleep -s 1 #pause

#load prefs


appetizer devices control $target shell input keyevent KEYCODE_POWER #turn off screen

Start-Sleep -s 1

for i in {1...$runs}
do
	if $i -eq $bufferRuns
	then
		for phone in $target
		adb -s $phone shell am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "trepnTemp" #start profiling
		done
		Write-Host "profile started"
	fi

	Write-Host "waking up"
	appetizer devices control $target shell input keyevent KEYCODE_WAKEUP #-turn on phone if not already on, no effect otherwise
	Start-Sleep -s .25 #pause
	appetizer devices control $target shell input keyevent 82 #-------------unlock phone if at lock screen, no effect otherwise
	Start-Sleep -s 10 #pause

	appetizer devices control $target launch_pkg $app #---------------------launch target app on target device(s)	
	
	for j in {1...3}{	
		Start-Sleep -s 5 #pause
		Write-Host "playing:"
		Write-Host $trace
		ErrorActionPreference="silentlyContinue"
		appetizer trace replay $trace $target #---------------------------------run prerecorded test
		Start-Sleep -s 5 #pause
			appetizer devices control $target shell input keyevent KEYCODE_BACK #Press back button to return to main screen
	}
	
	appetizer devices control $target shell am force-stop $app #------------halt target app so it can be re-launched
	Start-Sleep -s 5 #pause
	appetizer devices control $target shell input keyevent KEYCODE_POWER #--turn off screen to indicate end of run
	Start-Sleep -s 5 #pause
	Write-Host "run completed"
done

for phone in $target

#stop profiling
$phone shell am broadcast -a com.quicinc.trepn.stop_profiling

#convert the output to csv
$phone shell am broadcast -a com.quicinc.trepn.export_to_csv -e com.quicinc.trepn.export_db_input_file "trepnTemp.db" -e com.quicinc.trepn.export_csv_output_file $outputFile
Write-Host "Output successful"

#pull output to master machine
destPath = "/trepn"
$phone pull $trepnPath $pwd$destPath

done