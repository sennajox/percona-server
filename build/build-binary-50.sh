#!/bin/sh
#
# Execute this tool to setup the environment and build binary releases
# for Percona-Server starting from a fresh tree.
#
# Usage: build-binary.sh [target dir]
# The default target directory is the current directory. If it is not
# supplied and the current directory is not empty, it will issue an error in
# order to avoid polluting the current directory after a test run.
#

# Bail out on errors, be strict
set -ue

AUTOGEN=no

# Examine parameters
TARGET="$(uname -m)"
TARGET_CFLAGS=''

# Check if we have a functional getopt(1)
if ! getopt --test
then
    go_out="$(getopt --options="ai" --longoptions=autogen,i686 \
        --name="$(basename "$0")" -- "$@")"
    test $? -eq 0 || exit 1
    eval set -- $go_out
fi

for arg
do
    case "$arg" in
    -- ) shift; break;;
    -a | --autogen ) shift; AUTOGEN=yes;;
    -i | --i686 )
        shift
        TARGET="i686"
        TARGET_CFLAGS="-m32 -march=i686"
        ;;
    esac
done

# Working directory
if test "$#" -eq 0
then
    WORKDIR="$(pwd)"
    
    # Check that the current directory is not empty
    if test "x$(echo *)" != "x*"
    then
        echo >&2 \
            "Current directory is not empty. Use $0 . to force build in ."
        exit 1
    fi

elif test "$#" -eq 1
then
    WORKDIR="$1"

    # Check that the provided directory exists and is a directory
    if ! test -d "$WORKDIR"
    then
        echo >&2 "$WORKDIR is not a directory"
        exit 1
    fi

    WORKDIR_ABS="$(cd "$WORKDIR"; pwd)"

else
    echo >&2 "Usage: $0 [target dir]"
    exit 1

fi

SOURCEDIR="$(cd $(dirname "$0"); cd ..; pwd)"
test -e "$SOURCEDIR/Makefile" || exit 2

# Extract version from the Makefile
MYSQL_VERSION="$(grep ^MYSQL_VERSION= "$SOURCEDIR/Makefile" \
    | cut -d = -f 2)"
PATCHSET="$(grep ^PATCHSET= "$SOURCEDIR/Makefile" | cut -d = -f 2)"
PRODUCT="Percona-Server-$MYSQL_VERSION-$PATCHSET"

# Build information
REVISION="$(cd "$SOURCEDIR"; bzr log -r-1 | grep ^revno: | cut -d ' ' -f 2)"
PRODUCT_FULL="$PRODUCT.$REVISION.$(uname -s).$TARGET"
COMMENT="Percona Server with XtraDB (GPL), Release $PRODUCT"
COMMENT="$COMMENT, Revision $REVISION"

# Compilation flags
export CC=gcc
export CXX=gcc
export CFLAGS="-fPIC -Wall -O3 -g -static-libgcc -fno-omit-frame-pointer $TARGET_CFLAGS"
export CXXFLAGS="-O2 -fno-omit-frame-pointer -g -pipe -Wall -Wp,-D_FORTIFY_SOURCE=2 -fno-exceptions $TARGET_CFLAGS"
export MAKE_JFLAG=-j4

# Create a temporary working directory
INSTALLDIR="$(cd "$WORKDIR" && TMPDIR="$WORKDIR_ABS" mktemp -d percona-build.XXXXXX)"
INSTALLDIR="$WORKDIR_ABS/$INSTALLDIR"   # Make it absolute

# Prepare sources
(
    cd "$INSTALLDIR"
 
    # Execute clean and download mysql
    wget "http://www.percona.com/downloads/community/mysql-$MYSQL_VERSION.tar.gz"
    tar xzf "mysql-$MYSQL_VERSION.tar.gz"
    mv "mysql-$MYSQL_VERSION" "$PRODUCT_FULL"
    
    # Apply patches
    cd "$PRODUCT_FULL"
    for p in $(cat "$SOURCEDIR/series")
    do
        patch -p1 < "$SOURCEDIR/$p"
    done

    # Run autogen if needed
    if test "x$AUTOGEN" = "xyes"
    then
        sh BUILD/autorun.sh
    fi

    # Configure
    ./configure --prefix="/usr/local/$PRODUCT_FULL" \
                --localstatedir="/usr/local/$PRODUCT_FULL/data" \
                --enable-shared \
                --enable-assembler \
                --with-pic \
                --without-debug \
                --with-readline \
                --without-libedit \
                --without-bench \
                --without-extra-tools \
                --with-libwrap \
                --with-low-memory \
                --with-comment="$COMMENT" \
                --enable-thread-safe-client \
                --with-yassl --without-embedded-server \
                --with-client-ldflags=-all-static \
                --with-mysqld-ldflags=-all-static \
                --with-innodb \
                --with-csv-storage-engine \
                --with-archive-storage-engine \
                --with-blackhole-storage-engine \
                --with-federated-storage-engine \
                --with-big-tables \
                --enable-local-infile \
                --with-extra-charsets=complex

    make $MAKE_JFLAG VERBOSE=1
    make DESTDIR="$INSTALLDIR" install

)

# Package the archive
(
    cd "$INSTALLDIR/usr/local/"

    tar czf "$WORKDIR_ABS/$PRODUCT_FULL.tar.gz" \
        --owner=root --group=root "$PRODUCT_FULL/"
    
)

# Clean up
rm -rf "$INSTALLDIR"

