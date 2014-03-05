MAIN=$(abspath $(firstword $(wildcard *.ino)))
BOARD=pinoccio:avr:pinoccio
PORT=/dev/ttyACM0
BUILD_DIR=$(abspath build)
PREFS=--pref "build.path=$(BUILD_DIR)"
# Uncomment these to automatically set up the entire environment. One
# caveat, with Arduino 1.5.6 this permanently changes your sketchbook
# location.
#SKETCHBOOK=$(abspath $(CURDIR)/..)
#PREFS=$PREFS --pref "sketchbook.path=$(SKETCHBOOK)"

-include Makefile.local

compile:
	mkdir -p $(BUILD_DIR)
	arduino-git $(PREFS) --verbose --verify --board $(BOARD) --port $(PORT) $(MAIN)

upload:
	arduino-git $(PREFS) --verbose --upload --board $(BOARD) --port $(PORT) $(MAIN)

disasm: compile
	avr-objdump --disassemble --source --demangle $(BUILD_DIR)/*.elf
