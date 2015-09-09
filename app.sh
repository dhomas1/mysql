### ATOMIC ###
_build_atomic() {
# source: http://vincesoft.blogspot.com.br/2012/04/how-to-solve-undefined-reference-to.html
# The GCC toolchain for Drobo does not support atomic builtins.
# This is a workaround.
# The GCC first release to include linux-atomic.c is 4.7.0.
local FOLDER="linux-atomic"
local FILE="${FOLDER}.c"
local COMMIT="93c5ebd73a4d1626d25203081d079cdd68222fcc"
local URL="https://gcc.gnu.org/git/?p=gcc.git;a=blob_plain;f=libgcc/config/arm/${FILE};hb=${COMMIT}"

_download_file "${FILE}" "${URL}"
mkdir -p "target/${FOLDER}"
cp -vf "download/${FILE}" "target/${FOLDER}/"
pushd "target/${FOLDER}"
libtool --tag=CC --mode=compile "${CC}" ${CFLAGS} ${CPPFLAGS} -MT linux-atomic.lo -MD -MP -MF ${FOLDER}.Tpo -c -o ${FOLDER}.lo ${FILE}
libtool --tag=CC --mode=link "${CC}" ${CFLAGS} ${LDFLAGS} -o lib${FOLDER}.la ${FOLDER}.lo
mkdir -p "${DEPS}/lib"
cp -vf ".libs/lib${FOLDER}.a" ".libs/lib${FOLDER}.la" "${DEPS}/lib/"
popd
}

### ATOMIC64 ###
_build_atomic64() {
# source: http://vincesoft.blogspot.com.br/2012/04/how-to-solve-undefined-reference-to.html
# The GCC toolchain for Drobo does not support atomic builtins.
# This is a workaround.
# The GCC first release to include linux-atomic-64bit.c is 4.7.0.
local FOLDER="linux-atomic-64bit"
local FILE="${FOLDER}.c"
local COMMIT="93c5ebd73a4d1626d25203081d079cdd68222fcc"
local URL="https://gcc.gnu.org/git/?p=gcc.git;a=blob_plain;f=libgcc/config/arm/${FILE};hb=${COMMIT}"

_download_file "${FILE}" "${URL}"
mkdir -p "target/${FOLDER}"
cp -vf "download/${FILE}" "target/${FOLDER}/"
pushd "target/${FOLDER}"
libtool --tag=CC --mode=compile "${CC}" ${CFLAGS} ${CPPFLAGS} -MT linux-atomic.lo -MD -MP -MF ${FOLDER}.Tpo -c -o ${FOLDER}.lo ${FILE}
libtool --tag=CC --mode=link "${CC}" ${CFLAGS} ${LDFLAGS} -o lib${FOLDER}.la ${FOLDER}.lo
mkdir -p "${DEPS}/lib"
cp -vf ".libs/lib${FOLDER}.a" ".libs/lib${FOLDER}.la" "${DEPS}/lib/"
popd
}

### ZLIB ###
_build_zlib() {
local VERSION="1.2.8"
local FOLDER="zlib-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://zlib.net/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --prefix="${DEPS}" --libdir="${DEST}/lib" --shared
make
make install
rm -vf "${DEST}/lib/libz.a"
popd
}

### OPENSSL ###
_build_openssl() {
local VERSION="1.0.2d"
local FOLDER="openssl-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://mirror.switch.ch/ftp/mirror/openssl/source/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
cp -vf "src/${FOLDER}-parallel-build.patch" "target/${FOLDER}/"
pushd "target/${FOLDER}"
patch -p1 -i "${FOLDER}-parallel-build.patch"
./Configure --prefix="${DEPS}" --openssldir="${DEST}/etc/ssl" \
  zlib-dynamic --with-zlib-include="${DEPS}/include" --with-zlib-lib="${DEPS}/lib" \
  shared threads linux-armv4 -DL_ENDIAN ${CFLAGS} ${LDFLAGS} \
  -Wa,--noexecstack -Wl,-z,noexecstack
sed -i -e "s/-O3//g" Makefile
make
make install_sw
mkdir -p "${DEST}/libexec"
cp -vfa "${DEPS}/bin/openssl" "${DEST}/libexec/"
cp -vfa "${DEPS}/lib/libssl.so"* "${DEST}/lib/"
cp -vfa "${DEPS}/lib/libcrypto.so"* "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/engines" "${DEST}/lib/"
cp -vfaR "${DEPS}/lib/pkgconfig" "${DEST}/lib/"
rm -vf "${DEPS}/lib/libcrypto.a" "${DEPS}/lib/libssl.a"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libcrypto.pc"
sed -e "s|^libdir=.*|libdir=${DEST}/lib|g" -i "${DEST}/lib/pkgconfig/libssl.pc"
popd
}

### NCURSES ###
_build_ncurses() {
local VERSION="5.9"
local FOLDER="ncurses-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://ftp.gnu.org/gnu/ncurses/${FILE}"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"
pushd "target/${FOLDER}"
./configure --host="${HOST}" --prefix="${DEPS}" --libdir="${DEST}/lib" --datadir="${DEST}/share" --with-shared --enable-rpath
make
make install
rm -vf "${DEST}/lib/libform.a" "${DEST}/lib/libform_g.a" \
       "${DEST}/lib/libmenu.a" "${DEST}/lib/libmenu_g.a" \
       "${DEST}/lib/libncurses++.a" "${DEST}/lib/libncurses.a" "${DEST}/lib/libncurses_g.a" \
       "${DEST}/lib/libpanel.a" "${DEST}/lib/libpanel_g.a"
popd
}

### MYSQL ###
_build_mysql() {
# sudo apt-get install cmake ccmake g++ libncurses5-dev
local VERSION="5.6.26"
local FOLDER="mysql-${VERSION}"
local FILE="${FOLDER}.tar.gz"
local URL="http://cdn.mysql.com/Downloads/MySQL-5.6/${FILE}"
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"
export FOLDER_LOCAL="${PWD}/target/${FOLDER}-local"

_download_tgz "${FILE}" "${URL}" "${FOLDER}"

# native compilation of comp_err and comp_sql
if [[ ! -d "${FOLDER_LOCAL}" ]]; then
  cp -faR "target/${FOLDER}" "${FOLDER_LOCAL}"
fi
if [[ ! -f "${FOLDER_LOCAL}/extra/comp_err"   ]] || \
   [[ ! -f "${FOLDER_LOCAL}/scripts/comp_sql" ]]; then
  ( . uncrosscompile.sh
  pushd "${FOLDER_LOCAL}"
  cmake .
  make comp_err comp_sql )
fi

pushd "target/${FOLDER}"
cat > "cmake_toolchain_file.$ARCH" << EOF
SET(CMAKE_SYSTEM_NAME Linux)
SET(CMAKE_SYSTEM_PROCESSOR ${ARCH})
SET(CMAKE_C_COMPILER ${CC})
SET(CMAKE_CXX_COMPILER ${CXX})
SET(CMAKE_AR ${AR})
SET(CMAKE_RANLIB ${RANLIB})
SET(CMAKE_STRIP ${STRIP})
SET(CMAKE_CROSSCOMPILING TRUE)
SET(STACK_DIRECTION 1)
SET(CMAKE_FIND_ROOT_PATH ${TOOLCHAIN}/${HOST}/libc)
SET(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
SET(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
SET(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
SET(CMAKE_SKIP_BUILD_RPATH  FALSE)
SET(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
SET(CMAKE_INSTALL_RPATH "${DEST}/lib")
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
EOF

# Use existing zlib
ln -vfs libz.so $DEST/lib/libzlib.so
mv -v zlib/CMakeLists.txt{,.orig}
touch zlib/CMakeLists.txt

# Fix regex to find openssl 1.0.2 version
sed -e "s/\^#define/^#[\t ]*define/g" -e "s/\+0x/*0x/g" \
    -i cmake/ssl.cmake
# Add linking to linux-atomic and linux-atomic-64bit
sed -e "325iTARGET_LINK_LIBRARIES(mysqld linux-atomic linux-atomic-64bit)" \
    -i sql/CMakeLists.txt
sed -e "30iTARGET_LINK_LIBRARIES(mysql_embedded linux-atomic linux-atomic-64bit)" \
    -e "49iTARGET_LINK_LIBRARIES(mysqltest_embedded linux-atomic linux-atomic-64bit)" \
    -e "74i\  TARGET_LINK_LIBRARIES(mysql_client_test_embedded linux-atomic linux-atomic-64bit)" \
    -i libmysqld/examples/CMakeLists.txt

LDFLAGS="${LDFLAGS:-} -L${DEPS}/lib" \
  cmake . -DCMAKE_TOOLCHAIN_FILE="./cmake_toolchain_file.${ARCH}" \
  -DCMAKE_AR="${AR}" \
  -DCMAKE_STRIP="${STRIP}" \
  -DCMAKE_INSTALL_PREFIX="${DEST}" \
  -DMYSQL_DATADIR="${DEST}/data" \
  -DTMPDIR="${DEST}/tmp" \
  -DDEFAULT_CHARSET=utf8 \
  -DDEFAULT_COLLATION=utf8_general_ci \
  -DWITH_ZLIB=system -DZLIB_INCLUDE_DIR="${DEPS}/include" \
  -DWITH_SSL=system -DOPENSSL_ROOT_DIR="${DEST}" -DOPENSSL_INCLUDE_DIR="${DEPS}/include" -DOPENSSL_LIBRARY="${DEST}/lib/libssl.so" -DCRYPTO_LIBRARY="${DEST}/lib/libcrypto.so" \
  -DCURSES_LIBRARY="${DEST}/lib/libncurses.so" -DCURSES_INCLUDE_PATH="${DEPS}/include" \
  -DCMAKE_C_FLAGS="${CFLAGS} -I${DEPS}/include/ncurses" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS} -I${DEPS}/include/ncurses -Wno-psabi" \
  -DENABLED_PROFILING=OFF \
  -DENABLE_DEBUG_SYNC=OFF \
  -DWITH_UNIT_TESTS=OFF \
  -DWITH_PIC=ON \
  -DHAVE_LLVM_LIBCPP_EXITCODE=1 \
  -DHAVE_GCC_ATOMIC_BUILTINS=ON

cp "${FOLDER_LOCAL}/extra/comp_err" "extra/"
cp "${FOLDER_LOCAL}/scripts/comp_sql" "scripts/"
PATH=".:${PATH}" make -j1
make install
rm -vfR "${DEST}/mysql-test" "${DEST}/sql-bench"
rm -vf "${DEST}/bin/mysql_client_test_embedded" \
       "${DEST}/bin/mysqltest_embedded" \
       "${DEST}/bin/mysql_client_test" \
       "${DEST}/bin/mysqltest" \
       "${DEST}/lib/libmysqlclient.a" \
       "${DEST}/lib/libmysqlclient_r.a" \
       "${DEST}/lib/libmysqld.a" \
       "${DEST}/lib/libmysqlservices.a"
mkdir -p -m 775 "${DEST}/tmp"
popd
}

### MYWEBSQL ###
_build_mywebsql() {
local VERSION="3.6"
local FOLDER="mywebsql"
local FILE="${FOLDER}-${VERSION}.zip"
local URL="http://sourceforge.net/projects/mywebsql/files/stable/${FILE}"

_download_zip "${FILE}" "${URL}" "${FOLDER}"
mkdir -p "${DEST}/app"
cp -vfaR "target/${FOLDER}/"* "${DEST}/app/"
rm -vf "${DEST}/app/install.php"
}

### CERTIFICATES ###
_build_certificates() {
# update CA certificates on a Debian/Ubuntu machine:
#sudo update-ca-certificates
cp -vf /etc/ssl/certs/ca-certificates.crt "${DEST}/etc/ssl/certs/"
ln -vfs certs/ca-certificates.crt "${DEST}/etc/ssl/cert.pem"
}

### SQL BOOTSTRAP ###
_build_sql_bootstrap() {
export QEMU_LD_PREFIX="${TOOLCHAIN}/${HOST}/libc"

rm -vfr "${DEST}/data"
mkdir -p "${DEST}/data"

# taskset is needed due to bugs in qemu-user-static
# see: https://bugs.launchpad.net/ubuntu/+source/qemu/+bug/1350435
timeout --signal=SIGKILL 60 taskset 1 perl "${DEST}/scripts/mysql_install_db" --basedir="${DEST}" --datadir="${DEST}/data" --cross-bootstrap --thread-handling=no-threads --thread_concurrency=1

# taskset is needed due to bugs in qemu-user-static
# see: https://bugs.launchpad.net/ubuntu/+source/qemu/+bug/1350435
timeout --signal=SIGKILL 60 taskset 1 "${DEST}/bin/mysqld" --basedir="${DEST}" --datadir="${DEST}/data" --bootstrap --thread-handling=no-threads --thread_concurrency=1 < "src/mysql_secure_installation.sql"
}

### BUILD ###
_build() {
  _build_atomic
  _build_atomic64
  _build_zlib
  _build_openssl
  _build_ncurses
  _build_mysql
  _build_mywebsql
  _build_certificates
  _build_sql_bootstrap
  _package
}
