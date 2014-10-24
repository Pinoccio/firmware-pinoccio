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
quickly get all three of the above requirements done. This is a 1GB
torrent containing a VM template that can be imported into either
Virtualbox or VMWare Workstation/Fusion.

Magnet URI (Built 18 Mar 2014):

magnet:?xt=urn:btih:788538B08B13E723AC3649BB813891DC785EF99C

The `create-vm-image.sh` script will build a new VM image from scratch (advanced users only!)

--------------
1: Arduino IDE
--------------
The toolchain (gcc, libc, binutils and avrdude) shipped with older
Arduino versions is too old and does not contain the right patches for
the Atmega256RFR2 chip used in the Pinoccio Scout. For this reason, you
need at least IDE version 1.5.7 or above.

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
folder, the libraries and the mains sketch. There are a few ways to
achieve this:

 1. Set the Arduino sketchbook path to the the `firmware-pinoccio` dir
    you created above (under File -> Preferences). This is the easiest
    and will make everything work right away. The downside here is that
    the Arduino IDE will no longer see your regular libraries and
    sketches, until you change the sketchbook path back.

 2. Create symlinks from your sketchbook to the folder above. e.g.:

    ```
    mkdir -p /path/to/sketchbook/hardware /path/to/sketchbook/libraries
    ln -s /path/to/firmware/pinoccio/hardware/pinoccio /path/to/sketchbook/hardware
    ln -s /path/to/firmware/pinoccio/Bootstrap /path/to/sketchbook/
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
(File->Examples->Pinoccio->[example]. Make sure your Board is set to
Pinoccio and the Port is set to your serial port.

------------------------------------
Official firmware / Bootstrap builds
------------------------------------
When shipped and when updating the Pinoccio scout boards through the
Pinoccio HQ, it will contain an official firmware build. This build is
generated using the "Bootstrap" example from the library-pinoccio
repository. This example pulls in the needed libraries and generates the
main firmware that offers a ScoutScript prompt and knows how to talk to
the various hardware attached to the Pinoccio scout.

These official builds are generated using the `build.sh` script in this
repository, which automatically detects the build number (based on tags
and git revision) and includes that in the build. If you build the
Bootstrap example through the Arduino IDE normally, the build number and
revision will be set to -1 and "unknown".

See the comments at the top of the `build.sh` script for instructions on
how to use it.
