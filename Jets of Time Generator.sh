#!/bin/bash
#
# Jets of Time RG351* Seed Generator
#
# Based off of:
#
# PortMaster
# https://github.com/christianhaitian/arkos/wiki/PortMaster
# Description : A simple tool that allows you to download
# various game ports that are available for RK3326 devices
# using 351Elec, ArkOS, EmuElec, RetroOZ, and TheRA.
#
# and
#
# Jets of Time
# https://github.com/Anskiy/jetsoftime/
# Jets of Time is a remake of Wings of Time, intended to 
# create faster seeds while taking more liberties with the
# gameplay. The progression has been altered greatly, and 
# seeds can usually be beat within the 2:30:00 mark. The 
# gameplay is still mostly classic Chrono Trigger, so being
# good at the base game helps a lot.
#
# 

#USERS: to modify output directory and input filename, ctrl+f to sys_infile and sys_outdir inside initVars
#Alternatively, modify ${dir_root}/config/user_sys.txt and restart script

ESUDO="sudo"
GREP="grep"
WGET="wget"
export DIALOGRC=/

##Directory setup, search current working dir for $0

#ArkOS and 351ELEC appear to pass absolute paths when starting a game from emulationstation. abuse this fact to get root dir
dir_root="${0%/*}"

#if it somehow does not exist, ensure it exits properly
if [ ! -d "${dir_root}" ]; then
    echo Incapable of locating root directory for "${0}" . Exiting. 2>&1
    sleep 5
    exit 1
fi

#testing if systen is 351ELEC
sudo echo "Testing for sudo..."
if [ $? != 0 ]; then
#it is 351ELEC
  ESUDO=""
  export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${dir_root}/libs"
  GREP="${dir_root}/grep"
  WGET="${dir_root}/wget"
  LANG=""
  export whichOSIsIt="351ELEC"

else
#it's not 351ELEC, FIXME flash an SD card to test this functionality with
  dpkg -s "curl" &>/dev/null
  if [ "$?" != "0" ]; then
    $ESUDO apt update && $ESUDO apt install -y curl --no-install-recommends
  fi

  dpkg -s "dialog" &>/dev/null
  if [ "$?" != "0" ]; then
    $ESUDO apt update && $ESUDO apt install -y dialog --no-install-recommends
    temp=$($GREP "title=" /usr/share/plymouth/themes/text.plymouth)
    if [[ $temp == *"ArkOS 351P/M"* ]]; then
      #Make sure sdl2 wasn't impacted by the install of dialog for the 351P/M
      $ESUDO ln -sfv /usr/lib/aarch64-linux-gnu/libSDL2-2.0.so.0.14.1 /usr/lib/aarch64-linux-gnu/libSDL2-2.0.so.0
      $ESUDO ln -sfv /usr/lib/arm-linux-gnueabihf/libSDL2-2.0.so.0.10.0 /usr/lib/arm-linux-gnueabihf/libSDL2-2.0.so.0
    fi
  fi

  isitarkos=$($GREP "title=" /usr/share/plymouth/themes/text.plymouth)
  if [[ "$isitarkos" == *"ArkOS"* ]]; then
    if [[ ! -z "$( timedatectl | grep inactive )" ]]; then
      $ESUDO timedatectl set-ntp 1
      export whichOSIsIt="ArkOS"
    fi
  fi
fi

$ESUDO chmod 666 /dev/tty0
export TERM=linux
export XDG_RUNTIME_DIR=/run/user/$UID/
printf "\033c" > /dev/tty0
dialog --clear

#assume RG351P/M/MP

hotkey="Select"
height="15"
width="55"

#RG351V
if [[ -e "/dev/input/by-path/platform-ff300000.usb-usb-0:1.2:1.0-event-joystick" ]]; then
  param_device="anbernic"
  if [ -f "/boot/rk3326-rg351v-linux.dtb" ] || [ "$(cat "/storage/.config/.OS_ARCH" || echo not)" == "RG351V" ]; then
    $ESUDO setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
    height="20"
    width="60"
  fi
elif [[ -e "/dev/input/by-path/platform-odroidgo2-joypad-event-joystick" ]]; then
  if [[ ! -z $(cat /etc/emulationstation/es_input.cfg | $GREP "190000004b4800000010000001010000") ]]; then
    param_device="oga"
    hotkey="Minus"
  else
    param_device="rk2020"
  fi
elif [[ -e "/dev/input/by-path/platform-odroidgo3-joypad-event-joystick" ]]; then
  param_device="ogs"
  $ESUDO setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  height="20"
  width="60"
else
  param_device="chi"
  hotkey="1"
  $ESUDO setfont /usr/share/consolefonts/Lat7-Terminus20x10.psf.gz
  height="20"
  width="60"
fi

toolsfolderloc="${dir_root}"

cd "${toolsfolderloc}"

$ESUDO "${toolsfolderloc}/oga_controls" "${0##*/}" "$param_device" > /dev/null 2>&1 &

userExit() {
  $ESUDO kill -9 $(pidof oga_controls)
  $ESUDO systemctl restart oga_events &
  dialog --clear
  printf "\033c" > /dev/tty0
  exit 0
}

whichSystemIsIt()
{
local result=$(grep "title=" "/usr/share/plymouth/themes/text.plymouth")

#ArkOS
if [[ "${result}" == *"ArkOS"* ]]; then
        echo "ArkOS"
        return
fi

#TheRA
if [[ "${result}" == *"TheRA"* ]]; then
        echo "TheRA"
        return
fi

#351ELEC if nothing else works
echo "351ELEC"
}

#----------------------------------------------------------------------------------------------------------------------


initVars() {

##Directories
#cache dir, for not messing up rom collections
#uses /dev/shm/ctrando, avoids writes on disk

dir_cache="/dev/shm/ctrando"

#config dir, user configs go here, along with seed presets
dir_config="${dir_root}/config"
#for output dir for newly-generated seeds, see sys_outdir

##Decoration.
#backtitle of all dialog windows
ui_dec_backtitle="Jets of Time"

#Jets of Time current version, FIXME eventually update this to obtain version from selected jetsoftime-* commit dir
ui_dec_curversion="3.1.0"

#Non-user-configurable files, for export and import of variables
#system user config
export file_config="${dir_config}/user_sys.txt"
export file_config_name="User System Config"
export file_config_desc="Storage file for user configured system settings"

#seed user config
export file_seed_config="${dir_config}/user_seed.txt"
export file_seed_config_name="User Seed Config"
export file_seed_config_desc="Storage file for user configured seed flags"

#user configurable system variables for export and import.
#required vars: sys_*,sys_*_default,sys_*_name,sys_*_desc

#Input file from which to generate seed.
#FIXME hardcoded atm, for testing purposes. make user configurable, as we will not be allowed to ship a rom with it. (for ****ing stupid legal bs)
export sys_infile_default="${dir_root}/ct.sfc"
export sys_infile="${sys_infile}"
export sys_infile_name="Input ROM"
export sys_infile_desc="Input ROM to copy and modify to create seed.\n\nKnown working MD5 sums:\n\na2bc447961e52fd2227baed164f729dc\n395bf4d0a75717b03c0c2131495faf7a"

#output directory FIXME make this something sensible like /storage/roms/snesh instead of whatever the author has set up
export sys_outdir_default="/storage/roms/snesh/"

if [[ "$(whichSystemIsIt)" == "ArkOS" ]]; then
    export sys_outdir_default="/roms/snes-hacks"
fi

export sys_outdir="${sys_outdir_default}"
export sys_outdir_name="Output Directory"
export sys_outdir_desc="Output directory to place randomized ROM when finished."

#selected randomizer version, assumed to be in dir_root
export sys_jetsdir_default="${dir_root}/jetsoftime-e8892db4942bb728d7a801af94abd62a38bdaee7"
export sys_jetsdir="${sys_jetsdir_default}"
export sys_jetsdir_name="Jets of Time Directory"
export sys_jetsdir_desc="Directory in which the Jets of Time randomizer backend is stored."

}

initSeedVars() {
#seed variables, these options affect game content once seed is generated. 
#required vars: seed_*,seed_*_flag,seed_*_name,seed_*_desc
#except dc matrix. ree.
##export seed variables, FIXME assuming Jets upstream ever implements machine readable flagsets or provides a CLI to do the same, fix this to not duplicate the logic in randomizer.py
#Options which do not add add a flag to the seed's output filename flag string portion use underscore ( _ ) to avoid bash misordering the expected input of dialog.

#seed, string from which to derive PRNG output with which to randomize content.
export seed_seed_string=""
export seed_seed_string_flag="_"
export seed_seed_string_name="Pseudorandom Seed"
export seed_seed_string_desc="String from which to derive PRNG output with which to randomize content.\n\nA ROM randomized with the same version of Jets of Time and the same seed will produce the same ROM."

#difficulty, multistate string (Easy/Normal/Hard e/n/h)
#FIXME upstream has no code to make case insensitive, ensure input is lowercase
export seed_difficulty="n"
export seed_difficulty_flag="e,n,h"
export seed_difficulty_name="Seed Difficulty"
export seed_difficulty_desc="Easy: Makes higher quality treasure from chests and enemies more plentiful.\nNormal: Has standard treasure randomization.\nHard: Has reduced treasure quality from chests and enemies, with most enemies not dropping anything. Enemies are also scaled up to be tougher and more durable in general."
#glitch fixes, upstream 3.1.0-49dc7918e9c4a20cccf12b6eedb27f4173beceb7 DOES have case modifying code for this option.
export seed_glitch_fixes="y"
export seed_glitch_fixes_flag="g"
export seed_glitch_fixes_name="Glitch Fixes (g)"
export seed_glitch_fixes_desc="This flag disables most well known glitches, like emptying equipment slots, saving anywhere you can, and using quick menu switching to activate scripted encounters from a distance and skip them. Tricks that aren't blocked by this flag are generally accepted as valid for races, the most notable one being the menu glitch."
#Lost Worlds
export seed_lost_worlds="n"
export seed_lost_worlds_flag="l"
export seed_lost_worlds_name="Lost Worlds (l)"
export seed_lost_worlds_desc="This activates Lost Worlds, a huge twist on the gameplay of Jets of Time. When it's activated:\n    You start out in 2300 AD, and can explore it, 12000 BC and Prehistory freely.\n    Your characters start at level 15, have three techs learnt, and have magic unlocked.\n     You can buy from the guarantee shop in the fair before starting, but can't access it afterwards until either Zeal 2 or the Lavos shell is defeated.\n     To access the Ocean Palace, you need to defeat Black Tyrano and collect the Ruby Knife."
#boss scaling with progression, make bosses harder if they gate progression key items
export seed_boss_scalar="n"
export seed_boss_scalar_flag="b"
export seed_boss_scalar_name="Boss Scaling (b)"
export seed_boss_scalar_desc="This flag activates boss scaling. Bosses holding important key items, directly or otherwise, get scaled up. When it's activated:\n    Bosses holding the Ruby Knife, Clone or C. Trigger get scaled up the most, usually.\n    Bosses holding keys to one of the three routes, or to a location that holds the three aforementioned key items, get scaled up a little less.\n    Bosses holding keys to those specific locations get scaled up the least, while still being noticeably stronger.\n    Dragon Tank gets scaled based on the strongest key item placed in the Future.\n    If the c flag is on, R Series scale up based on the character placed in Proto Dome. Crono and Magus are the highest ranked, and Frog, Marle and Lucca the least ranked.\n    Bosses that are not locked behind anything will not be scaled. This means that Zombor, Heckran, and Masa & Mune(both fights) will always be the same strength regardless of seed."
#boss rando, shuffle the locations different bosses appear in
export seed_boss_rando="y"
export seed_boss_rando_flag="ro"
export seed_boss_rando_name="Boss Shuffle (ro)"
export seed_boss_rando_desc="Activates boss randomization. This currently shuffles single part bosses among themselves, and dual part bosses in their own pool, however a few bosses that don't show up in a regular seed are also included in the pool. "
#Zeal 2 final boss
export seed_zeal_end="y"
export seed_zeal_end_flag="z"
export seed_zeal_end_name="Zeal 2 Final Boss (z)"
export seed_zeal_end_desc="This makes Zeal 2 an alternate final boss. Defeating her will win the game and grant a different ending. Defeating Lavos still remains an option, and grants the regular ending."
#quick pendant charging, this parameter is not requested by randomizer.py if lost worlds is active
export seed_quick_pendant="y"
export seed_quick_pendant_flag="p"
export seed_quick_pendant_name="Early Pendant Charge (p)"
export seed_quick_pendant_desc="This makes the Pendant charge earlier. Precisely, it charges the moment you complete the Prison quest, allowing you to open sealed chests and doors a lot earlier than normal."
#locked characters, require additional tasks complete to get Proto Dome / Dactyl Nest characters
export seed_locked_characters="n"
export seed_locked_characters_flag="c"
export seed_locked_characters_name="Locked Characters (c)"
export seed_locked_characters_desc="This locks the characters in Proto Dome and Dactyl Nest further. The Proto Dome character requires the Factory to be completed, while the Dactyl Nest character requires the Dreamstone to access."
#randomized tech list
export seed_random_tech="y"
export seed_random_tech_flag="te"
export seed_random_tech_name="Randomize Tech List (te)"
#yay execution order
export seed_random_tech_balance_name="Balance Random Techs (tex)"
export seed_random_tech_desc="Randomizes the tech list for each character, with no weighting.\n\nEnable both this and '${seed_random_tech_balance_name}' to add weighted tech randomization functionality."
#balance the randomized tech list, not called if tech list is not randomized
export seed_random_tech_balance="n"
export seed_random_tech_balance_flag="x"
export seed_random_tech_balance_desc="Enables weighted randomization of the randomized techs.\n\nRequires '${seed_random_tech_name}' to be enabled."
#unlocked magic at start
export seed_no_spekkio="n"
export seed_no_spekkio_flag="m"
export seed_no_spekkio_name="Unlocked Magic (m)"
export seed_no_spekkio_desc="Magic begins unlocked for Crono, Marle, Lucca and Frog.\nSpekkio does not need to be visited to progress beyond the first three techs for those characters."
#quiet mode, no music
export seed_quiet_mode="n"
export seed_quiet_mode_flag="q"
export seed_quiet_mode_name="Quiet Mode (q)"
export seed_quiet_mode_desc="Stops all music from playing."
#chronosanity
export seed_chronosanity="n"
export seed_chronosanity_flag="cr"
export seed_chronosanity_name="Chronosanity (cr)"
export seed_chronosanity_desc="An alternate mode, where key items can be found from chests and are not limited to specific bosses or quests. Note that key items can never be in chests that are lost or made inaccessible through events, like the Prison sequence or Magus' Castle. They will also never show up in the endgame dungeons of Ocean Palace and Black Omen either."
#duplicate characters
export seed_duplicate_chars="n"
export seed_duplicate_chars_flag="dc"
#yay more execution order
export seed_duplicate_techs_name="Duplicate Character Dual Techs"
export seed_duplicate_chars_name="Duplicate Characters (dc)"
export seed_duplicate_chars_desc="Allow duplicate characters to exist. You will still require the characters initially named Marle, Robo and Frog to complete story events (Prism Shard, Desert, Magus's Castle). Enable '${seed_duplicate_techs_name}' to allow duplicate characters to learn dual techs with themselves."
#duplicate chars learn dual techs with each other FIXME upstream doesn't have code to ensure uppercase input, causing it to fail to pass to randomizer. handleUpstreamCodeErrors handles this.
export seed_duplicate_techs="y"
export seed_duplicate_techs_flag="_"
export seed_duplicate_techs_desc="Enables dual techs for duplicate characters. Has no effect without '${seed_duplicate_chars_name}' enabled."
#Duplicate character matrix to shim in. going to have to handle these as a special case in seedSettingsSaveCurrentFlags to avoid overpopulating the seed flag menu
export charMatrixList=(Crono Marle Lucca Robo Frog Ayla Magus)

#init char matrices
#except f u because arrays cannot be exported without chichanery. reeee bash 4.3 not delivering array features
for c in "${charMatrixList[@]}"; do
    for i in 0 1 2 3 4 5 6; do
        export charMatrix${c}${i}=y
    done
done

#tabsanity, all treasures are tabs
export seed_tab_treasures="n"
export seed_tab_treasures_flag="tb"
export seed_tab_treasures_name="Tab Treasures (tb)"
export seed_tab_treasures_desc="Turns all loot from chests into tabs. Note that shops and monster drops are unaffected."
#shop prices, multistate string [Normal(n), Free(f), Mostly Random(m), or Fully Random(r)]
export seed_shop_prices="n"
export seed_shop_prices_flag="_,spf,spm,spr"
export seed_shop_prices_name="Shop Pricing Randomization (spf,spm,spr)"
export seed_shop_prices_desc="Normal: Standard pricing.\nFree: Shops sell all items for free.\nMostly Random: Shops sell items at random prices, excluding some cheap consumables like ethers, heals and such.\nFully Random: Shops sell all items at random prices."
##--------------------------------------------------------------------
}

#load user configs from disk, if they exist.
importVars()
{
#system vars
if [ -e "${file_config}" ]; then
    source "${file_config}"
fi
#seed vars
if [ -e "${file_seed_config}" ]; then
    source "${file_seed_config}"
fi
}


#ensure directories exist, except root
ensureDirsExist(){
for var in $(declare -p | grep -e '--\s*dir_' | grep -v dir_root | sed "s@declare -- @@;s@=.*@@"); do
    if [ ! -d "${!var}" ]; then
        mkdir -p "${!var}"
    fi
done
}


#ensure standard dialog views
dialogStandardMenu=( dialog \
    --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--no-collapse \
   	--clear \
    --cancel-label "Cancel" )
    
dialogStandardStub=( dialog \
    --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--no-collapse \
   	--clear \
    --title "[ Standard Function Stub ]" )
    
#A big thank you to PortMaster for both inspiring and demonstrating this technique to get user input on RG351* devices.
thanksScreen()
{
dialog \
    --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--no-collapse \
   	--clear \
    --cancel-label "Return" \
    --title "[ About & Thanks ]" \
    --msgbox "Jets of Time v${ui_dec_curversion}\nOn-device generator of seeds for RG351* devices, no keyboard necessary.\nThanks to:\n\n   Jets of Time (https://github.com/Anskiy/jetsoftime/) for new enjoyment of one of the best video games yet created.\n\n   PortMaster (https://github.com/christianhaitian/arkos/wiki/PortMaster) for demonstrating this method of scripting for user input without a keyboard, without which this would not have been created." $height $width  2>&1 > /dev/tty0 
}
#

#Usage: $0 randopy
#Upstream commit has code differences between GUI and CLI invocation, causing ROMs generated by the two methods to differ despite same input.
handleUpstreamCodeErrors() {


local file="${1}"

#printf apparently dumps backspaces into vars. good to know, get around it.
local char_choices_shim="$(buildDuplicateCharactersShim | tr -d '\b')"

#Upstream jets has unconditional import of gui modules, causing crashes upon invokation. modify to make gui conditional by moving the import under the gui init ifelse
#Duplicate characters (te) doesn't ask for the character rando matrix, is never defined. causes error with tech rando as well. shim in our own array
#CLI does not force uppercase on input for duplicate character dual techs. correct this deficiency.

sed -i -f - "${file}" << _EOF_
/import randomizergui as gui/d;s@\(\s*\)gui\.guiMain@\1import randomizergui as gui\n&@
/if duplicate_chars == "Y":/{N;/charrando/{s@[ ]\+charrando@         char_choices = ${char_choices_shim}\n&@}}
/input("Should duplicate characters learn dual techs?/{N;s@[ ]\+else@         same_char_techs = same_char_techs.upper()\n&@}
_EOF_
}

#make a machine-readable export date. why busybox can't accept +%s input when it is capable of outputing that i have absolutely no idea
#FIXME this date command, and all others, was based off Busybox 1.32.1; it may not be perfectly compliant.
makeDateString()
{
date ${@+-d @${@}} +%Y.%m.%d-%H:%M:%S
}

#build the flagset
#we only care about the display order, perhaps put buildDisplayFlagOrder into initVars so can use for the display order in 
buildDisplayFlagset()
{
#FIXME at some point go back and enter *_type variables so one can iterate over declare output instead of having duplicated hardcoded value types (multistate, boolean, string). refactor this to check ${flagvar}_type for caseblock

local buildDisplayFlagOrder=( seed_difficulty seed_glitch_fixes seed_lost_worlds seed_boss_scalar seed_boss_rando seed_zeal_end seed_quick_pendant seed_locked_characters seed_random_tech seed_random_tech_balance seed_no_spekkio seed_quiet_mode seed_chronosanity seed_duplicate_chars seed_duplicate_techs seed_tab_treasures seed_shop_prices )

local flagset=""
for flagvar in "${buildDisplayFlagOrder[@]}"; do
    local flag="${flagvar}_flag"
    local value="${!flagvar}"
    case "${flagvar}" in
#multistates
        seed_difficulty|seed_shop_prices)
            flagset="${flagset}$(echo "${!flag}" | tr ',' '\n' | grep "${value}\|_" | tr -d '_' | tr -d '\n' )"
        ;;
        seed_quick_pendant)
            if [ ! "${seed_lost_worlds}" == "y" ]; then
                flagset="${flagset}${!flag}"
            fi
        ;;
        seed_random_tech_balance) 
            if [ "${seed_random_tech}" == "y" -a "${value}" == "y" ]; then
                flagset="${flagset}${!flag}"
            fi
        ;;
        #duplicate techs has no flag associated with it. in the event that changes, this will catch it.
        seed_duplicate_techs) 
            continue
        ;;
        *) 
            if [ "${value}" == "y" ]; then
                flagset="${flagset}${!flag}"
            fi
        ;;
    esac
done

echo "${flagset}"

}


seedSettingsReloadUserFlags()
{
source "${1}"
}

#ask user to confirm reloading of previously-saved seed flag settings. ${1} is the absolute path to a configuration file.
seedSettingsReloadUserConfirm()
{
local seed_vars=( $(  declare -p | grep ' seed_' | grep -v -e '_default=' -e '_name=' -e '_desc=' -e 'def=' -e '_flag=' | sed 's@declare -. @@;s@=.*@@' ) )
local displayArray=()

local displayDialog="Do you want to restore the following seed flag values from disk?\n\nProposed flagset:$(source "${1}" ; buildDisplayFlagset)\nCurrent flagset: $(buildDisplayFlagset)\n\n"

for def in "${seed_vars[@]}"; do
    declare displayArray=("${displayArray[@]}" "Name: $(declare -p ${def}_name 2>/dev/null | cut -d '=' -f 2)"'\n' "Description: $(declare -p ${def}_desc 2>/dev/null | cut -d '=' -f 2 | sed 's@\\\\n@\\n@g')"'\n' "Current Value: $(declare -p ${def} 2>/dev/null | cut -d '=' -f 2)"'\n' "Proposed Value: $(source "${1}"; declare -p ${def} 2>/dev/null | cut -d '=' -f 2)"'\n\n' )
done

dialog \
                --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
                --no-collapse \
                --clear \
                --title "[ User Seed Flag Value Restore Confirmation ]" --yesno "${displayDialog} ${displayArray[*]}" $height $width 2>&1 > /dev/tty0
}

#print current seed_ variables to stdout. redirect this to file to save.
#busybox is annoying at times.
seedSettingsSaveCurrentFlags()
{
local seconds=$(date +%s)
local exportTime="$(makeDateString ${seconds})"
local exportFlagset="$(buildDisplayFlagset)"

echo "#NAME:User Exported"
echo "#DESC:User exported flagset. Generation time: ${exportTime}"
echo "#FLAGS: ${exportFlagset}"
echo
echo "#Export time (unix epoch): ${seconds}"
echo export exportFlagset="${exportFlagset}"
echo 
declare -p | grep ' seed_' | grep -v -e '_default=' -e '_name=' -e '_desc=' -e '_flag=' -e 'def=' | sed 's@declare -.@export@'

#DC settings
echo -e '\n#Duplicate character settings'
declare -p | grep 'charMatrix[^0-9]\+[0-6]=' | sed 's@declare -.@export@'

}

#ask user to confirm saving over previously-exported user flag settings file
seedSettingsSaveCurrentFlagsConfirm()
{
if [ ! -e "${1}" ]; then
    
    seedSettingsSaveCurrentFlags > "${1}"

    dialog \
                --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
                --no-collapse \
                --clear \
                --title "[ User Seed Value Save Confirmation ]" \
                --msgbox "'${1}' did not yet exist; the current seed flag $() settings have been saved." "${height}" "${width}" 2>&1 > /dev/tty0
                
    return 1
fi

#apparently the loop variable def gets displayed by declare. good to know, use grep to filter it out
local seed_vars=( $( source "${1}"; declare -p | grep ' seed_' | grep -v -e '_default=' -e '_name=' -e '_desc=' -e 'def=' -e '_flag=' | sed 's@declare -. @@;s@=.*@@' ) )
local displayArray=()
local diskFlagset=$( source "${1}"; buildDisplayFlagset)

local displayDialog="Do you want to overwrite the following values to disk?\n\nCurrent Flagset: $(buildDisplayFlagset)\nFlagset on Disk: ${diskFlagset}\n\n"

for def in "${seed_vars[@]}"; do
    declare displayArray=("${displayArray[@]}" "Name: $(declare -p ${def}_name 2>/dev/null | cut -d '=' -f 2)"'\n' "Description: $(declare -p ${def}_desc 2>/dev/null | cut -d '=' -f 2 | sed 's@\\\\n@\\n@g')"'\n' "Current Value: $(declare -p ${def} 2>/dev/null | cut -d '=' -f 2)"'\n' "Previously-Saved Value: $(source "${1}"; declare -p ${def} 2>/dev/null | cut -d '=' -f 2)"'\n\n' )
    
done

dialog \
                --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
                --no-collapse \
                --clear \
                --title "[ User Seed Value Save Confirmation ]" --yesno "${displayDialog} ${displayArray[*]}" $height $width 2>&1 > /dev/tty0
}


#print current sys_ variables to stdout. redirect this to file to save.
systemSettingsSaveCurrentOptions()
{
local seconds=$(date +%s)
local exportTime="$(makeDateString ${seconds})"
local exportFlagset="$(buildDisplayFlagset)"

echo "#User exported system configuration settings."
echo "#Export time (unix epoch): ${seconds}"
echo export exportTime="${exportTime}"
echo 
declare -p | grep ' sys_' | grep -v -e '_default=' -e '_name=' -e '_desc=' -e 'def=' | sed 's@declare -.@export@'
}

#ask user to confirm saving over previously-exported user system settings file
systemSettingsSaveCurrentOptionsConfirm()
{
if [ ! -e "${1}" ]; then
    
    systemSettingsSaveCurrentOptions > "${1}"

    dialog \
                --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
                --no-collapse \
                --clear \
                --title "[ User System Value Save Confirmation ]" \
                --msgbox "'${1}' did not yet exist; the current settings have been saved." "${height}" "${width}" 2>&1 > /dev/tty0
                
    return 1
fi

#apparently the loop variable def gets displayed by declare. good to know, use grep to filter it out
local sys_vars=( $( source "${1}"; declare -p | grep ' sys_' | grep -v -e '_default=' -e '_name=' -e '_desc=' -e 'def=' | sed 's@declare -. @@;s@=.*@@' ) )
local displayArray=()
local displayDialog="Do you want to overwrite the following values to disk?\n\n"

for def in "${sys_vars[@]}"; do
    declare displayArray=("${displayArray[@]}" "Name: $(declare -p ${def}_name 2>/dev/null | cut -d '=' -f 2)"'\n' "Description: $(declare -p ${def}_desc 2>/dev/null | cut -d '=' -f 2 | sed 's@\\\\n@\\n@g')"'\n' "Current Value: $(declare -p ${def} 2>/dev/null | cut -d '=' -f 2)"'\n' "Previously-Saved Value: $(source "${1}"; declare -p ${def} 2>/dev/null | cut -d '=' -f 2)"'\n\n' )
done

dialog \
                --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
                --no-collapse \
                --clear \
                --title "[ User System Value Save Confirmation ]" --yesno "${displayDialog} ${displayArray[*]}" $height $width 2>&1 > /dev/tty0
}

#reload previously-saved user system settings. in fairness can merge systemSettingsReloadUserOptions and seedSettingsReloadUserFlags with no loss of functionality. 
systemSettingsReloadUserOptions()
{
source "${1}"
}

#ask user to confirm reloading of previously-saved user system settings. ${1} is the absolute path to a configuration file.
systemSettingsReloadUserOptionsConfirm()
{
local sys_vars=( $(  declare -p | grep ' sys_' | grep -v -e '_default=' -e '_name=' -e '_desc=' -e 'def=' -e '_flag=' | sed 's@declare -. @@;s@=.*@@' ) )
local displayArray=()

local displayDialog="Do you want to restore the following values from disk?\n\n"

for def in "${sys_vars[@]}"; do
    declare displayArray=("${displayArray[@]}" "Name: $(declare -p ${def}_name 2>/dev/null | cut -d '=' -f 2)"'\n' "Description: $(declare -p ${def}_desc 2>/dev/null | cut -d '=' -f 2 | sed 's@\\\\n@\\n@g')"'\n' "Current Value: $(declare -p ${def} 2>/dev/null | cut -d '=' -f 2)"'\n' "Proposed Value: $(source "${1}"; declare -p ${def} 2>/dev/null | cut -d '=' -f 2)"'\n\n' )
done

dialog \
                --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
                --no-collapse \
                --clear \
                --title "[ User System Value Restore Confirmation ]" --yesno "${displayDialog} ${displayArray[*]}" $height $width 2>&1 > /dev/tty0
}

#ask user to confirm restoration of default settings for non-seed variables
systemSettingsResetToDefaultConfirm()
{
#find out which sys_* have default values
local sys_defaults=( $( declare -p | sed -n '/sys_.*_default/{s@.*sys@sys@;s@_default=.*@@;p}' ) )
local displayArray=()

local displayDialog="Do you want to restore the following default values?\n\n"

for def in "${sys_defaults[@]}"; do
    declare displayArray=("${displayArray[@]}" "Name: $(declare -p ${def}_name 2>/dev/null | cut -d '=' -f 2)"'\n' "Description: $(declare -p ${def}_desc 2>/dev/null | cut -d '=' -f 2 | sed 's@\\\\n@\\n@g')"'\n' "Current Value: $(declare -p ${def} 2>/dev/null | cut -d '=' -f 2)"'\n' "Default Value: $(declare -p ${def}_default 2>/dev/null | cut -d '=' -f 2)"'\n\n' )
done

dialog \
                --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
                --no-collapse \
                --clear \
                --title "[ Default System Value Restore Confirmation ]" --yesno "${displayDialog} ${displayArray[*]}" $height $width 2>&1 > /dev/tty0
}

#if user answers yes to systemSettingsResetToDefaultConfirm, perform the confirmed action
systemSettingsResetToDefault()
{
local sys_defaults=( $( declare -p | sed -n '/sys_.*_default/{s@.*sys@sys@;s@_default=.*@@;p}' ) )

for def in "${sys_defaults[@]}"; do
local defdefault=${def}_default

export "${def}"="${!defdefault}"

done
}

#displays flagset, seed, input file and output directory before generation, to allow user to confirm settings are correct.
generateSeedConfirmDialog()
{
dialog \
                    --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
                    --no-collapse \
                    --clear \
                    --title "[ Seed Generation Confirmation Dialog ]" --yesno "Input File: ${sys_infile}\nOutput directory: ${sys_outdir}${seed_seed_string:+\nSeed: '${seed_seed_string}'}\nFlagset: $( buildDisplayFlagset )\n\nDo you want to generate a seed using these settings?" "${height}" "${width}" 2>&1 > /dev/tty0
}

#manage files and pass variables to actually generate the seed.
generateSeed() {

#python3 passes pwd correctly, if invoked from a tmp directory randomizer.py will place the new rom in the same directory in which the input rom is kept.
#copy the rom to a cache directory, so we don't mess up someone's rom collection

echo -e "Copying input file to cache..."

cp "${sys_infile}" "${dir_cache}" || local cpCarry="$?"

if [ ! "${cpCarry:-0}" = 0 ]; then
    echo -e "Unable to copy input file to cache\n\nInput ROM:\n${sys_infile}\nCache directory:\n${dir_cache}"
    return 1
fi


local cacherom="${dir_cache}/${sys_infile##*/}"

#define randopy here, to allow for menu-based modification of jetsdir
local randopy="${sys_jetsdir}/sourcefiles/randomizer.py"

echo -e "Backing up randomizer.py..."

#backup randopy to restore later

cp "${randopy}" "${dir_cache}" || local cpCarry="$?"

if [ ! "${cpCarry:-0}" = 0 ]; then
    echo -e "Unable to copy randomizer.py to cache\n\nrandomizer.py:\n${randopy}\nCache directory:\n${dir_cache}"
    return 1
fi

local cachepy="${dir_cache}/${randopy##*/}"

#Upstream stable build has errors when invoked via CLI. Rectify this.
handleUpstreamCodeErrors "${randopy}"

#randomizer.py inherits pwd from shell, searches pwd for names.txt, since we do not want to copy this anywhere, pushd to randopy's location
pushd "${randopy%/*}" > /dev/null

echoSeedVars "${cacherom}" | python3 "${randopy}" -c
local carry="$?"
popd > /dev/null

#we're done with the cache copy, remove it
rm "${cacherom}"

#restore backup randopy for next execution
cp "${cachepy}" "${randopy}"

#and delete cache
rm "${cachepy}"


if [ ! "${carry}" == "0" ]; then
    echo There was an error from "${randopy}". Pipeline exit code "${carry}"
    return
fi

#randomizer.py does not output filename of newly generated seeds. find it.
local infilename="${sys_infile##*/}"
local newseed=$( ls -1 "${dir_cache}" | grep -e "${infilename%.*}.*${infilename##*.}" )

mv "${dir_cache}/${newseed}" "${sys_outdir}/${newseed}"

echo -e '\n'
echo "Seed generated."
echo -e '\n'
echo "New seed: ${newseed}"
echo "Output directory: ${sys_outdir}"

}



#echo the seed variables in a format randomizer.py can understand. FIXME Duplicates logic from randomizer.py, rework when/if randomizer gets proper CLI support
echoSeedVars(){
#-----------------------------------------------------------------------------------------------------
#/path/to/inputfile from which to generate seed is passed as ${1}, since we copy it to a cache
echo "${1}"

#give randomizer what it wants
echo "${seed_seed_string}"
echo "${seed_difficulty}"
echo "${seed_glitch_fixes}"
echo "${seed_lost_worlds}"
echo "${seed_boss_scalar}"
echo "${seed_boss_rando}"
echo "${seed_zeal_end}"

if [ ! "${seed_lost_worlds}" == "y" ]; then
    echo "${seed_quick_pendant}"
fi

echo "${seed_locked_characters}"

echo "${seed_random_tech}"
if [ "${seed_random_tech}" == "y" ]; then
    echo "${seed_random_tech_balance}"
fi

echo "${seed_no_spekkio}"
echo "${seed_quiet_mode}"
echo "${seed_chronosanity}"

#oh of course
#duplicate characters 

echo "${seed_duplicate_chars}"
if [ "${seed_duplicate_chars}" == "y" ]; then
    echo "${seed_duplicate_techs}"
fi

echo "${seed_tab_treasures}"
echo "${seed_shop_prices}"

#and finally, exit. 
echo


#-----------------------------------------------------------------------------------------------------
}

#Duplicate characters (dc)------------
duplicateCharacterMatrixMainMenu()
{
  
  local charMatrixAll=(y y y y y y y)
  local displayLen=5
 
  duplicateCharMatrixMainSelection=(dialog \
   	--backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--title "[ Duplicate Character Matrix ]" \
   	--no-collapse \
   	--clear \
    --cancel-label "Return" \
    --menu "Pick a character to choose with whom they may be replaced. Each character slot must have at minimum one possibility." "$height" "$width" 15)

while true; do

local duplicateCharacterMatrixMainOptions=($(for c in "${charMatrixList[@]}"; do echo "${c}"; echo "$(duplicateCharacterMatrixNames ${displayLen:-5} ${c} $(declare -p | grep charMatrix${c}[0-6] | sed 's@.*=@@;s@"@@g' | tr '\n' ' '))"; done) 'Allow All' '' 'Reset All' '') 

    duplicateCharacterMatrixMainChoice=$("${duplicateCharMatrixMainSelection[@]}" "${duplicateCharacterMatrixMainOptions[@]}" 2>&1 > /dev/tty0) || seedSettingsFlagConfigMenu
    
    case "${duplicateCharacterMatrixMainChoice}" in
        Allow*)
            for c in "${charMatrixList[@]}"; do
                for i in 0 1 2 3 4 5 6; do
                    declare -x "charMatrix${c}${i}"=y
                done
            done
        ;;
        Reset*)
            "${duplicateCharMatrixMainSelection[@]}" --no-cancel --msgbox "Please note a minimum of one character is required for each slot.\n\nEach slot will be set to their vanilla option." "${height}" "${width}" 2>&1 >> /dev/tty0
            for c in "${charMatrixList[@]}"; do
                for i in 0 1 2 3 4 5 6; do
                    declare -x "charMatrix${c}${i}"=n
                done
            done        
        ;;
        *)
           duplicateCharacterMatrixCharMenu "${duplicateCharacterMatrixMainChoice}" || duplicateCharacterErrorCheck "${duplicateCharacterMatrixMainChoice}"
        ;;
    esac 
            #do some checking that everyone has at least one option available to them. esp. the disallow all button
        for char in "${charMatrixList[@]}"; do
            local minone=$(declare -p | grep -e "charMatrix${char}" | cut -d '=' -f 2 | grep y | uniq | tr -d '"')
            
            if [[ ! "${minone:-n}" == "y" ]]; then
                local index=$(index=0; while [[ ${index:-0} -le ${#charMatrixList[@]} ]]; do if [[ "${char}" == "${charMatrixList[${index}]}" ]]; then echo ${index}; break; fi; ((index += 1)); done)
                export charMatrix${char}${index}=y
            fi
        done
  done
}

#Usage: $0 CHARLIMIT CHAR [yn] [yn] [yn] [yn] [yn] [yn] [yn]
#prints character names in place of numbers, optionally limiting the length of the returned string from 0.
#granted, this use case doesn't have a point of greater than 5 in CHARLIMIT
duplicateCharacterMatrixNames()
{
local CHARLIMIT="${1}"
local name="${2}"

if [ "${CHARLIMIT:-0}" -le 0 ]; then
    local CHARLIMIT="999"
fi

shift
shift

local index=0
local output=""

for n in "${@}"; do

    if [[ "${n,,}" == "y" ]]; then
        output+=$(printf '%s' "${charMatrixList[${index}]:0:${CHARLIMIT}}")
    fi
    
    (( index += 1 ))
done

printf '%s' "${output:-None}"
}

duplicateCharacterMatrixCharMenu()
{
local char="${1}"
  
  duplicateCharMatrixCharSelection=(dialog \
   	--backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--title "[ Duplicate Character Matrix: ${char} ]" \
   	--no-collapse \
   	--clear \
    --cancel-label "Return" \
    --menu "With whom may ${char} be replaced? At minimum, one choice must be present." "$height" "$width" 15)
 
while true; do
    
    #at least this one doesn't have to deal with whitespace
    
    oldIFS="${IFS}"
    IFS='|' duplicateCharacterMatrixSelection=($(index=0; for c in "${charMatrixList[@]}"; do var=charMatrix${char}${index}; echo "${c}" "${!var}"; (( index += 1 )); done | tr ' ' '|' | tr '\n' '|' ))
    IFS="${oldIFS}"

    duplicateCharacterMatrixCharChoice=$("${duplicateCharMatrixCharSelection[@]}" "${duplicateCharacterMatrixSelection[@]}" 2>&1 > /dev/tty0) || return

    local choiceIndex="$(index=0; while [[ ${index} -le ${#charMatrixList[@]} ]]; do if [[ ${duplicateCharacterMatrixCharChoice} == "${charMatrixList[${index}]}" ]]; then echo ${index}; break; fi; ((index += 1)); done)"
    
    case "${choiceIndex}" in
        *)
            local realvar=charMatrix${char}${choiceIndex}
  
            if [[ "${!realvar}" == "y" ]]; then
                export charMatrix${char}${choiceIndex}="n"
            else 
                export charMatrix${char}${choiceIndex}="y"
            fi
        ;;
    esac
    
done
}

#error check, need at minimum one character per slot
duplicateCharacterErrorCheck()
{
local char="${1}"
local check="$(duplicateCharacterMatrixNames ${displayLen:-5} ${char} $(declare -p | grep charMatrix${char}[0-6] | sed 's@.*=@@;s@"@@g' | tr '\n' ' '))"

  duplicateCharErrorCheckUi=(dialog \
   	--backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--title "[ Duplicate Character Matrix: ${char} ]" \
   	--no-collapse \
   	--clear \
    --no-cancel )

if [[ "${check}" == "None" ]]; then
    "${duplicateCharErrorCheckUi[@]}" --msgbox "Character slots must have, at minimum, one possibilty. ${char} will be representing themselves." "${height}" "${width}" 2>&1 > /dev/tty0
    local index=$(index=0; while [[ ${index:-0} -le ${#charMatrixList[@]} ]]; do if [[ ${char} == "${charMatrixList[${index}]}" ]]; then echo ${index}; break; fi; ((index += 1)); done)
    export charMatrix${char}${index}=y
fi

}

#outputs char_choices array FIXME it prints backspace characters, which are then stored in variables. tr -d '\b' will delete them
buildDuplicateCharactersShim()
{
printf '%s' '['

for c in "${charMatrixList[@]}"; do
    index=0
    printf '%s' '['
    while [[ "${index:-0}" -lt "${#charMatrixList[@]}" ]]; do
        local indir=charMatrix${c}${index}
        if [[ "${!indir}" == 'y' ]]; then
            printf '%s, ' "${!indir+${index}}"
        fi
        (( index += 1 ))
    done
    printf '%b%s' '\b\b], '
done

printf '%b%s' '\b\b]'
} 
#-------------------------------------

#infile, seed, outdir
#Usage: handleStringInput "${var}" "${FUNCNAME}"
# ${1} is the name of the variable to set. ${2} should be the calling function's ${FUNCNAME} to provide proper backtrack, if omitted, the 
#The user may cancel their changes with a menu option. In this case, handleStringInput will output a newline. Ensure calling functions have a conditional to detect this
handleStringInput(){
#this technically works, but please just hardcode your seed value, as this is going to suck to use.

dialogKeysSpecial=( 'End' End 'Clear' Clear 'Cancel' Cancel 'Backspace' Backspace 'Space' Space '/' Slash '.' Period '-' Dash '_' Underscore)

dialogKeysLower=("${dialogKeysSpecial[@]}" 'SHIFT' UPPERCASE  a alpha  b bravo  c charlie  d delta  e echo  f foxtrot  g golf  h hotel  i india  j juliet  k kilo  l lima  m mike  n november  o oscar  p papa  q quebec  r romeo  s sierra  t tango  u uniform  v victor  w whiskey  x x-ray  y yankee  z zulu  1 one  2 two  3 three  4 four  5 five  6 six  7 seven  8 eight  9 niner  0 zero  )

dialogKeysUpper=("${dialogKeysSpecial[@]}" 'shift' lowercase  A Alpha  B Bravo  C Charlie  D Delta  E Echo  F Foxtrot  G Golf  H Hotel  I India  J Juliet  K Kilo  L Lima  M Mike  N November  O Oscar  P Papa  Q Quebec  R Romeo  S Sierra  T Tango  U Uniform  V Victor  W Whiskey  X X-ray  Y Yankee  Z Zulu  '!' "Exclaimation Point"  '@' "At Symbol"  '#' "Octothorpe"  '$' "Dollar Sign"  '%' "Percent Sign"  '^' Caret  '&' Ampersand  '*' Star  '(' "Open Paranthesis"  ')' "Close Paranthesis" )

dialogKeyboardBuffer="${!1}"

dialogKeyboardShiftStatus="UPPER"

dialogKeyboardUseArray=( "${dialogKeysUpper[@]}" )

local desc="${1}_name"
if [ ! "${desc}" == "_desc" ] ; then
local dec_title="${!desc}"
fi

while true; do

dialogKeyboardRadio=( dialog \
                    --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
                    --no-collapse \
                    --clear \
                    --no-cancel )

if [ "${dialogKeyboardShiftStatus}" == "UPPER" ]; then
        dialogKeyboardUseArray=("${dialogKeysUpper[@]}")
    else
        dialogKeyboardUseArray=("${dialogKeysLower[@]}")
fi

#FIXME this l1/r1 advice is specific to RG351P afaik, modify to use PortMaster's system detection at some point
dialogKeyboardChoice=$( "${dialogKeyboardRadio[@]}" --title "[ String Input${desc:+: ${dec_title}} ]" --menu "Your input:\n'${dialogKeyboardBuffer:-Select a key to fill...}'\nUse R1 to page down, L1 to page up." ${height} ${width} 99 "${dialogKeyboardUseArray[@]}" 2>&1 > /dev/tty0 ) || "${2}"
    
for key in "${dialogKeyboardChoice}"; do
        case "${key}" in
            End) 
                echo "${dialogKeyboardBuffer}" 
                return
            ;;
            #echo an escape character, calling function must have [ "${var}" == "$(echo -en '\x1B')" ] or similar to act upon this output
            Cancel) 
                echo -en '\x1B'
                return
            ;;
            Clear)
                dialogKeyboardBuffer=""
            ;;
            Space) dialogKeyboardBuffer="${dialogKeyboardBuffer} " ;;
            SHIFT) dialogKeyboardShiftStatus="UPPER" ;;
            shift) dialogKeyboardShiftStatus="lower" ;;
            Backspace) dialogKeyboardBuffer="${dialogKeyboardBuffer%?}" ;;
            *) dialogKeyboardBuffer="${dialogKeyboardBuffer}${key}";;
        esac
    done
done

}


#FIXME additionally, this code does not contain exception handling for if the preset file is not executable. it is assumed the roms directory is on a FAT-derivitive file system and the default file permissions allow execution. at some point perhaps fix this error.
seedStageLoadPreset(){
local name=$(sed -n '/^#NAME:/{s@^#NAME:@@;p}' "${1}" )
local desc=$(sed -n '/^#DESC:/{s@^#DESC:@@;p}' "${1}" )
local flags="$(source "${1}"; buildDisplayFlagset)"

#hardcoded
#local flags=$(sed -n '/^#FLAGS:/{s@^#FLAGS:@@;p}' "${1}" )

    dialog \
   	--backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--title "[ Load A Seed Preset ]" \
   	--no-collapse \
   	--clear \
    --cancel-label "Cancel" \
    --yesno "Name: ${name}\nDescription: ${desc}\nEnabled flags: ${flags}\n\nDo you want to set these flags?" ${height} ${width} 2>&1 > /dev/tty0 

case $? in
    0)
        source "${1}"
        
        dialog \
        --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
        --title "[ Load A Seed Preset ]" \
        --no-collapse \
        --clear \
        --no-cancel \
        --msgbox "Flag preset '${name}' applied. Seed flag values have been changed." ${height} ${width} 2>&1 > /dev/tty0 
        
        seedSettingsLoadPresetMenu
    ;;
    *)
        dialog \
        --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
        --title "[ Load A Seed Preset ]" \
        --no-collapse \
        --clear \
        --no-cancel \
        --msgbox "Flag preset '${name}' not applied. Seed flag values unchanged." ${height} ${width} 2>&1 > /dev/tty0 
        
        seedSettingsLoadPresetMenu
    ;;
esac
}

#load a preset
seedSettingsLoadPresetMenu(){
  while true; do
    seedSettingsLoadPresetSelection=(dialog \
   	--backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--title "[ Load A Seed Preset ]" \
   	--no-collapse \
   	--clear \
    --cancel-label "Cancel" \
    --menu "Select a preset:" $height $width 15)
    
    local presetFiles=()
    
    oldIFS="${IFS}"
    IFS='|' presetFiles=( $( ls "${dir_config}/seed_flags_preset_"* | tr '\n' '|') )
    IFS="${oldIFS}"
  
    local seedSettingsLoadPresetOptions=(  )
    
    
    #name and flagset
    local count=0
    for f in "${presetFiles[@]}"; do
        seedSettingsLoadPresetOptions[${count:-0}]="$(sed -n 's@^#NAME:@@p' "${f}")"
        seedSettingsLoadPresetOptions[((${count:-0}+1))]="$(source "${f}"; buildDisplayFlagset)"
        count=${count}+2
    done
        
    seedSettingsLoadPresetChoices=$("${seedSettingsLoadPresetSelection[@]}" "${seedSettingsLoadPresetOptions[@]##*/}" 2>&1 > /dev/tty0) || manageConfigMenu
    
       local file=$(grep -H "^#NAME:${seedSettingsLoadPresetChoices}" "${dir_config}/seed_flags_preset_"* | cut -d: -f1)
       
       seedStageLoadPreset "${file}" "${seedSettingsLoadPresetChoices}"
  done
}

#Usage: $0 VAR DIR|FILE
#presents 'ls' output in dialog's --menu form, writes choice to stdout
#capture input with var=$(handleFileBrowser "${VAR}" "${DIR}")
#some logic is included if the ${DIR} input is not a directory to choose the directory containing the file.
#DIR is an absolute path.
handleFileBrowser()
{

local displayname="${1}"
local dir="${2}"
local cancel="${2}"

#dir is not a directory, 
if [ ! -d "${dir}" ]; then

    #get the parent dir
    dir="${dir%/*}"

fi

#dir doesn't exist, go to root
if [ ! -e "${dir}" ]; then
    dir="/"
fi


#trim trailing slashes
[[ ( "${dir}" == */ ) && ( ! "${dir}" == "/" ) ]] && dir="${dir%/*}"



fileBrowserSelection=(dialog \
    --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--no-collapse \
   	--clear \
    --cancel-label "Cancel" \
   	--title "[ File Browser: ${displayname} ]" )

while true; do

    oldIFS="${IFS}"
    IFS='|' fileBrowserOptions=( '.' 'Current Dir' '..' '' $( ls -LAF "${dir}" | sed 's@$@\n@;s@/\n$@\nDIR@;s@\*\n$@\n@;s@=\n$@\nSOCKET@g;s@|\n$@\nPIPE@g;s/@\n$/\nSYMLINK/' | tr '\n' '|' ) )
    IFS="${oldIFS}"
                
    fileBrowserChoice=$("${fileBrowserSelection[@]}" --menu "${dir}" "${height}" "${width}" 15 "${fileBrowserOptions[@]}" 2>&1 > /dev/tty0)
    
    if [[ "$?" == 1 ]]; then
        echo "${cancel}"
        return
    fi
    
        case "${fileBrowserChoice}" in
            ..)
            dir="${dir%/*}"
            #handle root
            [ -z "${dir}" ] && dir='/'
            ;;
            .)
                echo "${dir}"
                return
            ;;
            *)
            #is directory
            if [ -d "${dir}/${fileBrowserChoice}" ]; then
                dir="$( echo "${dir}/${fileBrowserChoice}" | sed 's@/\{2,\}@/@g' )"
                [[ "${dir}" == */ ]] && dir="${dir%/*}"
                continue
            fi 
            #is not a directory
            echo "${dir}/${fileBrowserChoice}"
            return
            ;;
        esac

done
}

#infile name, infile dir, outdir
systemModifySettings()
{
systemModifySettingsSelection=(dialog \
    --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--no-collapse \
   	--clear \
    --cancel-label "Return" \
   	--title "[ Manage System Settings ]" \
    --menu "Pick an option." "${height}" "${width}" 99 )

while true; do

    oldIFS="${IFS}"
    IFS='|' systemModifySettingsOptions=( $(declare -p | grep -e '-.\s*sys_' | grep -v -e '_\(desc\|flag\|name\|default\)=' -e 'sys_choice=' | sed 's@declare -. @@;s@\([^=]\+\)=.*@$(printf "\\"%s\\"" "${\1_name}")\\|$(printf "\\"%s\\"" "${\1}")\\|@' | tr -d '\n' | sed 's@^@echo @' | bash )) 
    IFS="${oldIFS}"
    
    systemModifySettingsChoices=$("${systemModifySettingsSelection[@]}" "${systemModifySettingsOptions[@]/sys_/}" 2>&1 > /dev/tty0) || manageConfigMenu
    
    
    
    for choice in "${systemModifySettingsChoices}"; do
     
        
        #because dialog uses the tag of the item as its output, convert the *_name value back to sys_*
        local realvar="$(declare -p | grep "${choice}" | sed 's@declare -.\s*@@;s@=.*@@;s@_name@@')"
        local sys_choice_desc="${realvar}_desc"
        local sys_choice_name="${realvar}_name"
        
        case "${realvar/sys_/}" in
            infile|outdir|jetsdir)
                local pickfile="$(handleFileBrowser "${!sys_choice_name}" "${!realvar}" "${FUNCNAME}")"
                declare "${realvar}"="${pickfile}"
            ;;
            #assumed boolean
            *) 
            if [ "${!realvar}" == "y" ]; then
                dialog --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" --title "[ Boolean Option: ${choice} ]" --no-collapse --clear --cancel-label "Cancel" --yesno "Option ${choice} is currently ENABLED.\n\n${!sys_choice_desc}\n\nDo you want to DISABLE ${choice}?" $height $width 2>&1 > /dev/tty0
                case $? in 
                    0) declare "${realvar}"="n"
                    ;;
                esac
                else
                dialog --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" --title "[ Boolean Option: ${choice} ]" --no-collapse --clear --cancel-label "Cancel" --yesno "Option ${choice} is currently DISABLED.\n\n${!sys_choice_desc}\n\nDo you want to ENABLE ${choice}?" $height $width 2>&1 > /dev/tty0
                    case $? in 
                    0) declare "${realvar}"="y"
                    ;;
                esac
            fi 		
            ;;
        esac
    done
  done
}


#manageConfigMenu, pick between saving current settings, loading a preset, loading a previously-saved user config, and resetting to defaults
manageConfigMenu()
{
while true; do
  local manageConfigMenuOptions=( 1 "Save Current User Flagset" 2 "Reload User Flagset" 3 "Load Flag Preset" 4 "Modify System Variables" 5 "Save Current User System Settings" 6 "Reload User System Settings" 7 "Reset Default System Settings" )

  local manageConfigMenuSelection=(dialog \
    --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--no-collapse \
   	--clear \
    --cancel-label "Return" \
   	--title "[ Manage Configuration Files ]" \
    --menu "Pick an option. Settings are non-flag options, flags are options for the randomizer." ${height} ${width} 99 )

  manageConfigMenuChoices=$("${manageConfigMenuSelection[@]}" "${manageConfigMenuOptions[@]}" 2>&1 > /dev/tty0) || TopLevel
  
  for choice in "${manageConfigMenuChoices}"; do
      case $choice in
    1) seedSettingsSaveCurrentFlagsConfirm "${file_seed_config}" && seedSettingsSaveCurrentFlags > "${file_seed_config}" ;;
    2) seedSettingsReloadUserConfirm "${file_seed_config}" && seedSettingsReloadUserFlags "${file_seed_config}" ;;
    3) seedSettingsLoadPresetMenu ;;
    4) systemModifySettings ;;
    5) systemSettingsSaveCurrentOptionsConfirm "${file_config}" && systemSettingsSaveCurrentOptions > "${file_config}" ;;
    6) systemSettingsReloadUserOptionsConfirm "${file_config}" && systemSettingsReloadUserOptions "${file_config}" ;;
    7) systemSettingsResetToDefaultConfirm && systemSettingsResetToDefault ;;
      esac
    done
  done
}

seedSettingsFlagConfigMenu(){
  while true; do
  
    seedSettingsFlagConfigSelection=(dialog \
   	--backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--no-collapse \
   	--clear \
    --cancel-label "Return" \
   	--title "[ Set Seed Flags ]" \
    --menu "Current flagset: $( buildDisplayFlagset )" $height $width 15)
    
    #the fudge is this ifs doing staying set? okay then, explicitly declare the new ifs to go back to the old ifs.
    oldIFS="${IFS}"
    IFS='|' seedSettingsFlagConfigOptions=( $(declare -p | grep -e '-.\s*seed_' | grep -v -e '_\(desc\|flag\|name\)=' -e 'seed_choice=' | sed 's@declare -. @@;s@\([^=]\+\)=.*@$(printf "\\"%s\\"" "${\1_name}")\\|$(printf "\\"%s\\"" "${\1}")\\|@' | tr -d '\n' |sed 's@^@echo @' | bash ) '"Duplicate Character Matrix"' "$(for c in "${charMatrixList[@]}"; do printf '%s' "$(declare -p | grep "charMatrix${c}[0-6]"='"y"' | wc -l)"; done)") 
    IFS="${oldIFS}"

    seedSettingsFlagConfigChoices=$("${seedSettingsFlagConfigSelection[@]}" "${seedSettingsFlagConfigOptions[@]/seed_/}" 2>&1 > /dev/tty0) || TopLevel
    
    for choice in "${seedSettingsFlagConfigChoices}"; do
    
    if [[ "${choice}" == '"Duplicate Character Matrix"' ]]; then
        duplicateCharacterMatrixMainMenu
        continue
    fi
    
    
    #because dialog uses the tag of the item as its output, convert the *_name value back to seed_*
    local realvar="$(declare -p | grep "${choice}" | sed 's@declare -.\s*@@;s@=.*@@;s@_name@@')"
    local seed_choice_desc="${realvar}_desc"
    local seed_choice_name="${realvar}_name"
    
    case "${realvar/seed_/}" in

    seed_string|infile|outdir) 
    local cancelled=$(handleStringInput "${realvar}" "${FUNCNAME}")
        if [ "${cancelled}" == "$(echo -en '\x1B')" ]; then
                continue
            else
                declare "${realvar}"="${cancelled}"
        fi
        ;;
    difficulty|shop_prices)
    if [ "${realvar/seed_/}" == "difficulty" ]; then
                local multistate=( e "Easy" n "Normal" h "Hard" ) 
    else
                local multistate=( n "Normal" f "Free" m "Mostly Random" r "Fully Random" )
    fi
    
    local multistateDesc="${realvar}_desc"
    
    local multistateSelection=(dialog \
   	--backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--title "[ Multistate Option: ${choice} ]" \
   	--no-collapse \
   	--clear \
    --cancel-label "Cancel" \
    --menu "Flag ${choice} has $(( ${#multistate[@]} / 2 )) options. They are:\n$(echo "${!multistateDesc}")" $height $width 15)
    
    local multistateChoices=$( "${multistateSelection[@]}" "${multistate[@]}" 2>&1 > /dev/tty0) || seedSettingsFlagConfigMenu
        #both difficulty and shop_prices have standard flags as 'n'. user is able to exit out of dialog without setting a new option. use previous value in this case
        declare "${realvar}"="${multistateChoices:-${!realvar}}"
    ;;
    *) 
    if [ "${!realvar}" == "y" ]; then
        dialog --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" --title "[ Boolean Option: ${choice} ]" --no-collapse --clear --cancel-label "Cancel" --yesno "Flag ${choice} is currently ENABLED.\n\n${!seed_choice_desc}\n\nDo you want to DISABLE ${choice}?" $height $width 2>&1 > /dev/tty0
        case $? in 
            0) declare "${realvar}"="n"
            ;;
        esac
        else
        dialog --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" --title "[ Boolean Option: ${choice} ]" --no-collapse --clear --cancel-label "Cancel" --yesno "Flag ${choice} is currently DISABLED.\n\n${!seed_choice_desc}\n\nDo you want to ENABLE ${choice}?" $height $width 2>&1 > /dev/tty0
            case $? in 
            0) declare "${realvar}"="y"
            ;;
        esac
    fi 		
    ;;
    esac
    done
  done
}


#wrap output to width. if for some reason it would wrap to 0 or fewer, silently fail to wrap and return 0 to not impede operation

sedWrapToDialogWidth(){
local wrap="$((${width:-0} - 4))"

if [ "${wrap}" -le 0 ]; then
    wrap="0,"
fi

sed "s@.\{${wrap}\}@&\n@g"
}

#A big thank you to PortMaster for both inspiring and demonstrating this technique to get user input on RG351* devices.
thanksScreen()
{
dialog \
    --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--no-collapse \
   	--clear \
    --cancel-label "Return" \
    --title "[ About & Thanks ]" \
    --msgbox "Jets of Time v${ui_dec_curversion}\nOn-device generator of seeds for RG351* devices, no keyboard necessary.\nThanks to:\n\n   Jets of Time (https://github.com/Anskiy/jetsoftime/) for new enjoyment of one of the best video games yet created.\n\n   PortMaster (https://github.com/christianhaitian/arkos/wiki/PortMaster) for demonstrating this method of scripting for user input without a keyboard, without which this would not have been created." $height $width  2>&1 > /dev/tty0 
}
#

#first menu when loading script
TopLevel() {
  local topoptions=( 1 "Set Seed Flags" 2 "Generate A Seed" 3 "Save/Load Configuration" 4 "About" )

  while true; do
    topselection=(dialog \
   	--backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" \
   	--no-collapse \
   	--clear \
    --cancel-label "Exit Generator" \
    --title "[ Top Level Menu ]" \
    --menu "Choose an option." $height $width 15)
    
    topchoices=$("${topselection[@]}" "${topoptions[@]}" 2>&1 > /dev/tty0) || userExit

    for choice in $topchoices; do
      case $choice in
    1) seedSettingsFlagConfigMenu ;;
    2) generateSeedConfirmDialog && generateSeed | sedWrapToDialogWidth | dialog --backtitle "${ui_dec_backtitle} v${ui_dec_curversion}" --no-collapse --clear --title "[ Seed Generation ]" --programbox "Generating seed..." $height $width > /dev/tty0 ;;
    3) manageConfigMenu ;;
    4) thanksScreen ;;
      esac
    done
  done
}

initVars
ensureDirsExist
initSeedVars
importVars
ensureDirsExist #user config directories may not exist, ensure they exist again.
pushd "${dir_root}" > /dev/null

TopLevel