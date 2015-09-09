#!/bin/sh

set -o nounset
set -o errexit

prog_dir="$(dirname $(realpath "${0}"))/.."
data_dir="$(realpath "${prog_dir}/data")"
daemon="$(realpath "${prog_dir}/bin/mysql")"
name=

usage() {
cat << EOHELP

usage: $0 [options]

Return 0 if the given table exists.

OPTIONS:
   -h   Show this message
   -n   Name of the database

EOHELP
}

_mysql() {
  "${daemon}" --defaults-file="${data_dir}/.root.cnf" "$@" 2>&1
}

while getopts "hn:" OPTION; do
  case $OPTION in
    h) usage ; exit 1 ;;
    n) name=$OPTARG ;;
    :) echo "Option -$OPTARG requires an argument" >&2 ; usage ; exit 1 ;;
    ?) echo "Invalid option: -$OPTARG" >&2 ; usage ; exit 1 ;;
  esac
done

# check arguments
if [ -z "${name}" ]; then
  echo "Missing database name." >&2
  usage ; exit 1
fi

# table exists
#sql="SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${name}';"
sql="SHOW DATABASES LIKE '${name}';"
res="$(_mysql -e "${sql}")"
if [ -z "${res}" ]; then
  exit 1
fi
exit 0
