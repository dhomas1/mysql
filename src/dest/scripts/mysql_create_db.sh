#!/bin/sh

set -o nounset
set -o errexit

prog_dir="$(dirname $(realpath "${0}"))/.."
data_dir="$(realpath "${prog_dir}/data")"
daemon="$(realpath "${prog_dir}/bin/mysql")"
name=
user=
pass=
force=0
backup=0
folder=

usage() {
cat << EOHELP

usage: $0 [options]

Create a new database.

OPTIONS:
   -h   Show this message
   -n   Name of the database
   -u   User account with all rights to the new database
   -p   Password for the user account
   -f   Force the creation (remove first if the database exists)
   -b   Folder to place the database backup

EOHELP
}

_mysql() {
  "${daemon}" --defaults-file="${data_dir}/.root.cnf" "$@" 2>&1
}

while getopts “hn:u:p:fb:” OPTION; do
  case $OPTION in
    h) usage ; exit 1 ;;
    n) name=$OPTARG ;;
    u) user=$OPTARG ;;
    p) pass=$OPTARG ;;
    f) force=1 ;;
    b) folder=$OPTARG ; backup=1 ;;
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
if [ ${backup} -eq 1 -a -z "${folder}" ]; then
  echo "Invalid backup folder: ${folder}" >&2
  usage ; exit 1
fi

# backup database
if [ ${backup} -eq 1 ]; then
  if ! (_mysql -e "USE '${name}';" | grep -q "ERROR 1049"); then
    filename="${folder}/${name}-$(date +%F_%H-%M-%S).sql"
    if ! "${prog_dir}/bin/mysqldump" --defaults-file="${data_dir}/.root.cnf" "${name}" 1> "${filename}"; then
      echo "Backup of database ${name} failed." >&2
      exit 3
    fi
  fi
fi

# create database
sql="CREATE DATABASE '${name}' CHARACTER SET utf8 COLLATE utf8_general_ci; USE '${name}'; GRANT ALL PRIVILEGES ON * TO '${user}'@localhost IDENTIFIED BY '${pass}'; FLUSH PRIVILEGES;"
if [ ${force} -eq 1 ]; then
  sql="DROP DATABASE IF EXISTS '${name}'; ${sql}"
fi
_mysql -e "${sql}"
