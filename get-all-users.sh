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
Usage: ${0} <file> [options]

Options:
    -h, --help                    : Show script help
    -d, --debug                   : Enable Debug logging
    -f, --file                    : The import file of line-separated organizations to scan

Description:
Gets all users for each organization in the import file (-f) and outputs to a CSV.

Example:
 ${0}

EOM
  exit 0
}

# set vars
DEBUG=0
HAS_NEXT_PAGE=1
EXPORT_FILE="all_users_$(timestamp).csv"
IMPORT_FILE=""
CURSOR=""

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

debug "Debug enabled: true";

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

# create file
touch ${EXPORT_FILE}

while read ORG; do

    echo "Getting users for ${ORG}...";

    HAS_NEXT_PAGE=1;
    CURSOR="";

    while [ ${HAS_NEXT_PAGE} -eq 1 ]; do

        if [ ! -z "${CURSOR}" ]; then
            USER_CURSOR="-F cursor=${CURSOR}"
            debug "Attempting query with cursor ${CURSOR}"
        else
            USER_CURSOR=""
            debug "No cursor defined. First query attempt."
        fi

        RESULT=$(gh api graphql -F organization=${ORG} ${USER_CURSOR} -f query='
            query (
                $cursor: String
                $organization: String!
            ) {
            organization(login: $organization) {
                    teams(first: 10, after: $cursor) {
                        nodes {
                            name
                            organization {
                                name
                            }
                            members {
                                edges {
                                    node {
                                        login
                                        email
                                    }
                                    role
                                }
                            }
                        }
                        pageInfo {
                            endCursor
                            hasNextPage
                        }
                    }
                }
            }
        ');

        # exit if fail to get back response
        if [ $? -ne 0 ]; then
            echo "";
            echo "The graphql API endpoint responded with error code: $?";
            exit 1;
        fi

        debug "Query result: ${RESULT}";

        # get each uer detail
        echo "${RESULT}" | jq -r '.data.organization.teams.nodes[].members.edges[].node | if .email == "" then .login + ",<unknown>" else .login + "," + .email end' \
            >> ${EXPORT_FILE};

        # stop loop if there's another page
        HAS_NEXT_PAGE_JSON=$(echo "${RESULT}" | jq -r '.data.organization.teams.pageInfo.hasNextPage')
        if [ "${HAS_NEXT_PAGE_JSON}" == "false" ]; then
            debug "No next page found. Setting flag.";
            HAS_NEXT_PAGE=0
        else
            debug "Another page is available. Setting flag.";
        fi

        # adjust the cursor
        CURSOR=$(echo "${RESULT}" | jq -r '.data.organization.teams.pageInfo.endCursor');
        debug "Cursor found: ${CURSOR}";

    done
done < ${IMPORT_FILE}

echo "";
echo "Saved data to ${EXPORT_FILE}";
echo "";
echo "Recommended next command: cat ${EXPORT_FILE}"