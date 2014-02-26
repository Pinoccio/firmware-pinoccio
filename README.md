firmware-pinoccio
=================

This repository contains the default sketch to use on a Pinoccio scout,
as well as references to all external repositories that are needed to
build it.

This repository serves two main purposes:

 - Allow easily cloning and updating all required repositories for
   development
 - Allow tracking exactly what collection of code was used for
   particular official builds.

To get started with Pinoccio and this sketch, you need three things:

 1. The Arduino IDE (nightly build with an updated toolchain).
 2. The "pinoccio" hardware folder that tells the Arduino IDE about the
    Pinoccio Scout and allows compiling sketches for it.
 3. A collection of libraries that know how to talk to the various parts
    of the Pinoccio Scout and its backpacks.

Note that if you don't need the various support libraries and just want
to write bare sketches for the Pinoccio Scout, only steps 1 and 2 are
enough (e.g., you can run blink without step 3).

-----------------------------
Quick start: Preconfigured VM
-----------------------------
There is a pre-configured Pinoccio VM available, which you can use to
quickly get all three of the above requirements done. This is a 3.4GB
torrent containing a VM template that can be imported into either
Virtualbox or VMWare Workstation/Fusion.

*This link is outdated and does not match the current version*

Magnet URI (current version is 0.9):

magnet:?xt=urn:btih:3A291BD6C4EC6C720B73D0625285692DF7F030A7

--------------
1: Arduino IDE
--------------
The toolchain (gcc, libc, binutils and avrdude) shipped with the regular
Arduino downloads too old and does not contain the right patches for the
Atmega256RFR2 chip used in the Pinoccio Scout.

Fortunately, the Arduino is preparing an update for the toolchain and
has a preview version available already. You can download this version
here:

 - Windows: [http://downloads.arduino.cc/arduino-avr-toolchain-nightly-gcc-4.8.1-windows.zip]()
 - OSX: [http://downloads.arduino.cc/arduino-avr-toolchain-nightly-gcc-4.8.1-macosx.zip]()
 - 32-bit Linux: [http://downloads.arduino.cc/arduino-avr-toolchain-nightly-gcc-4.8.1-linux32.tgz]()
 - 64-bit Linux: [http://downloads.arduino.cc/arduino-avr-toolchain-nightly-gcc-4.8.1-linux64.tgz]()

There is currently one caveat: The avrdude version included in above
builds is version 5, which does not support the atmega256rfr2 chip yet.
This is expected to be fixed soon, but until then you should either
overwrite `hardware/tools/avr/bin/avrdude` with a version 6 binary, or
modify `platform.txt` to point to the right version.

------------------------------------
2 & 3: hardware folder and libraries
------------------------------------
You'll need to get the pinoccio hardware folder into the `hardware`
directory of your sketchbook, and the various libraries into the
`libraries` directory of your sketch book.

All needed repositories are configured as submodules of this
repositories. Additionally, a script named `update` is provided which
can set up all the submodules for you automatically.

```
$ git clone https://github.com/Pinoccio/firmware-pinoccio.git
(...output...)
$ cd firmware-pinoccio
$ ./update.sh
(...output...)
$ ls
Bootstrap  hardware  libraries  update.sh
$ ls hardware/
pinoccio
$ ls libraries/
bitlash  gainspan  lwm  pinoccio
```

Now, you need to make sure the Arduino IDE learns about this hardware
folder and these libraries. There are a few ways to achieve this:

 1. Set the Arduino sketchbook path to the the `firmware-pinoccio` dir
    you created above (under File -> Preferences). This is the easiest
    and will make everything work right away. The downside here is that
    the Arduino IDE will no longer see your regular libraries and
    sketches, until you change the sketchbook path back.
 2. Create symlinks from your sketchbook to the folder above. e.g.:

    ```
    mkdir -p /path/to/sketchbook/hardware /path/to/sketchbook/libraries
    ln -s /path/to/firmware/pinoccio/hardware/pinoccio /path/to/sketchbook/hardware
    for i in /path/to/firmware-pinoccio/libraries/*; do
      ln -s $i /path/to/sketchbook/libraries
    done
    ```
    The downside of this approach is that you need to maintain the
    symlinks when a library is added or removed.
 3. Copy the various repositories into your sketchbook (or just clone
    them in the right place to begin with). This requires manually
    running git pull in each repository to stay up to date, so this is
    probably only useful if your OS does not support symbolic links.

### Development ###

If you want to develop the hardware folder or libraries, you can
normally work in the `hardware/pinoccio` and `libraries/*` directories.
These are normal git repositories.

One caveat is that the `git submodule` command has created all
repositories in "detached HEAD" state. So, before you start, you should
first check out a normal branch where you can commit your work. When
calling `update.sh`, `git submodule` is called with the `--rebase` flag,
which should prevent `git submodule` from overwriting your changes or
detaching the head again.


If you make changes to the submodules, these will also show up as
changes in the working copy of the main `firmware-pinoccio` repository.
This is because the main repository contains the explicit revision of
each of its submodules. Usually it's ok to just commit these along with
other changes (they provide historical reference of the environment used
to create the commit).


Also note that all submodules are cloned using `https://` urls, so
they can work anonymously. If you have commit access to these
repositories and want to use ssh access so you can push, you can tell
git to replace https with ssh automatically:

    git config --global url.git@github.com:.insteadOf https://github.com/

Note that this command applies to _all_ github urls in all repositories.

------------------
Compiling Sketches
------------------

You should then be able to open one of the Pinoccio examples
(File->Examples->Pinoccio->[example]) or the main sketch
(File->Sketchbook->Bootstrap) and compile it. Make sure your Board is
set to Pinoccio and the Port is set to your serial port.
