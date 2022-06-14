#!/usr/bin/env bash

PrintUsage()
{
  cat <<EOM
Usage: ${0} <file> [options]

Options:
    -h, --help                    : Show script help
    -d, --debug                   : Enable Debug logging
    -f, --file                    : The import file of line-separated repos to delete

Description:
Deletes all repositories in the import file (-f).

Example:
 ${0}

EOM
  exit 0
}

debug() {
  if [[ ${DEBUG} == 1 ]]; then
    echo "$1"
  fi
}


# set vars
IMPORT_FILE=""

# Read paramters passed
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -h|--help)
      PrintUsage;
      ;;
    -d|--debug)
      DEBUG=1
      shift
      ;;
    -f|--file)
      IMPORT_FILE=$2
      shift
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
  PARAMS="$PARAMS $1"
  shift
  ;;
  esac
done

debug "Testing GitHub CLI authentication...";
USER=$(gh api user);
# exit if no user is found (gh auth login needs to be performed)
if [ $? -ne 0 ]; then
    exit 1;
fi

# make sure we have an import file
if [ -z "${IMPORT_FILE}" ]; then
    echo "No import file was provided."
    exit 1;
elif [ ! -f "${IMPORT_FILE}" ]; then
    echo "Import file provided not found."
    exit 1;
fi

# make sure they want to proceed
read -p "Are you sure you want to delete all the repositories listed in the import file? " -n 1 -r
echo    # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then

    while read REPO; do

        debug "Attempting to delete repository ${REPO}..."
        # attempt to delete repo
        gh repo delete "${REPO}" --confirm

        if [ $? -ne 0 ]; then
            echo "";
            echo "The graphql API endpoint responded with error code: $?";
            exit 1;
        fi

    done < ${IMPORT_FILE}
fi