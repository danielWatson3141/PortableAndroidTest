#!/bin/bash

target=$1 #target device (or devices)
trace=$2  #trace file to run
runs=$3   #times to run
bufferRuns=$4 #times to run before profiling
app=$5    #app to run trace on
outputFile=$6 #output file name to use (without extension)
trepnPath=$7 #Trepn directory on Android device 

#trepnPath=$trepnPath"/"$outputFile".csv"


./appetizer devices control $target shell "am startservice com.quicinc.trepn/.TrepnService"


if [ $# -eq 8 ]
then
	./appetizer devices control $target shell "am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file "$trepnPath/saved_preferences/""
	sleep 1
fi


#start with screen on - IMPORTANT


sleep 1 #pause

#load prefs


./appetizer devices control $target shell input keyevent KEYCODE_POWER #turn off screen

sleep 1

for ((i=1;i<=$runs;i++))
do
	if [ $i==$bufferRuns ]
	then
		for phone in $target
        do
		./appetizer devices control $target shell "am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "trepnTemp"" #start profiling
		done
		echo "profile started"
	fi

	echo "waking up"
	./appetizer devices control $target shell input keyevent KEYCODE_WAKEUP #-turn on phone if not already on, no effect otherwise
	sleep .25 #pause
	./appetizer devices control $target shell input keyevent 82 #-------------unlock phone if at lock screen, no effect otherwise
	sleep 10 #pause

	./appetizer devices control $target launch_pkg $app #---------------------launch target app on target device(s)

    sleep 10 #pause
    echo "playing:"
    echo $trace
    ErrorActionPreference="silentlyContinue"
    ./appetizer trace replay $trace $target #---------------------------------run prerecorded test
    sleep 5 #pause
	./appetizer devices control $target shell am force-stop $app #------------halt target app so it can be re-launched
	sleep 5 #pause
	./appetizer devices control $target shell input keyevent KEYCODE_POWER #--turn off screen to indicate end of run
	sleep 5 #pause
	echo "run completed"
done


#stop profiling
./appetizer devices control $target shell "am broadcast -a com.quicinc.trepn.stop_profiling"

#convert the output to csv
./appetizer devices control $target shell "am broadcast -a com.quicinc.trepn.export_to_csv -e com.quicinc.trepn.export_db_input_file "trepnTemp.db" -e com.quicinc.trepn.export_csv_output_file $outputFile"


for phone in $target
do
#pull output to master machine
mkdir trepn
destPath="/trepn"
pwd=$(pwd)
./adb -s $phone pull $trepnPath "$pwd$destPath"
done
echo "Output successful"