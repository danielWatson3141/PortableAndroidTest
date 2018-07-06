# Android Test Center Setup and Usage

1. Open a terminal in this directory.

    shift + right click-> open Powershell Window here 
2. Make sure adb is working:

    type `./adb`. It should give you usage information.
3. Enable developer options on the Android device.

   Settings->About device
   tap build number seven times.
4. Enable the following developer options. 

    They appear in the developer options menu in this order:
  
    * Stay Awake

    * USB debugging

    * USB configuration: MTP 

        (Usually you can select from a list of options. Select MTP (Media transfer Protocol))

    * Show Touches
5. Disable immediate screen lock.
    * If you have your security settings set to lock the phone immediately on screen shutdown, this must be set to a delay of 1 minute or more.

    * This setting is found in Settings->Lock Screen and security->Secure Lock Settings, although this may differ by manufacturer.
6. Install Trepn Profiler 
    * Available on Google Play Store, also installable from the apk in PortableAndroidTest/
7. Configure Trepn

    Once installed, we need to configure Trepn to record what we want to measure.
    1. Open trepn.
    2. Open advanced mode by hitting the beaker at the top corner and go to settings>Data Points(tab).
        I recommend using:
        * CPU Load(Normalized) - Percent of CPU utilization with respect to maximum theorhetical capacity. This accounts for things like temperature and low battery conditions.
        * GPU Load - Percent of GPU capacity utilized.
        * Memory Usage - Total memory occupied in Kb
        * Battery power - Rate of battery consumption in mW
        * Screen State - Screen on or off, boolean value.
        Screen state is to help with processing. The others are relevant performance datapoints.
    3. Be sure to save your preferences by hitting general>Save Preferences. Remember what you name this file (or save it to a variable in your console)

Now, we need to find out where trepn has made itself at home on our Android device.
 Open your phone's file browser (you may need to download and install one like "file manager") and locate the .../trepn directory.
 On my phone, this is /Internal storage/trepn.
 Save this path to a variable in your terminal:
 `$trepnPath = "/Internal storage/trepn"`

## Sending Commands to the phone

Plug the phone into your computer. A popup should come up asking you if you want to enable MTP, press yes and, if available, check the box that says "always allow from this computer".

Commands can now be sent to the phone over the adb(Android Debugging Bridge).

### Test the link by sending a command to the phone over the adb.

With the screen off, type:

`./adb shell input keyevent KEYCODE_WAKEUP`

Your phone should activate.

### Now find your phone's id, usually the same as the serial number.

Type:

`./starfish devices list`

The first item on the list, "uid" is how we will identify the phone. Copy and paste this id (with the quotes).

### Save it to a variable

`$myPhone = "abc123"`

Any command we can send over the adb, we can send over starfish using the phone's uid. For example:

`./starfish devices control $myPhone shell input keyevent KEYCODE_WAKEUP`

## Recording touch interactions:

Replaykit can be used to record a series of touchscreen inputs and save them to file to be played back later. More details can be found on the Replaykit Github (link)

### Start recording:
`./starfish trace record --device $myPhone mytrace.trace`

type 'exit' to stop.

### Check the trace (optional):
`./starfish trace info mytrace.trace`

This gives information about the trace such as duration and number of recorded events.
If numbers there are all zero, something isn't working right.

### Viewing trace files
We can also view and edit the trace file by decompressing(right click -> extract archive...) it, then opening it with a text editor. Replaykit
is ok with compressed or decompressed trace files but they are compressed by default

We can then open the trace file and view its contents. Each row represents a brief instant of a touch on the screen. Each line gives a timestamp, coordinates, and a pressure reading. These values can all be edited manually or programatically to generate or modify trace files. 

### Play back the Trace:
`./starfish trace replay mytrace.trace $myPhone`

## Scripting Experiments

### Find the package name of the app you want to test

 `./adb shell pm list packages`

 This will show you all packages installed on the device. To narrow the list, apply a filter.For example, if I want to test an app called Glympse, I type:

`./adb shell pm list packages glympse`

And I get back:

`package:com.glympse.android.glympse`

save the full package name as a variable:
`$myapp = "com.glympse.android.glympse"`

### Record a trace for our app
1. launch it
2. start the trace
3. interact a bit. Touch the screen, drag it, pinch it.
4. exit the trace.

Now, to collect several samples we call our script that ties these things together:




### Launch the script
 `./runtests $myPhone mytrace.trace 3 0 $myapp myProfile $trepnPath`

 This script has 7 arguments and an optional 8th. They are:

1. target phone uid
2. trace to run
3. times to run experiment
4. times to run experiment before triggering trepn (more on this later)
5. app to test
6. name of output file
7. path to trepn directory on device.
8. (optional) name of .pref file to use without path (if you want to use an alternate pref file to the one currently active)

This will launch your target app and run your trace 3 times while profiling it with Trepn.
Once it has completed its execution 5 times, it will save Trepn's output as a csv, which 
then be pulled into your working directory. Each Experiment(set of runs) generates 1 csv file
which can then be processed in Excel, R, Matlab, or your spreadsheet software of choice.

## Advanced Usage

Open runtests.ps1 with your preferred text editor or IDE.

We can make our experiments more complex by adding other inputs like button presses and text.

 `./starfish devices control $target shell input keyevent KEYCODE_ENTER #--press enter`
 `./starfish devices control $target shell input touchscreen text $city #--type something`

 A complete reference of adb actions can be found here: https://gist.github.com/Pulimet/5013acf2cd5b28e55036c82c91bd56d8
To send these events to multiple devices, just replace adb with./starfish devices control $target.
 

### Designing Experiments
 To set up an experiment, first decide:

* What app shall I test?
* What series of interactions do I want to test?
* How consistent do I expect the app to be in how it responds?

#### Experimentation in this manner works ideally when:

* UI elements that we wish to test are stationary on the screen (i.e. not moving)
* The app is intended to give (largely) the same feedback to the same set of interactions (deterministic modulo user input)
* Timing is not of critical importance to the outcomes of interactions.

#### Examples of Apps that fit this set of criteria:

* Listing apps like reddit, airbnb, Netflix, Spotify, Tinder
* Web browsers
* Calculators
* Puzzle Games such as Sudoku
* Clock apps

#### Examples of Apps that do not work ideally:

* Anything involving Maps like Google maps or Uber (as maps is somewhat non-deterministic as scroll speed is partly dependent on CPU constraints)
* Any games involving motion or timing (flappybird, pong, etc.)
* Any apps that update content continuously (such as Facebook, Instagram, Youtube) as consecutive sessions will not show the same content.

I do not mean to suggest we cannot use the tool to perform tests on these apps,
but our sample variance is likely to be much higher and possibly more sensitive to small variations
in experimental technique. Draw conclusions with caution when testing such apps.

Once you've chosen an app to profile, decide what interactions to test. It is best to design a test that is both representative of actual use conditions, and repeatable. That is, the same response by the app can be expected each time from the given input. 


#### Before designing your experiment, answer the following:

* Does this set of interactions sufficiently resemble an interesting use case?
* Should this set of interactions consistently give us the same response?
* How will activities such as caching affect the measurements I'm taking? Will this effect obscure my results?
* How big of an observer effect might Trepn be having on my phone and is it large enough to prevent me observing what I want? This depends on the hardware, as older or more sluggish phones may be more affected by Trepn's activities.

Once you have decided on an experiment:

1. Boot the app
2. Record your interactions
3. call runtests.ps1 again with your chosen app and trace file to see how it goes.

#### Add other events or traces

In the script, you should only edit the code between when the app is launched and when the app is closed.
Some examples of things you can script without too much code:

-record multiple traces for different purposes (or for some kind of randomized trial). Just treat the $trace parameter as an array and pass it an array of trace files when you run it.

-Call monkey for random screen events. This can help look for bugs or performance bottlenecks.


### Example

Open Windows/propertyExp.ps1. In this file, we've scripted an experiment to test a very simple listview
demonstration app, like the one found here:
https://www.raywenderlich.com/178012/react-native-tutorial-building-android-apps-javascript
Our script clears the text box, types in the name of a city (from a list of 3), presses enter, then scrolls the list up and down for a little while,
before hitting the back button and returning to the main screen to repeat the process for the three cities

This allows us to profile the scrolling behavriour, but also how the app behaves while making http requests.

### Resetting the phone

To undo the settings we enabled for this demo, open Settings->Developer Options and there is an option to disable them all at the top. Remember to return your security settings to their previous state as well.

### Bonus
One thing starfish allows us to do that the adb alone does not is control multiple devices at once.
(This step is optional, but allows you to control multiple phones if you wish.)

We first create an array of uid's:
$myPhones = $phone1,$phone2,$phone3

Then wake them all up:
./starfish devices control $myPhones shell input keyevent KEYCODE_WAKEUP

We can use the array of phone id's to carry out experiments using the script in the same way as before, no additional cost.