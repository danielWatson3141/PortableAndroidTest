$target = $args[0] #target device (or devices)
$trace = $args[1]  #trace file to run
$runs = $args[2]   #times to run
$bufferRuns = $args[3] #times to run before profiling
$app = $args[4]    #app to run trace on
$outputFile = $args[5] #output file name to use (without extension)
$trepnPath = $args[6] #Trepn directory on Android device 


#Use default path if none provided.


Write-Host "output file:"
Write-Host  $outputFile

#start Trepn Service

		starfish devices control $target shell "am startservice com.quicinc.trepn/.TrepnService"


if($args[7]) {
	#load prefs
	starfish devices control $target shell -join("am broadcast -a com.quicinc.trepn.load_preferences -e com.quicinc.trepn.load_preferences_file ",$trepnPath ,"/saved_preferences/", $prefsFile)
	Start-Sleep -s 1
 }
Start-Sleep -s 1 #pause



starfish devices control $target shell input keyevent KEYCODE_POWER #turn off screen

Start-Sleep -s 1

For ($i=0; $i -lt $runs ; $i++){
	if($i -eq $bufferRuns){
			starfish devices control $target shell "am broadcast -a com.quicinc.trepn.start_profiling -e com.quicinc.trepn.database_file "trepnTemp"" #start profiling
		Write-Host "profile started"
	}

	Write-Host "waking up"
	starfish devices control $target shell input keyevent KEYCODE_WAKEUP #-turn on phone if not already on, no effect otherwise
	Start-Sleep -s .25 #pause
	starfish devices control $target shell input keyevent 82 #-------------unlock phone if at lock screen, no effect otherwise
	Start-Sleep -s 10 #pause

	starfish devices control $target launch_pkg $app #---------------------launch target app on target device(s)
	Start-Sleep -s 10 #pause
	Write-Host "playing:"
	Write-Host $trace
	$ErrorActionPreference = "silentlyContinue"
	starfish trace replay $trace $target #---------------------------------run prerecorded test
	Start-Sleep -s 5 #pause
	starfish devices control $target shell am force-stop $app #------------halt target app so it can be re-launched
	Start-Sleep -s 5 #pause
	starfish devices control $target shell input keyevent KEYCODE_POWER #--turn off screen to indicate end of run
	Start-Sleep -s 5 #pause
	Write-Host "run completed"
}


#stop profiling
starfish devices control $target shell "am broadcast -a com.quicinc.trepn.stop_profiling"
#convert the output to csv
starfish devices control $target shell "am broadcast -a com.quicinc.trepn.export_to_csv -e com.quicinc.trepn.export_db_input_file "trepnTemp.db" -e com.quicinc.trepn.export_csv_output_file $outputFile"

Foreach ($phone in $target){
	.\adb -s $phone pull $trepnPath (-join((pwd),"/trepn"))
}
Write-Host "Output complete"
#pull output to master machine
