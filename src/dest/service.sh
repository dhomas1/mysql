#!/usr/bin/env sh
#
# MySQL service

# import DroboApps framework functions
. /etc/service.subr

framework_version="2.1"
name="mysql"
version="5.6.25"
description="SQL Database Server"
depends=""
webui=":8033/"

prog_dir="$(dirname "$(realpath "${0}")")"
daemon="${prog_dir}/bin/mysqld"
data_dir="${prog_dir}/data"
tmp_dir="/tmp/DroboApps/${name}"
pidfile="${tmp_dir}/pid.txt"
logfile="${tmp_dir}/log.txt"
statusfile="${tmp_dir}/status.txt"
errorfile="${tmp_dir}/error.txt"

webserver="${prog_dir}/libexec/web_server"
confweb="${prog_dir}/etc/web_server.conf"
pidweb="/tmp/DroboApps/${name}/web_server.pid"

# backwards compatibility
if [ -z "${FRAMEWORK_VERSION:-}" ]; then
  framework_version="2.0"
  . "${prog_dir}/libexec/service.subr"
fi

_create_user() {
  if ! id mysql; then
    adduser -S -H -h "${data_dir}" -D -s /bin/false -G nobody -u 40 mysql
  fi
  touch "${pidfile}"
  chmod 664 "${logfile}"
  chown -R mysql "${pidfile}" "${logfile}" "${data_dir}" "${prog_dir}/tmp"
}

start() {
  local rootpass
  _create_user
  mkdir -p "${tmp_dir}/sessions"
  setsid "${daemon}" --user=mysql --basedir="${prog_dir}" --datadir="${data_dir}" --pid-file="${pidfile}" --log-error="${logfile}" --init-file="${data_dir}/.root.sql" &
  if ! is_running "${pidweb}" "${webserver}"; then
    "${webserver}" "${confweb}" & echo $! > "${pidweb}"
  fi
  rootpass="$(awk -F= '$1 == "password" {print $2}' "${data_dir}/.root.cnf")"
  echo "Application is running. Root password is ${rootpass}" > "${statusfile}"
  chmod 600 "${statusfile}"
}

stop() {
  rm -f "${statusfile}"
  /sbin/start-stop-daemon -K -x "${webserver}" -p "${pidweb}" -v -o
  /sbin/start-stop-daemon -K -x "${daemon}" -p "${pidfile}" -v
}

force_stop() {
  rm -f "${statusfile}"
  /sbin/start-stop-daemon -K -s 9 -x "${webserver}" -p "${pidweb}" -v -o
  /sbin/start-stop-daemon -K -s 9 -x "${daemon}" -p "${pidfile}" -v
}

# boilerplate
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
STDOUT=">&3"
STDERR=">&4"
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o pipefail # propagate last error code on pipe
set -o xtrace   # enable script tracing

main "${@}"
