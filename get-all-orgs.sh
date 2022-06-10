#!/usr/bin/env bash

# set functions
timestamp() {
    date +"%Y%m%d%H%M%S"
}

debug() {
  if [[ ${DEBUG} == 1 ]]; then
    echo "$1"
  fi
}

PrintUsage()
{
  cat <<EOM
Usage: ${0} [options]

Options:
    -h, --help                    : Show script help
    -d, --debug                   : Enable Debug logging

Description:
Gets all organizations the authenticated user can see, and outputs to a CSV.

Example:
 ${0}

EOM
  exit 0
}

# set vars
HAS_NEXT_PAGE=1
EXPORT_FILE="all_orgs_$(timestamp).csv"
CURSOR=""
DEBUG=0

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

debug "Debug enabled: true";

debug "Is user authenticated?";
USER=$(gh api user);
# exit if no user is found (gh auth login needs to be performed)
if [ $? -ne 0 ]; then
    exit 1;
fi

# create file
touch ${EXPORT_FILE}

# while there are still orgs to get, loop through pages
debug "Getting all organizations...";
while [ ${HAS_NEXT_PAGE} -eq 1 ]; do

    if [ ! -z "${CURSOR}" ]; then
        ORG_CURSOR="-F cursor=${CURSOR}"
        debug "Attempting query with cursor ${CURSOR}"
    else
        ORG_CURSOR=""
        debug "No cursor defined. First query attempt."
    fi

    RESULT=$(gh api graphql ${ORG_CURSOR} -f query='
        query($cursor: String) {
            viewer {
                organizations(first: 100, after: $cursor) {
                    nodes {
                        login
                    }
                    pageInfo {
                        endCursor
                        hasNextPage
                    }
                }
            }
        }
    ');

    if [ $? -ne 0 ]; then
        echo "";
        echo "The graphql API endpoint responded with error code: $?";
        exit 1;
    fi

    debug "Query result: ${RESULT}";
    
    # append results to export file
    echo "${RESULT}" | jq -r '.data.viewer.organizations.nodes[].login' >> ${EXPORT_FILE};
    
    # stop loop if there's another page
    HAS_NEXT_PAGE_JSON=$(echo "${RESULT}" | jq -r '.data.viewer.organizations.pageInfo.hasNextPage')
    if [ "${HAS_NEXT_PAGE_JSON}" == "false" ]; then
        debug "No next page found. Setting flag.";
        HAS_NEXT_PAGE=0;
    else
        debug "Another page is available. Setting flag.";
    fi

    # adjust the cursor
    CURSOR=$(echo "${RESULT}" | jq -r '.data.viewer.organizations.pageInfo.endCursor');
    debug "Cursor found: ${CURSOR}";
done

echo "";
echo "Saved data to ${EXPORT_FILE}";
echo "";
echo "Recommended next command: ./get-all-users.sh -f ${EXPORT_FILE}"
