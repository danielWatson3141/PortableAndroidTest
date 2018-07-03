Setup

Make sure adb is working:
type "adb". It should give you a version number.
If it does not, do the following

1. Install Android SDK cli tools.

2. Ensure <sdk>/platform-tools is in your PATH.

Check the adb once again to ensure everything is working.

Install Trepn Profiler - available on Google Play Store

Configuring Trepn

Once installed, we need to configure Trepn to record what we want to measure.
Open trepn and go to settings>Data Points

Find the executable file called starfish.exe or appetizer.sh:

From shell terminal in Portable/replaykit-master/%Your OS%:

(Windows) $starfish = Resolve-Path starfish.exe -- add this to PATH

Make sure this file is executable,
(Linux) chmod 777 appetizer 
(Mac) chmod 777 appetizer
and add this to your path as well.
Basic Use:

Commands can be sent to the phone over the adb(Android Debugging Bridge).

Enable usb debugging on the Android device.

(optional, but highly recommended) In your phone's developer options, enable "Show Touches" as this will help down the road.

Plug the phone into your computer

Test the link by sending a command to the phone over the adb.

With the screen off, type:

adb shell input keyevent KEYCODE_WAKEUP

Your phone should activate.

Now find your phone's id, usually the same as the serial number.

Type:

starfish devices list

The first item on the list, "uid" is how we will identify the phone. Copy and paste this id (without the quotes) and save it to a variable

$myPhone = %uid%

Any command we can send over the adb, we can send over starfish. For example:

starfish devices control $myPhone shell input keyevent KEYCODE_WAKEUP

One thing starfish allows us to do that the adb does not is control multiple devices at once.
(This step is optional, but allows you to control multiple phones if you wish.)

We first create an array of uid's:
$myPhones = $phone1,$phone2,$phone3

Then wake them all up:
starfish devices control $myPhones shell input keyevent KEYCODE_WAKEUP

Recording touch interactions:
More detail can be found on the GitHub.

Start recording:
starfish trace record --device $myPhone mytrace.trace

type 'exit' to stop.

Check the trace (optional):
starfish trace info mytrace.trace

This gives information about the trace such as duration and number of recorded events.
If numbers seem off, something isn't working right.

We can also view and edit the trace file by decompressing it, then opening it with a text editor. Replaykit
is ok with compressed or decompressed trace files but they are compressed by default

Play back the Trace:
Starfish trace replay mytrace.trace $myPhone


I recommend using CPU Load(Normalized), GPU Load, Memory Usage, and Screen State

Screen state is to help with processing (more on that later). The others 
are relevant performance datapoints. Be sure to save your preferences by 
hitting general>Save Preferences. Remember what you name this file (or save it to a variable in your console)

Now, we need to find out where trepn has made itself at home on our Android device.
 Open your phone's file browser and locate the .../trepn directory.
 On my phone, this is /Internal storage/trepn.
 Save this path to a variable:
 $trepnPath = /Internal storage/trepn
 

Scripting Experiments


Find the package name if the app you want to test:

 adb shell pm list packages
 
 This will show you all packages installed on the device. To narrow the list, type:
 
 adb shell pm list packages %filter% 
 
 if you think you know any part of the package name.
 
 save the full package name as a variable:
 
 $myapp = "com.%me%.%myapp%"

 Record a trace for our app by launching it, starting the trace, 
 interacting a bit, then exiting the trace.
 
 
 
 Now, to collect several samples we call our magic script that ties these things together:
 
 .\runtests $myPhone traces/mytrace.trace 5 0 $myapp myProfile $trepnPath

This will launch your target app and run your trace 5 times while profiling it with Trepn.
Once it has completed its execution 5 times, it will save Trepn's output as a csv, which 
then be pulled into your working directory. Each Experiment(set of runs) generates 1 csv file
which can then be processed in Excel, R, Matlab, or your spreadsheet software of choice.

Advanced Usage

Open runtests with your preferred text editor or IDE.

We can make our experiments more complex by adding other inputs like button presses and text.

 starfish devices control $target shell input keyevent KEYCODE_ENTER #--press enter
 starfish devices control $target shell input touchscreen text $city #--type something

 More actions can be found here: https://gist.github.com/Pulimet/5013acf2cd5b28e55036c82c91bd56d8
 
 To send these events to multiple devices, just replace adb with 
 starfish devices control $target.
 
 
Designing Experiments
 To set up an experiment, first decide:

-What app shall I test?
-What series of interactions do I want to test?
-How consistent do I expect the app to be in how it responds?

Experimentation in this manner works ideally when:
-UI elements that we wish to test are stationary on the screen (i.e. not moving)
-The app is intended to give (largely) the same feedback to the same set of interactions (deterministic modulo user input)
-Timing is not of critical importance to the outcomes of interactions.

Examples of Apps that fit this set of criteria:
-Listing apps like reddit, airbnb, Netflix, Spotify, Tinder
-Web browsers
-Calculators
-Puzzle Games such as Sudoku
-Clock apps

Examples of Apps that do not work ideally:
-Anything involving Maps like Google maps or Uber (as maps is somewhat non-deterministic as scroll speed is partly dependent on CPU constraints)
-Any games involving motion or timing (flappybird, pong, etc.)
-Any apps that update content continuously (such as Facebook, Instagram, Youtube) as consecutive sessions will not show the same content.

I do not mean to suggest we cannot use the tool to perform tests on these apps,
but our sample variance is likely to be much higher and possibly more sensitive to small variations
in experimental technique. Draw conclusions with caution when testing such apps.

Once you've chosen an app to profile, decide what interactions to test. Consider:
-Does this set of interactions sufficiently resemble a typical use case?
-Should this set of interactions consistently give us the same response?

Example:

Open propertyExp.ps1. In this file, we've scripted an experiment to test a very simple listview
demonstration app, like the one found here:
https://www.raywenderlich.com/178012/react-native-tutorial-building-android-apps-javascript
Our script clears the text box, types in the name of a city (from a list of 3), presses enter, then scrolls the list up and down for a little while,
before hitting the back button and returning to the main screen.

Suggestions:

As mentioned previously, certain games make good candidates for testing.

Web browsers make excellent candidates for this tool, as for most websites, 
the user sees the same content when they navigate to them. One could, for example, design
an experiment to test the efficiency or quickness of web browsers by tapping the url bar,
typing out a website, and pressing enter.
