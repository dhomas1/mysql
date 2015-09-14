#!/usr/bin/env sh
#
# install script

prog_dir="$(dirname "$(realpath "${0}")")"
name="$(basename "${prog_dir}")"
data_dir="${prog_dir}/data"
tmp_dir="/tmp/DroboApps/${name}"
logfile="${tmp_dir}/install.log"

# boilerplate
if [ ! -d "${tmp_dir}" ]; then mkdir -p "${tmp_dir}"; fi
exec 3>&1 4>&2 1>> "${logfile}" 2>&1
echo "$(date +"%Y-%m-%d %H-%M-%S"):" "${0}" "${@}"
set -o errexit  # exit on uncaught error code
set -o nounset  # exit on unset variable
set -o xtrace   # enable script tracing

# copy default configuration files
find "${prog_dir}" -type f -name "*.default" -print | while read deffile; do
  basefile="$(dirname "${deffile}")/$(basename "${deffile}" .default)"
  if [ ! -f "${basefile}" ]; then
    cp -vf "${deffile}" "${basefile}"
  fi
done

# copy initial database
if [ ! -d "${data_dir}" ]; then
  mv -f "${data_dir}.initial" "${data_dir}"
else
  rm -fR "${data_dir}.initial"
fi

# generate server RSA key
if [ ! -f "${data_dir}/private_key.pem" ]; then
  "${prog_dir}/libexec/openssl" genrsa -out "${data_dir}/private_key.pem" 2048
  chmod 400 "${data_dir}/private_key.pem"
fi

if [ ! -f "${data_dir}/public_key.pem" ]; then
  "${prog_dir}/libexec/openssl" rsa -in "${data_dir}/private_key.pem" -pubout -out "${data_dir}/public_key.pem"
  chmod 444 "${data_dir}/public_key.pem"
fi

# generate root password
"${prog_dir}/scripts/mysql_gen_root_pass.sh"
