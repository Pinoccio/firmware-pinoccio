#2014111401

⚠ **Arduino 1.5.8 or above is now _required_ when compiling custom sketches.** ⚠

- ##### Initial support for Over-The-Air (OTA) updating ([library-pinoccio, #203](https://github.com/Pinoccio/library-pinoccio/pull/203))
  This module allows over-the-air updating of other scouts. To use it, run `scout.otaboot` on the target scout to reboot it in OTA mode (it will stay in OTA mode for 10 seconds, or indefinitely if it receives any valid packet).

  Then, on another scout with this commit, enable the `ota` module and run the ota commands:

  ```
  > module.enable("ota")
  > ota.ping(0xffff)
  >
  PONG {'short_addr':0x0005, 'status':0x00, 'errno':0x0000,'appname': 'wibo', 'boardname':'pinoccio', 'version':0x05, 'crc':0x0000}

  > ota.ping(5)
  > No ping reply

  > ota.ping(5)
  >
  PONG {'short_addr':0x0005, 'status':0x00, 'errno':0x0000,'appname': 'wibo', 'boardname':'pinoccio', 'version':0x05, 'crc':0x0000}
  ```

  `ota.ping` just tries a single pin, without retries, all other command retry a few times. Ping either accepts a target address, or `0xffff` to do a broadcast.

  To actually flash something, use a sequence of `ota.start` to select the target, any number of `ota.block` to send data and `ota.end` to reboot the target again.

  ```
  > ota.start(5, 1)
  >
  OK

  > ota.block(0, "DEADBEEF")
  >
  OK

  > ota.end
  >
  OK
  ```

  `ota.start` takes the address of a target and `0` for normal flashing and `1` for a dry run (everything is sent over, but the target doesn't do the actual flashing).

  `ota.block` preferably needs data in multiples of the flash page size (256 bytes). If shorter blocks are passed, they are padded with 0xff bytes (so the padding actually overwrites data!). Normally, this padding should only be needed for the final block. Due to limitations in bitlash, 512 byte is too much, so you should use blocks of 256.

  Alternatively, you can use the `ota.clone` to send over the scout's own flash contents to the target instead of sending the data. An `ota.clone` command replaces a series of `ota.block` commands by sending the flash contents of the scout running it (excluding bootloader) to the target. To use it, use `ota.start`, `ota.clone` and `ota.end`.

  Cloning also sends over all trailing `0xff` bytes in the flash, since the code does not know where the sketch code ends. Skipping all trailling 0xff bytes is also not possible, since the sketch might actually contain some trailing 0xff bytes (e.g. some data). For this reason, we just always send over _all_ flash contents.

  All `ota` commands are coded so they eventually always print either "OK" or "FAIL" (on a line by itself), allowing a script to easily parse the result (since the bitlash command returns before the operation is completed).

  To make using these commands easier, you can use the [commandline interface from the `pinoccio` nodejs module][npm.pinoccio], or upload directly from the Arduino IDE.

  [npm.pinoccio]: https://www.npmjs.org/package/pinoccio

  ###### OTA programming from the Arduino IDE

  To do OTA updates from the IDE, connect another scout (in the same troop as the target) to your computer through USB and select it's port in the Port menu.

  In the programmers menu, there are two options:

    1. _Over-the-Air programming for Pinoccio (first target already in OTA mode)_ requires putting the target pinoccio into OTA mode manually beforehand, using the scout.otaboot command. Then the OTA update will use a broadcast ping to find it. If multiple scouts are in OTA mode, the first one to respond to the ping will be used.

    2. _Over-the-Air programming for Pinoccio (selected target, switch to OTA mode)_ uses a specific target scout, which is also rebooted into OTA mode if needed. The target id needs to be configured beforehand using the pinoccio cli.Run e.g. `pinoccio config ota.default-target 123` to configure the target id.

  This requires that the ["pinoccio" program][npm.pinoccio] is in the search PATH.

  If you have it installed somewhere else, you can make a platform.local.txt file containing:
  
  ```
  tools.pinoccio_ota.cmd.path=/path/to/pinoccio
  ```

- ##### Add SD example ([library-pinoccio, #210](https://github.com/Pinoccio/library-pinoccio/pull/210))
  This example sketch initializes the SD library and adds a few bitlash commands to interact with it.

- ##### WiFi: use SPI transactions ([library-pinoccio, #209](https://github.com/Pinoccio/library-pinoccio/pull/209))
  The Gainspan module now takes care of initializing SPI and uses the transaction API to set the speed. We just use its defaults, so no need
  to pass any extra settings either.

  This new API makes sure that we always use our own SPI settings for every transaction, even when other libraries also use the SPI bus with
  different settings.

  ⚠ **Since we always use the transaction API, this means Arduino 1.5.8 or above is now required.**

- ##### Power state is always "current" ([library-pinoccio, #213](https://github.com/Pinoccio/library-pinoccio/pull/213))
  When using sleep extensively, the power report/commands could be returning old/cached information but will now always be current.

- ##### Use torch LED to indicate boot and network status ([library-pinoccio, #207](https://github.com/Pinoccio/library-pinoccio/pull/207))
  ###### The first pass at this is boot status indicators of:

  1. The bootstrap blinks `torch` once
  2. There is no LED during firmware boot
  3. Successful firmware init turns on `torch` then runs custom startup scripts
  4. Successful custom-startup completion turns off `torch`
  5. If battery alarm is on (<20%) and it is not charging, it then blinks `red` three times quickly
  6. If custom startup changes the LED, no post-boot indicators are done

  So:

  * two torch blinks - full boot + power
  * two torch blinks then three red blinks - full boot but low power
  * one torch blink then off - bad firmware
  * one torch blink then steady torch - good firmware but bad startup scripts

  ###### The second pass is the mesh network status blink:

  This is only enabled after `scout.indicate` is run (optional arg of number of seconds, 5 is default, 0 to disable).

  * network status is indicated once every `indicate` seconds
  * it blinks the `torch` color
  * if any other scouts are detected the blink is very small (short)
  * if no mesh/scouts are detected the blink is a continuous second (long)
  * should restore any other LED settings after

  ###### The third pass is the wifi status:

  This is only enabled after `wifi.indicate` is run.

  * when associating, it will blink green very fast
  * after it associated and while it's trying to connect to hq it will be solid green
  * once connected to hq it turns back off
  * if it disconnects it starts over associating again

#2014110701

Fixes some issues with compiling in Arudino IDE 1.5.8.

#2014110301

**Note:** This is primarily a bug fix release, hot on the heels of the last, more-substantial update. Make sure you check out the last release for all the other new newness.

- #####Add `serial.mute` (library-pinoccio, #200)
  This adds a new command to enable silent running mode, ensuring nothing is printed to Serial when any background commands are run.

  Use just `serial.mute` or `serial.mute(1)` to put it in silent mode (it still prints to Serial when it receives commands from serial), and `serial.mute(0)` to disable.

  This is *highly recommended* to be put in startup functions when using scouts that aren't attached to USB and may be running commands that print to Serial, and it may even become the default soon if there're no issues found with it.

#2014102801

This release includes a number of bug fixes and stability improvements, along with the following feature additions and enhancements:

- #####Add connection events (library-pinoccio, #169)
  These can trigger troop-wide data reporting as soon as hq is online (or wifi is available).  They add two events:

  * When the wifi backpack successfully associates to a network, it will call the script event named `on.wifi.associate`.
  * As soon as any hq connection is established (including to a standalone pinoccio-server) via wifi or bridging (or other future connectivity) the script event `on.hq.online` is called.

- #####Add more modules (library-pinoccio, #171)
  Old modules have been moved into the new pattern. Use `module.status` to see what's building and what's not. Current module list...
  * wifi
  * env
  * flash
  * hello
  * motion
  * pixels
  * servo

- #####Add `mesh.fieldtest` (library-pinoccio, #175)
  In the quest to make a simple mesh calibration utility, multiple new facilities were required and some odds and ends were fixed.

  This adds the commands:

  * `mesh.fieldtest(seconds)` - turns on a fieldtest mode that runs a constant mesh ping for this many seconds, the scout running the fieldtest will turn red for no mesh, yellow for weak mesh, and blink green for good mesh, and every other scout it is meshed with will blink blue
  * `mesh.from` - returns the scout id that last commanded this scout (useful to auto-generate replies)
  * `mesh.each("command")` - will run `command(id,lqi,via)` for every other scout currently visible on the mesh (as seen with `mesh.routing`)

  It also enables multiple commands to be sent simultaneously.

- #####Add mesh-wide `online` awareness (library-pinoccio, #176)
  In an effort to improve the reliability of `hq.report` there were some side-effects:

  * whenever a lead scout comes online, `on.hq.online` is triggered across the whole mesh
  * the command `hq.online` will return 1/0 on any scout if hq has been seen recently on the mesh
  * the last `hq.report` will be persisted and resent until a lead scout acks it (good for triggers to make sure they're sync'd)

- #####Add a "sniffer" module (library-pinoccio, #184)
  This module allows capturing packets from the mesh. To use it, enable the
  module and call sniffer.start:

      > module.enable("sniffer")
      > sniffer.start

  This dumps raw packets to the Serial port (but completely stops all
  other processing on the Scout!).

  By running `sniffer.start(1)`, a binary output mode is selected which
  works in concert with a small script:

  https://github.com/Pinoccio/tool-serial-pcap

- #####Add `mesh.setchannel` (library-pinoccio, #187)
  This adds a function, `mesh.setchannel` for setting the mesh channel without having to also pass a `pan id` and `address`, as are required with `mesh.config`.

  Usage: `mesh.setchannel(26)` will set the mesh channel to 26.

  **Important:** You'll want all the Scouts in your Troop to change to this new channel as well, so the practical usage should be `command.all("mesh.setchannel",26)`.

- #####Add `command.group` (library-pinoccio, #189)
  This adds a `command.group` function to ScoutScript. Use it to command a group of Scouts, for example: `command.group(42,"led.red")` will make all of the Scouts in `group 42` run `led.red`.

- #####Implement `wifi.setverbose` (library-pinoccio, #197)
  By default, only errors are logged. By running `wifi.verbose(1)`, all
  data sent to and received from the wifi module is logged.

  Logging only happens to Serial, since it is a bad idea to log data to HQ
  (which goes through wifi, causing more log output, causing more traffic,
  etc.).

#2014082001

- #####Add module support (library-pinoccio, #151)
  A Module is a class the defines a bunch of functionality that can be
  dynamically enabled at runtime. The code is already present in Flash,
  but the relevant setup steps (in particular, big memory allocations
  and registering ScoutScript commands) have not been performed and the
  associated bitlash function are not registered yet until the module is
  enabled.

  For now, there is just a single "wifi" module, which is automatically
  loaded when a wifi backpack is detected, so there is not really
  anything to do with modules yet. Later, extra features will end up in
  modules, though.

- #####Shell.eval() support (library-pinoccio, #163)
  `Shell.eval()` is a C++ method that makes it easier to evaluate
  ScoutScript commands from within the C/C++ codebase.

  The most basic version just accepts a single String (or through
  implicit conversion, const char*) containing a full command to
  run:

       Shell.eval("print 1");
       Shell.eval("function foo { print \"bar\"; }");

  Alternatively, you can pass a function name and arguments:

       Shell.eval("wifi.config", "foo", "bar");
       Shell.eval("hq.verbose", 1);

  This constructs and evalutes wifi.config("foo", "bar") and
  hq.verbose(1) respectively.

  String arguments are automatically quoted and passed to bitlash
  as strings, integers are used as-is. To pass an integer as a
  string argument, convert it to String explicitely:

       Shell.eval("hq.report", "test", String(2));

  Shell.eval always returns the (numeric) result of the command.
  The output is printed to the default location (usually Serial).
  To redirect the output, pass a Print reference or pointer as the
  first argument:

       Shell.eval(Serial1, "uptime.status");

  To capture the output in a string, use the PrintToString class:

       String output;
       Shell.eval(PrintToString(output), "pin.status");

- #####Run commands on other scouts (library-pinoccio, #166)
  This makes it easier to run commands on other scouts, without having
  to resort to (quite confusing) custom messages combined with string
  key handling.

  Instead of having to encode strings as keys,
  you now only need to send what ScoutScript command you want to execute
  on the other Scout or Scouts.

  ``command.scout(<scoutId>, "command", 32, "hi", "`led.gethex`");``
   This builds the command string: `command(32, "hi", "FF00FF")`, and sends
   that command to be evaluated on the Scout with `<scoutId>`. Any argument
   enclosed in backticks will be evaluated, and the return value will be
   included as the value of the argument.

  ``command.scout.ack("called",1,"led.sethex","`led.gethex`");``
   This command is the same as `command.scout`, except that `called(err, rssi)`
   is evaluated locally after the remote command is run.

  `command.all("led.setrgb", random(255), random(255), random(255))`
   This will run the command `led.setrgb(<random>, <random>, <random>)` on
   every scout in the troop--where `<random>` is some value between 0 and 255.

  `command.others("led.red")`
   This will run the command `led.red` on every scout in the troop other than
   the current Scout.

- #####Fix SPI flash on the wifi backpack (library-pinoccio, #161)
  When the Serial Flash module was accessed (using Flash.cpp in a custom
  sketch), SPI would completely stop.  This is now fixed, and you can
  write to and read from the on-board 2MB flash storage without losing
  your WiFi connection. An ScoutScript API for this still needs to be
  added.

- #####Allow changing the HQ address and port using hq.setaddress
  Changing the hq address through scoutscript always disables TLS (can
  only be re-enabled through a reboot). The port defaults to 22756 when
  left out.
  `hq.setaddress("pool.base.pinocc.io")`
  `hq.setaddress("192.168.1.123", 456)`

  This only takes effect until the next reboot, so put it in your
  `startup` function to make it permanent.

  Combined with the
  [pinoccio-server](https://www.npmjs.org/package/pinoccio-server)
  nodejs package, this makes it possible to run a custom HQ server
  without needing a custom firmware.

- #####Better WiFi recovery upon disconnect
  When a lead scout doesn't see any activity from HQ it tries to re-associate WiFi,
  and if that fails it completely restarts to cleanly reset the WiFi backpack. This
  replaces the earlier Network Connection Manager (NCM) support built into the
  Gainspan module, as it wasn't stable and would not hold connections.
  NCM is still used for associating to the wifi, just not for setting up
  HQ connections.

- #####Cleanup of event halting, to truly suppress events from emitting (library-pinoccio, #167)
  In some instances, when `events.stop` was ran, some events would still
  emit, specifically the LED change events.  This now ensures that all
  events are truly disabled, lowering the chatter and traffic on the
  mesh.

- #####Add `uptime` ScoutScript command as a alias of `uptime.status` (library-pinoccio)

- #####Support history editing in the serial console (library-pinoccio)
  In a regular serial console, pressing the up arrow now recalls the
  previously ran command. Note that the Serial monitor in the Arduino
  IDE uses line-based editing (as opposed to sending keypresses to the
  board directly), so this does not work there.

- #####Various serial console fixes (library-pinoccio, #159)
  Recently, the serial handling was moved out of the bitlash library and
  re-implemented in library-pinoccio. Not everything worked correctly
  yet, in particular backspace was not handled and not all types of
  newlines were handled correctly.

#2014080101

- #####Fix problem with newlines from reports (library-pinoccio, #159)
  Reports were sometimes outputting newline characters but not carraige
  return characters. To maintain backwards compatibility, a fix was added
  to include both characters in report output.

#2014073101

- #####Use the symbol counter for sleep timing (library-pinoccio, #149)
  Internally, the sleep timing is now calculated using the symbol
  counter, which is a 32-bit counter counting in 16μs increments.

  This (internally) increases sleep precision, but also limits the
  maximum sleep time to just over 19 hours (2³² * 16 μs). Because the
  symbol counter keeps on running at the same frequency while awake and
  while sleeping, the sleep timing should be more accurate than before.

  The `power.sleep` function still accepts a sleep interval in
  milliseconds as before.

- ##### Allow waking up from sleep on pin changes (library-pinoccio, #149)
  A number of pins on the Scout have support for triggering an interrupt
  that can wake up the Scout from sleep.

  To use this feature, first configure the pin as an input as normal.
  Then run e.g. `power.wakeup.pin("d2")` to enable wakeups for that pin.

  Not all pins are available, only the pins that have external interrupt or pin
  change interrupts. Supported pins are: D2, D4, D5, D7, BATT_ALERT, SS, MOSI,
  MISO, SCK, TX1, RX1, SDA, SCL.

  Of these, pins D4, D5, D7 and BATT_ALERT only support waking up on a low
  level, not on a change. This means that wakeup is enabled for one of these
  pins and it is low when starting the sleep, the scout will immediately wake
  up again, effectively preventing it from sleeping.

  Furthermore, [due to a bug][Arduino510] in the Arduino core, for the SCL,
  SDA, RX1 and TX1 pins when a pin change happens while not sleeping, the next
  sleep will be immediately interrupted because the interrupt flag remains set
  and immediately triggers the interrupt.

  [Arduino510]: https://github.com/arduino/Arduino/issues/510

  Note that even though the wakeups involve interrupts, these interrupts
  do not actually handle the new pin value, they just cause the Scout to
  wake up. The handling of the pin change is handled by the normal
  polling and `on.d[2-8]` event callbacks as normal, but only if the pin
  keeps its new value long enough for the polling to notice it after
  waking up.

  Also note that not a lot of effort is done to prevent race conditions:
  For example, if the pin change occurs just before sleeping, then the
  corresponding pin change handler might not be run, or only after
  sleeping. If these race conditions are problematic, short response
  times are needed or the pulses are very short, a custom sketch might
  still be needed.

- ##### Improve `power.sleep` callbacks (library-pinoccio, #149)
  `power.sleep` now accepts only a callback function name (not a full
  ScoutScript command). This function gets passed two arguments: the
  total sleep duration (e.g. the first argument to `power.sleep` as-is)
  as well as the number of milliseconds left to sleep.

  Normally, the second argument will be 0. However, when the sleep was
  interrupted, it can be non-zero.

  When sleep is interrupted, the callback function can return a non-zero
  value to continue sleeping until the full sleep duration has passed.
  When the callback returns 0, no further sleeping happens (though the
  callback can of course call `power.sleep` again to schedule another
  sleep interval).

  It is advisable to always let the `power.sleep` callback function
  return a value. If no value is explicitely returned, the return value
  of the last statement in the callback function is used, which might
  not be what you want.

- ##### Restructure ScoutScript uptime API (library-pinoccio, #149)

  There are now three uptime counters: uptime.awake, uptime.sleep
  and uptime (total uptime). Each of them has two subcounters: .seconds
  that returns the number of seconds and .micros that returns the time
  _within_ the current second in microseconds (so this rolls over at
  1,000,000 microseconds).

  All counters now have a precision of 16us. The seconds counter is
  32-bits wide, so it will only overflow after 136 years - as good as
  never.

  This removes the uptime.minutes, uptime.hours, uptime.days and
  uptime.millis scoutscript functions. The uptime.micros function is
  changed - before it returned the total number of microseconds since
  startup, overflowing only after 2^32 us (over an hour). Now, it rolls
  over every second and should be used in conjunction with the seconds
  counter to get the full value.

  Additionally, the uptime report now contains the total uptime and sleep
  time, in seconds instead of milliseconds.

- ##### Rename `pin.list` to `pin.status` and extend it (library-pinoccio, #149)
  It now also shows PWM and wakeup support for each pin.

- ##### Make the "password" argument to `wifi.config` optional (library-pinoccio)
  This allows using open wifi networks.

- #####Add ScoutScript function name caching (library-pinoccio, #157)
  This removes the need to look into the (slow) EEPROM to determine if a
  function is defined. In particular, this improves the startup time,
  since there a lot of `startup.something` function are ran (and before,
  for each of these functions that did not exist, the entire EEPROM
  contents was scanned).

- #####Enable usage of the "data ready" pin on WiFi backpack hardware version v1.1 (library-pinoccio)
  This pin was not connected on the v1.0 backpack, so the Scout had to
  resort to polling the SPI bus. With this pin added and support
  enabled, the CPU overhead on a lead scout should be significantly
  reduced.

- #####Improve bridge mode support and ScoutScript prompt (library-pinoccio, #156)
  This restructures the handling of the ScoutScript prompt, which
  makes the bridge mode support a lot more stable. It should now be
  usable, using the pinoccio node module running on the PC.

- #####Support calibrating the temperature sensor (library-pinoccio)
  This stores a simple offset value (in degrees Celcius) for the
  internal temperature sensor. The offset can be set explicitely using
  `temperature.setoffset` or can be calculated automatically by passing
  the real current temperature (in degrees Celcius) to
  `temperature.calibrate`

#2014072201

- #####Updated Lightweight Mesh library to v1.2.1 (Pinoccio/library-atmel-lwm)
  This contains no changes that affect Pinoccio, but it does clarify the
  library licensing a bit.

- #####Add support for "disconnected" pinmode, to reduce power draw (library-pinoccio, #130)
  Pins that are unused and do not have anything connected to them, draw
  more power than needed. To prevent wasting this power, these pins
  should be set to the "disconnected" pin mode. This can either be done
  one-by-one using `pin.makedisconnected` or it can be done at once for
  all pins that have not been assigned any other pin mode yet, using the
  `pin.othersdisconnected` function.

  Note that setting the "disconnected" pin mode enables the internal
  pullup resistor and should only be used for pins that are not actually
  connected to anything (see below). If a pin is connected to something
  but not used right now, you should set its pinmode to "disabled"
  instead.

  This extra power usage comes from the pin input logic. In the default
  pin mode (which is changed from "disabled" to "unset"), the hardware
  input logic is active. When a pin is unused (e.g.  not connected to
  anything / floating), its voltage can fluctuate under the influence of
  static charges. If the voltage fluctuates around the high/low
  boundary, this can cause the pin input logic to switch between high
  and low a lot. Each of these switches consumes a bit of power.

  The easiest way to prevent this switches is to enable the internal
  pullup which will keep the pin value high. However, when something is
  connected to the pin, enabling the pullup could cause problems (like
  accidentally enabling a connected relay). Therefore, this pullup is
  only enabled on pins that are explicitely marked as "disconnected".

- #####Add `pin.list` function (library-pinoccio, #130)
  This allows listing all available pins with their names, modes and
  current value. Due to technical limitation, this function only works
  through the serial console right now.

  Note that this function was later renamed to `pin.status`.

- #####Allow using all pins, not just Dx and Ax (library-pinoccio)
  The pin handling functions `pin.setmode`, `pin.read`, `pin.write`,
  etc. now support all I/O pins on the Scout instead of just the regular
  digital and analog pins. All special pins can be used as a digital
  I/O pin as well. For example:

      > pin.makeinput("tx1")
      > print(pin.read("tx1"))
      1

  Of course, pins that are reserved / used by a backpack (like the I²C
  pins) can still not be used.

  Note that pin reports to HQ still only include the Dx and Ax pins.

- #####Add millis to all reports (library-pinoccio, #153)
  This simply adds the value of the Arduino `millis()` counter to all
  reports to help with synchronization and deduplication at HQ.

- #####Allow multiple arguments to `hq.report` (library-pinoccio, #141)

- #####Preliminary support for bridge mode (library-pinoccio, #147)
  This prepares for letting the scout connect to HQ through the serial
  port, using the pinoccio node commandline tool, but this is far from
  complete yet.

- #####Add support for hardware PWM for digital pins 2, 3, 4, and 5 (library-pinoccio, #114)
  This allows outputting a PWM signal on pins that support it (like the
  `analogWrite` Arduino function).

  The frequency of the PWM signal is fixed at 976Hz (period is 1024μs)
  and the duty cycle can be configured using `pin.write`.

  To use this, first set the pinmode to PWM using e.g. `pin.makepwm(2)`.
  Then, write a duty cycle using e.g. `pin.write(2, 128)`.

  The duty cycle ranges from 0 (always low) to 255 (always high).

- #####Add beccapurple as a supported RGB LED color (library-pinoccio, #138)

- #####Add `uptime.micros` ScoutScript function (library-pinoccio)

- #####Allow creating temporary string keys using `key` (library-pinoccio, #140)
  By passing a non-zero value as the second argument of `key`, the key
  created is automatically cleaned up after the current ScoutScript
  command is completed.

- #####Fix pin.save (library-pinoccio)
  At some point, pin.save stopped actually saving the pin modes for
  after reboot (it did apply them, though). It now works as expected
  again.


#2014060501

- #####Add Serial Flash example for how to use the storage chip on the lead scout

- #####Add ClearScoutScript example sketch to reset functions defined in EEPROM
  This is a custom sketch that can be uploaded using the Arduino IDE,
  which clears the EEPROM from any user-defined scoutscript functions.
  This can be handy in case you added a startup function that prevents
  the ScoutScript prompt from working as expected.

- #####Include simple Bluetooth example sketch
  This is an example using the Adafruit Bluetooth breakout board.

- #####Slightly modify ScoutScript banner for easier reading
  This reorders things a bit and removes the build number (which can be
  found inside the revisions as well).

- #####Solve issue with mesh security key, when given less than 16 bytes
  Before, when a shorter key was used, the extra bytes were filled with
  random memory contents. Now, they are filled with 0xff.

- #####Do not do NTP when SSL/TLS is disabled for the HQ connection
  NTP timesync is needed to verify the certificate validity, but can be
  skipped otherwise.

- #####Allow calling `pin.save` with 3 arguments and `hq.report` with 2.
  This was already documented, but too strict argument checking
  prevented these calls from working.

- #####Minor `power.sleep` improvements
  Some restructuring and small bugfixes should slightly improve the
  sleep feature.

- #####Swap scout.delay arguments, to match power.sleep
  Now the delay is given as the first argument, unlike before.

#2014051403

- ###Introduce the `power.sleep` command
  This lets you put your Scout to sleep from around 100ms between wake-ups, up to around 50 days between wake-ups!  Using a [µCurrent](http://www.eevblog.com/projects/ucurrent/), we measured an average of 12.5µA of current draw while sleeping.

 Here's an example on how you use it:

  ```c
function foo {led.on; power.sleep(4000, "bar"); };
function bar {led.off; power.sleep(4000, "foo"); };
```

  Then just call `foo` and your Scout will switch the LED torch on or off, then go into sleep mode for four seconds.

  It might take a few ms before the sleep to actually kick in, while the scout finishes up unfinished business (e.g. mesh transmissions). While sleeping, the Scout is completely non-responsive, it will not respond on the serial port, mesh network or through wifi. Any (pin change) event handlers or scheduled delays will not run. Any PWM outputs will freeze to eigher high or low output.

  Note that this function is stil a work in progress, so feedback is welcome! Things to keep into account:
   - Backpacks are not disabled yet during sleep (so using sleep on a lead scout is probably going to break things).
   - The actual sleep time might be shorter if an interrupt happens halfway. Only a few interrupt types can actually wake up from sleep, but in rare circumstances other interrupts can also cause the sleep cycle to be broken.
   - Serial transmissions might be cut short in the middle of a byte.

- ### Increase WiFi connection stability

  The TLS connection from a Lead Scout to the API server has been changed over to a non-TLS socket.  The TLS socket is believed to be causing most of the TLS disconnect/reconnect issues, as well as some of the hung Lead Scouts. If you've ever seen things like `Response timeout. SSL negotiation to HQ failed, reassociating to retry`, or `Response timeout SPI 0xff?`, then this should put you in better order.

  What about security though?  Well, a couple of things.  If you'd like to turn it back on, just uncomment the `#define USE_TLS` line at the top of src/hq/HqInfo.cpp and reflash, and you should be good to go.

  Soon Telehash will handle all encrypted payloads regardless of networking stack, at which point TLS will be irrelevant. Progress!

- ###Introduce a new `scout.delay` command

  Now you can delay things inside of ScoutScript.  It can be called multiple times without conflict. Here's how you use it:

  ```c
  scout.delay(1000, "led.red"); scout.delay(3000, "led.off");
```

  This will turn the LED red after one second, and turn it off two seconds later, since both timers will start immediately.  Be sure to run both of those commands in the example above on the same line so you get proper timing!

- ###Introduce `hq.print` and `hq.report` for sending info directly to the API
  These two new commands make it really easy to print or send *anything* to the API.

  `hq.print` is a quick and easy way to print something on the HQ console, from directly in your ScoutScript.

  `hq.report` is how you can send any custom report you want up to the API.  It will be available via all of the API access methods, with a report type of "custom".  Make your [custom chipmunk report](http://support.pinocc.io/hc/en-us/articles/201864490-Chipmunk-Detector) super easy with this.

- ###Introduce `memory.report` for detailed memory stats

  This used to be buried in the `uptime` report, but we wanted to show you more.  Heres's what it looks like:

  ```json
  {"type":"memory","used":559,"free":18324,"large":17756}
```

  This now not only gives you the memory used, but the total free memory, and the largest non-fragmented memory block available.

- ###Enhance `uptime.report` to include totals from both wake and sleep state

  The report for showing uptime will now give you both awake and sleep durations.  This is helpful to track total time since last reset, regardless of sleep or wake states.

  ```json
  {"type":"uptime","millis":161433,"sleep":5000,"random":-9528,"reset":"External"}
```

- ###`temperature.report` report now includes C and F.

  Seems like a simple thing, but now the conversion is done on a Scout itself, so all of your reporting, and API clients will have consistent values and don't need to worry about converting on their side.

  ```json
{"type":"temp","c":26,"f":79}
```
  The previous high and low values have been removed, since the API now stores lifetime historical data per Scout.

- ### New, more consistent command names for sending and receiving mesh messages
  `mesh.send` has been renamed to `message.scout`, and `mesh.announce` has been renamed to `message.group`.  The arguments are the same!

- ### New, more consistent command names for all event handlers
  The previous event handlers were all over the map in terms of consistency.  They are now changed so that every event handler starts with the word `on.`, so it's easy and consistent.  Here are the current event handlers available:
  - `on.message.scout(fromId, keys)`: called whenever a message is received from another Scout
  - `on.message.group(groupId, fromId, keys)`: called whenever a message is received from another Scout addressed to a group
  - `on.message.signal(fromId, RSSI)`: called whenever an acknowledgement packet is received back to a sending scout.  The second argument has the RSSI value from the remote Scout.
  - `on.d2(value, mode)` - `on.d8(value, mode)`: called whenever the digital pins D2-D8 change values or modes
  - `on.d2.low` - `on.d8.low`: called whenever the given pin's value goes low
  - `on.d2.high` - `on.d8.high`: called whenever the given pin's value goes high
  - `on.a2(value, mode)` - `on.a7(value, mode)`: called whenever the analog pins A0-A7 change values or modes
  - `on.battery.level(level)`: called whenever the battery percentage changes
  - `on.battery.charging(flag)`: called whenever the battery starts or stops charging
  - `on.temperature(tempC, tempF)`: called whenever the temperature changes

- ###Other small changes and cleanups
  - Deprecate `mesh.key` in favor of `mesh.setkey`
  - Return a "usage" error message for incorrectly called commands
  - Make ScoutScript commands return consistent values
  - Remove extra-defined class resulting in memory saving
  - Return the key of the result for `uptime.getlastreset` so it can be used in boolean contexts
  - Deprecate `scout.free` since `memory.report` now exists
  - Remove battery voltage event handler
  - Event handlers can now be defined in C/C++ or in ScoutScript.  (thanks @drogge!)
  - Added `power.isvccenabled` that returns true/false if the VCC pin is currently supplying voltage or not
  - Added `power.hasbattery` that returns true/false if a battery is currently connected
  - Added licenses to all source code
