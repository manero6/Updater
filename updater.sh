#! /bin/bash

usage() {
  echo
  echo "Usage:"
  echo
  echo "  help --help -h        Print this help "
  echo "  list-commands         Print what command(s) each updater will run"
  echo "  all                   Execute all updaters listed below"
  echo "  dnf                   Update dnf packages with distrosync"
  echo "  flatpak               Update flatpak packages and remove unused packages"
  echo "  tldr                  Update tldr cache"
  echo
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
  echo "flatpak:"
  print_function_command flatpak_up
  echo
  echo "tldr:"
  print_function_command tldr_up
  echo
}

all_up() {
  echo "----------------"
  echo "| Updating all |"
  echo "----------------"
  echo " The following updater will be executed:"
  echo "   1) dnf"
  echo "   2) flatpak"
  echo "   3) tldr"
  dnf_up
  flatpak_up
  tldr_up
}

dnf_up() {
  echo "----------------"
  echo "| Updating dnf |"
  echo "----------------"
  # Always refresh cache
  sudo dnf distrosync --refresh
}

flatpak_up() {
  echo "--------------------"
  echo "| Updating flatpak |"
  echo "--------------------"
  # Uninstall unused packages first
  flatpak uninstall --unused && flatpak update
}

tldr_up() {
  echo "-----------------"
  echo "| Updating tldr |"
  echo "-----------------"
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
  # Execute 'all' if it was passed as option
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
        flatpak)
          flatpak_up
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
      esac
    done
  fi
}

main "$@"
