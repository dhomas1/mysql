#!/bin/sh

set -o nounset
set -o errexit

prog_dir="$(dirname $(realpath "${0}"))/.."
data_dir="$(realpath "${prog_dir}/data")"
daemon="$(realpath "${prog_dir}/bin/mysql")"
name=
user=
pass=

usage() {
cat << EOHELP

usage: $0 [options]

Change the password of a user.

OPTIONS:
   -h   Show this message
   -n   Name of the database
   -u   User account with all rights to the new database
   -p   New password for the user account

EOHELP
}

_mysql() {
  "${daemon}" --defaults-file="${data_dir}/.root.cnf" "$@" 2>&1
}

while getopts "hn:u:p:" OPTION; do
  case $OPTION in
    h) usage ; exit 1 ;;
    n) name=$OPTARG ;;
    u) user=$OPTARG ;;
    p) pass=$OPTARG ;;
    :) echo "Option -$OPTARG requires an argument" >&2 ; usage ; exit 1 ;;
    ?) echo "Invalid option: -$OPTARG" >&2 ; usage ; exit 1 ;;
  esac
done

# check arguments
if [ -z "${name}" ]; then
  echo "Missing database name." >&2
  usage ; exit 1
fi
if [ -z "${user}" ]; then
  echo "Missing user name." >&2
  usage ; exit 1
fi
if [ -z "${pass}" ]; then
  echo "Missing password." >&2
  usage ; exit 1
fi

# update password
sql="USE '${name}'; SET PASSWORD FOR '${user}'@localhost = PASSWORD('${pass}'); FLUSH PRIVILEGES;"
_mysql -e "${sql}"
