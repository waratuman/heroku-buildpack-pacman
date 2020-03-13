#!/bin/bash

set -x

pkgname=pacman
pkgver=5.2.1
pkgrel=4
pkgdesc="A library-based package manager with dependency support"
arch=('x86_64')
url="https://www.archlinux.org/pacman/"
license=('GPL')
groups=('base-devel')
depends=('bash' 'glibc' 'libarchive' 'curl'
         'gpgme' 'pacman-mirrorlist' 'archlinux-keyring')
makedepends=('asciidoc')
checkdepends=('python' 'fakechroot')
optdepends=('perl-locale-gettext: translation support in makepkg-template')
provides=('libalpm.so')
backup=(etc/pacman.conf
        etc/makepkg.conf)
options=('strip' 'debug')
validpgpkeys=('6645B0A8C7005E78DB1D7864F99FFE0FEAE999BD'  # Allan McRae <allan@archlinux.org>
              'B8151B117037781095514CA7BBDFFC92306B1121') # Andrew Gregory (pacman) <andrew@archlinux.org>
source=(https://sources.archlinux.org/other/pacman/$pkgname-$pkgver.tar.gz{,.sig}
        pacman-5.2.1-fix-pactest-package-tar-format.patch::https://git.archlinux.org/pacman.git/patch/?id=b9faf652735c603d1bdf849a570185eb721f11c1
        makepkg-fix-one-more-file-seccomp-issue.patch::https://git.archlinux.org/svntogit/packages.git/plain/trunk/makepkg-fix-one-more-file-seccomp-issue.patch?h=packages/pacman)
        # pacman.conf::https://git.archlinux.org/svntogit/packages.git/plain/trunk/pacman.conf?h=packages/pacman
        # makepkg.conf::https://git.archlinux.org/svntogit/packages.git/plain/trunk/makepkg.conf?h=packages/pacman)

sha256sums=('1930c407265fd039cb3a8e6edc82f69e122aa9239d216d9d57b9d1b9315af312'
            'SKIP'
            'd268379269c9dfa6eb3358f8931d3c84ef5fa4d47fe22567022fcbac8e4638c1'
            'e481a161bba76729cd434c97e0b319ddfcb1d93b2e4890d72b4e8a32982531d9'
            '3353f363088c73f1f86a890547c0f87c7473e5caf43bbbc768c2e9a7397f2aa2'
            '8c100b64450f5a19a16325dd05c143d49395bdeb96bd957f863cde4b95d3cb86')

prepare() {
    for s in ${source[*]}
    do
        filename=$(awk -F"::" '{ print $1 }' <<< $s)
        url=$(awk -F"::" '{ print $2 }' <<< $s)
        if  [[ !  -z  $url  ]]
        then
            curl -Lso $filename $url
        else
            curl -LsO $filename
        fi
    done

	cat <<- EOF > ./pacman.conf
		#
		# ${pkgdir}/etc/pacman.conf
		#
		# See the pacman.conf(5) manpage for option and repository directives

		[options]
		RootDir     = ${pkgdir}
		DBPath      = ${pkgdir}/var/lib/pacman/
		CacheDir    = ${pkgdir}/var/cache/pacman/pkg/
		LogFile     = ${pkgdir}/var/log/pacman.log
		GPGDir      = ${pkgdir}/etc/pacman.d/gnupg/
		HookDir     = ${pkgdir}/etc/pacman.d/hooks/
		HoldPkg     = pacman glibc
		Architecture = auto
		CheckSpace
		SigLevel    = Required DatabaseOptional
		LocalFileSigLevel = Optional

		[core]
		Include = /etc/pacman.d/mirrorlist

		[extra]
		Include = /etc/pacman.d/mirrorlist

		[community]
		Include = /etc/pacman.d/mirrorlist
	EOF

	cat <<-EOF > ./makepkg.conf
		#!/hint/bash
		#
		# ${pkgdir}/etc/makepkg.conf
		#

		#########################################################################
		# SOURCE ACQUISITION
		#########################################################################
		#
		#-- The download utilities that makepkg should use to acquire sources
		#  Format: 'protocol::agent'
		DLAGENTS=('file::/usr/bin/curl -gqC - -o %o %u'
				'ftp::/usr/bin/curl -gqfC - --ftp-pasv --retry 3 --retry-delay 3 -o %o %u'
				'http::/usr/bin/curl -gqb "" -fLC - --retry 3 --retry-delay 3 -o %o %u'
				'https::/usr/bin/curl -gqb "" -fLC - --retry 3 --retry-delay 3 -o %o %u'
				'rsync::/usr/bin/rsync --no-motd -z %u %o'
				'scp::/usr/bin/scp -C %u %o')

		#-- The package required by makepkg to download VCS sources
		#  Format: 'protocol::package'
		VCSCLIENTS=('bzr::bzr'
					'git::git'
					'hg::mercurial'
					'svn::subversion')

		#########################################################################
		# ARCHITECTURE, COMPILE FLAGS
		#########################################################################
		#
		CARCH="x86_64"
		CHOST="x86_64-pc-linux-gnu"

		#-- Compiler and Linker Flags
		CPPFLAGS="-D_FORTIFY_SOURCE=2"
		CFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt"
		CXXFLAGS="-march=x86-64 -mtune=generic -O2 -pipe -fno-plt"
		LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
		#-- Make Flags: change this for DistCC/SMP systems
		#MAKEFLAGS="-j2"
		#-- Debugging flags
		DEBUG_CFLAGS="-g -fvar-tracking-assignments"
		DEBUG_CXXFLAGS="-g -fvar-tracking-assignments"

		#########################################################################
		# BUILD ENVIRONMENT
		#########################################################################
		#
		# Defaults: BUILDENV=(!distcc !color !ccache check !sign)
		#  A negated environment option will do the opposite of the comments below.
		#
		#-- distcc:   Use the Distributed C/C++/ObjC compiler
		#-- color:    Colorize output messages
		#-- ccache:   Use ccache to cache compilation
		#-- check:    Run the check() function if present in the PKGBUILD
		#-- sign:     Generate PGP signature file
		#
		BUILDENV=(!distcc color !ccache check !sign)
		#
		#-- If using DistCC, your MAKEFLAGS will also need modification. In addition,
		#-- specify a space-delimited list of hosts running in the DistCC cluster.
		#DISTCC_HOSTS=""
		#
		#-- Specify a directory for package building.
		#BUILDDIR=/tmp/makepkg

		#########################################################################
		# GLOBAL PACKAGE OPTIONS
		#   These are default values for the options=() settings
		#########################################################################
		#
		# Default: OPTIONS=(!strip docs libtool staticlibs emptydirs !zipman !purge !debug)
		#  A negated option will do the opposite of the comments below.
		#
		#-- strip:      Strip symbols from binaries/libraries
		#-- docs:       Save doc directories specified by DOC_DIRS
		#-- libtool:    Leave libtool (.la) files in packages
		#-- staticlibs: Leave static library (.a) files in packages
		#-- emptydirs:  Leave empty directories in packages
		#-- zipman:     Compress manual (man and info) pages in MAN_DIRS with gzip
		#-- purge:      Remove files specified by PURGE_TARGETS
		#-- debug:      Add debugging flags as specified in DEBUG_* variables
		#
		OPTIONS=(strip docs !libtool !staticlibs emptydirs zipman purge !debug)

		#-- File integrity checks to use. Valid: md5, sha1, sha256, sha384, sha512
		INTEGRITY_CHECK=(md5)
		#-- Options to be used when stripping binaries. See \`man strip' for details.
		STRIP_BINARIES="--strip-all"
		#-- Options to be used when stripping shared libraries. See \`man strip' for details.
		STRIP_SHARED="--strip-unneeded"
		#-- Options to be used when stripping static libraries. See \`man strip' for details.
		STRIP_STATIC="--strip-debug"
		#-- Manual (man and info) directories to compress (if zipman is specified)
		MAN_DIRS=(${pkgdir}/{usr{,/local}{,/share},opt/*}/{man,info})
		#-- Doc directories to remove (if !docs is specified)
		DOC_DIRS=(${pkgdir}/usr/{,local/}{,share/}{doc,gtk-doc} opt/*/{doc,gtk-doc})
		#-- Files to be removed from all packages (if purge is specified)
		PURGE_TARGETS=(${pkgdir}/usr/{,share}/info/dir .packlist *.pod)
		#-- Directory to store source code in for debug packages
		DBGSRCDIR="${pkgdir}/usr/src/debug"

		#########################################################################
		# PACKAGE OUTPUT
		#########################################################################
		#
		# Default: put built package and cached source in build directory
		#
		#-- Destination: specify a fixed directory where all packages will be placed
		#PKGDEST=/home/packages
		#-- Source cache: specify a fixed directory where source files will be cached
		#SRCDEST=/home/sources
		#-- Source packages: specify a fixed directory where all src packages will be placed
		#SRCPKGDEST=/home/srcpackages
		#-- Log files: specify a fixed directory where all log files will be placed
		#LOGDEST=/home/makepkglogs
		#-- Packager: name/email of the person or organization building packages
		#PACKAGER="John Doe <john@doe.com>"
		#-- Specify a key to use for package signing
		#GPGKEY=""

		#########################################################################
		# COMPRESSION DEFAULTS
		#########################################################################
		#
		COMPRESSGZ=(gzip -c -f -n)
		COMPRESSBZ2=(bzip2 -c -f)
		COMPRESSXZ=(xz -c -z -)
		COMPRESSZST=(zstd -c -z -q -)
		COMPRESSLRZ=(lrzip -q)
		COMPRESSLZO=(lzop -q)
		COMPRESSZ=(compress -c -f)
		COMPRESSLZ4=(lz4 -q)
		COMPRESSLZ=(lzip -c -f)

		#########################################################################
		# EXTENSION DEFAULTS
		#########################################################################
		#
		PKGEXT='.pkg.tar.xz'
		SRCEXT='.src.tar.gz'
	EOF

    tar -xzf $pkgname-$pkgver.tar.gz
    cd "$pkgname-$pkgver"

    patch -Np1 < ../pacman-5.2.1-fix-pactest-package-tar-format.patch
    patch -Np1 < ../makepkg-fix-one-more-file-seccomp-issue.patch
}

build() {
  cd "$pkgname-$pkgver"

  ./configure --prefix=$pkgdir \
    --sysconfdir=$pkgdir/etc \
    --localstatedir=$pkgdir/var \
    --enable-doc \
    --with-scriptlet-shell=$pkgdir/usr/bin/bash \
    --with-ldconfig=$pkgdir/usr/bin/ldconfig
  make V=1
}

check() {
  make -C "$pkgname-$pkgver" check
}

package() {
  cd "$pkgname-$pkgver"

  make DESTDIR="$pkgdir" install

  # install Arch specific stuff
  install -dm755 "$pkgdir/etc"
  install -m644 "$srcdir/pacman.conf" "$pkgdir/etc"
  install -m644 "$srcdir/makepkg.conf" "$pkgdir/etc"
}
