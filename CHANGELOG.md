#2014073101

- #####Add better sleep and awake timing resolution, now down to 16µS! (library-pinoccio)

- #####Add ScoutScript function caching for much faster boot and event handling responsiveness (library-pinoccio)

- #####Add support for faster, non-polling communications for WiFi backpack hardware version v1.1 (library-pinoccio)

- #####Add support in ScoutScript for the wifi.config second argument to be optional, for open networks (library-pinoccio)

- #####Additional bridge-mode serial REPL refactoring (library-pinoccio)

- #####Ability to calibrate temperature for each Scout--to offset external factors (library-pinoccio)


#2014072201

- #####Add BOM and labels for jumpers in Pinoccio Scout schematic (hardware-pinoccio)

- #####Updated Lightweight Mesh library to v1.2.1 (library-atmel-lwm)

- #####Add support for disabled and disconnected states for pins, for lower sleep power draw (library-pinoccio)

- #####Add millis to all reports for clean synchro/deduplication at API side (library-pinoccio)

- #####Preliminary support for bridge mode (library-pinoccio)

- #####Add support for hardware PWM for digital pins 2, 3, 4, and 5 (library-pinoccio)

- #####Add beccapurple as a supported RGB LED color (library-pinoccio)


#2014060501

- #####Add Serial Flash example for how to use the storage chip on the lead scout

- #####Add ClearScoutScript example sketch to reset functions defined in EEPROM

- #####Include simple Bluetooth example sketch

- #####Slightly modify ScoutScript banner for easier reading

- #####Solve issue with mesh security key, when given less than 16 bytes

- #####Better handling for skipping NTP on non-SSL connections for lead scout

- #####Fix incorrect ScoutScript usage arguments, specifically for `pin.save` and `hq.report`

- #####Clean up `power.sleep` handling

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
