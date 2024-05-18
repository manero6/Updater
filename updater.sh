#! /bin/bash

# This hack is needed to always get the correct value for COLUMNS, or 'tput cols'.
# This is useful when executing the script in new maximized terminal windows/tabs ('gnome-terminal' for example).
sleep 0.1

declare STYLISH
   TOP_CHAR=┬
MIDDLE_CHAR=│
BOTTOM_CHAR=┴
TPUT_COLUMNS=$(tput cols)
#todo LR_OFFSET=3

# Check that 1 charachter is stored in the followng variables, else exit the script
for CHAR in $TOP_CHAR $MIDDLE_CHAR $BOTTOM_CHAR
do
  if ! [ ${#CHAR} -eq 1 ]
  then
    echo "TOP_CHAR, MIDDLE_CHAR and BOTTOM_CHAR variables must contain only 1 character!"
    echo "Please re-check your environment variables or the configuration file."
    exit 1
  fi
done

if which lolcat &>/dev/null
then
  STYLISH="| lolcat"
fi

usage() {
  echo
  echo "Usage:"
  echo
  echo "  help --help -h          Print this help "
  echo "  list-commands           Print what command(s) each updater will run"
  echo "  all                     Execute all updaters listed below"
  echo "  dnf                     Update dnf packages with distrosync"
  echo "  dnf-autoremove          Update dnf packages with distrosync and remove unused packages"
  echo "  flatpak                 Update flatpak packages"
  echo "  flatpak-autoremove      Update flatpak packages and remove unused packages"
  echo "  tldr                    Update tldr cache"
  echo
}

generate_title_top_bottom() {
  local CHAR=$1
  eval "for i in {1..$TPUT_COLUMNS}
        do
          echo -n "$CHAR"
        done"
}

generate_title_middle() {
  local CHAR=$1
  local TITLE=$2
  local TITLE_LENGTH="${#TITLE}"

  eval "for char in {1..$(( ($TPUT_COLUMNS-$TITLE_LENGTH)/2 ))}
        do
          echo -n "$CHAR"
        done"
}

print_title() {
  local TITLE=$1
  local TOP=$(generate_title_top_bottom $TOP_CHAR)
  # Double quoting TITLE, else the string will be cut at the first whitespace
  local MIDDLE=$(generate_title_middle $MIDDLE_CHAR "$TITLE")
  local BOTTOM=$(generate_title_top_bottom $BOTTOM_CHAR)

  local FINAL_TITLE="$MIDDLE $TITLE $MIDDLE"
  # Cheating a little bit right here... not always in the center but it is not noticeable unless one reads this comment MUHWAHAHA
  FINAL_TITLE=${FINAL_TITLE::$TPUT_COLUMNS}

  echo $TOP
  echo $FINAL_TITLE
  echo $BOTTOM
}

# old stuff
#print_title() {
#  # Dynamically insert '-' based on the total numbers of characters that $1 has
#  local STRING=$1
#  local HYPHEN=$(eval "for char in {1..${#1}}
#                       do
#                         echo -n -
#                       done"
#                )
#  echo "-----------$HYPHEN--"
#  echo "| Updating $STRING |"
#  echo "-----------$HYPHEN--"
#}


print_title_stylish() {
  # Escaping double quotes is needed, else 'eval' will not preserve whitespaces and do nasty stuff.
  eval print_title \"$1\" $STYLISH
}

get_function_command() {
  declare -f $1 | tail -2 | head -1
}

print_function_command() {
  if which highlight &>/dev/null
  then
    get_function_command $1 | highlight --syntax bash --out-format truecolor
  else
    get_function_command $1
  fi
}

list_commands() {
  echo "The actual command(s) that each updater will run:"
  echo
  echo "dnf:"
  print_function_command dnf_up
  echo
  echo "dnf-autoremove:"
  print_function_command dnf_up_rm
  echo
  echo "flatpak:"
  print_function_command flatpak_up
  echo
  echo "flatpak-autoremove:"
  print_function_command flatpak_up_rm
  echo
  echo "tldr:"
  print_function_command tldr_up
  echo
}

all_up() {
  print_title_stylish "all"
  echo "The following updaters will be executed:"
  echo "  1) dnf-autoremove"
  echo "  2) flatpak-autoremove"
  echo "  3) tldr"
  dnf_up_rm
  flatpak_up_rm
  tldr_up
}

dnf_up() {
  print_title_stylish "dnf"
  # Always refresh cache
  sudo dnf distro-sync --refresh
}

dnf_up_rm() {
  print_title_stylish "dnf & autoremove"
  # Always refresh cache and remove unused packages
  sudo bash -c "dnf distro-sync --refresh && dnf autoremove"
}

flatpak_up() {
  print_title_stylish "flatpak"
  flatpak update
}

flatpak_up_rm() {
  print_title_stylish "flatpak & autoremove"
  # Uninstall unused packages first
  flatpak uninstall --unused && flatpak update
}

tldr_up() {
  print_title_stylish "tldr"
  tldr -u
}

options_all() {
  # If any of the given options is 'all', then continue, else return error
  # This way 'all' is prioritized and every other option is skipped
  for option in $@
  do
    if [ $option = "all" ]
    then
      return 0
    fi
  done
  return 1
}

main() {
  if [ $# -lt 1 ]
  then
    # Print help when no option is passed
    echo "At least one option must be given..."
    usage
    exit 1
  # Execute 'all' if it is passed as option
  elif options_all "$@"
  then
    # In case 'all' is not the only option, print a message
    if [ $# -gt 1 ]
    then
      echo "When running 'all' every other option can be omitted."
    fi  
    all_up
  else
    while [ $# -gt 0 ]
    do
      case $1 in
        help|-h|--help)
          usage
	  exit 0
	  ;;
        list-commands)
	  list_commands
	  exit 0
	  ;;
        dnf)
          dnf_up
	  shift
	  ;;
        dnf-autoremove)
          dnf_up_rm
	  shift
	  ;;
        flatpak)
          flatpak_up
	  shift
	  ;;
        flatpak-autoremove)
          flatpak_up_rm
	  shift
	  ;;
        tldr)
          tldr_up
	  shift
	  ;;
	*)
          echo "Unknown option(s) '$@'"
          usage
	  exit 1
	  ;;
      esac
    done
  fi
}

main "$@"
