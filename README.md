# Get All Organization Users Using GitHub CLI
Quick &amp; dirty bash script that utilizes GitHub CLI to get users from organizations.

## About
When migrating users from GitHub Enterprise Server (GHES) or GitHub Enterprise Cloud (GHEC), it can often be a challenge to get a user list from multiple organizations. This script is written in bash (for compatibility) and uses the GitHub API Graphql endpoints via the GitHub CLI (`gh api graphql`) to paginate users (team members) from a list of organizations.

Included also is the ability to generate a list of organizations that the authenticated user has access to.

## Prerequisites
- **Terminal** capable of executing bash scripts
- **GitHub CLI** (https://cli.github.com/manual/installation) - authenticated
- **jq** (https://stedolan.github.io/jq)

## Compatibility Notes
- **GHES**: The graphql endpoints did not exist on GHES prior to version 2.20, so this will not work on servers running 2.19 or older.

## Executing

1. Make sure all prerequisites are available, installed, & configured.
2. If you haven't already, execute
    ```
    gh auth login
    ```
3. Execute the organization generation script: `./get-all-orgs.sh`
    ```
    ./get-all-orgs.sh
    ```
   1. This step is optional. You can simply craft your own line-separated file instead using the following format:
        ```
        org1
        org2
        ```
    <br>
4. Execute the user generation script (replace `<file-path>` with the path to your list of organizations):
    ```
    ./get-all-users.sh -f <file-path>
    ```
5. View the generated `.csv` file (the script will output the file name). The users will be listed by login and email address.

## Caveats
- Users who mark their email address as "private" will have no email address show up.