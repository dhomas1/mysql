#!/bin/sh

set -o nounset
set -o errexit

prog_dir="$(dirname $(realpath "${0}"))/.."
data_dir="$(realpath "${prog_dir}/data")"

rootpass="$("${prog_dir}/libexec/openssl" rand -hex 6)"
if [ -z "${rootpass}" ]; then
  echo "Root password generation failed." >&2
  exit 1
fi

cat > "${data_dir}/.root.cnf" << EOF
[client]
user=root
password=${rootpass}
EOF
chmod 600 "${data_dir}/.root.cnf"

cat > "${data_dir}/.root.sql" << EOF
UPDATE mysql.user SET Password=PASSWORD('${rootpass}'), password_expired='N' WHERE User='root' and plugin in ('', 'mysql_native_password');
FLUSH PRIVILEGES;
EOF
chmod 600 "${data_dir}/.root.sql"
