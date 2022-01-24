# RG351* Jets of Time on-device generator
Jets of Time generator for RG351* devices, no need for keyboard or internet connection.

Generates Jets of Time (https://github.com/Anskiy/jetsoftime/ , http://www.ctjot.com/) seeds on-device.

Tested on 351ELEC (https://351elec.de/) release 20211122 Pineapple Forest and ArkOS (https://github.com/christianhaitian/arkos/wiki) RG351P final release.

## Installation:

Download zip, extract to either:

351ELEC: ``/storage/roms/ports``

ArkOS: ``/roms/ports``

Restart EmulationStation or update gameslist to have the tool appear in EmulationStation.

## Setup:
Once loaded, d-pad up/down to navigate menu, d-pad left/right to pick accept or decline, A/B to choose option.

You will need to supply your own Chrono Trigger ROM for the randomizer backend to work on. The filepath to it can be navigated to with the option ``Save/Load Configuration > Modify System Variable > Input ROM``

By default, the randomized ROMs will be output to your SNES romhacks directory (351ELEC: ``/storage/roms/snesh``, ArkOS ``/roms/snes-hacks``). This can be modified under ``Save/Load Configuration > Modify System Variable > Output Directory``

The Jets backend supplied is the latest commit of https://github.com/Anskiy/jetsoftime/ as of time of writing.

## Usage:
Once set up with an input ROM, a Jets backend and an output directory, go to ``Set Seed Flags`` to modify all variables which affect the randomized game content in the output ROM.

Once variables are set to your liking, navigate to ``Generate Seed`` and review input ROM, output directory, and flagset. If correct, select Yes and the newly-generated ROM will be made and moved to your output directory.

Restart EmulationStation or update gamelists to populate it, then play it like any other SNES ROM.

## Thanks
Jets of Time (https://github.com/Anskiy/jetsoftime/) for new enjoyment of one of the best video games yet created.

PortMaster (https://github.com/christianhaitian/arkos/wiki/PortMaster) for demonstrating this method of scripting for user input without a keyboard, without which this would not have been created.
