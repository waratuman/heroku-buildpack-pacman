#!/bin/bash
pkgname=libarchive
pkgver=3.4.2
pkgrel=1
pkgdesc='Multi-format archive and compression library'
arch=(x86_64)
url='https://libarchive.org/'
license=(BSD)
depends=(acl attr bzip2 expat lz4 openssl xz zlib zstd)
provides=(libarchive.so)
validpgpkeys=('A5A45B12AD92D964B89EEE2DEC560C81CEC2276E') # Martin Matuska <mm@FreeBSD.org>
source=("https://github.com/${pkgname}/${pkgname}/releases/download/v${pkgver}/${pkgname}-${pkgver}.tar.xz"{,.asc})
sha256sums=('d8e10494b4d3a15ae9d67a130d3ab869200cfd60b2ab533b391b0a0d5500ada1'
            'SKIP')

prepare() {
  curl -Lso ${pkgname}-${pkgver}.tar.xz $source
  tar -Jxf ${pkgname}-${pkgver}.tar.xz
}

build() {
  cd $pkgname-$pkgver

  ./configure \
      --prefix=$1 \
      --without-xml2 \
      --without-nettle \
      --disable-static

  echo $1
  make
}

check() {
  cd $pkgname-$pkgver
  make check
}

package() {
  cd $pkgname-$pkgver
  make DESTDIR="$pkgdir" install
  install -Dm644 COPYING "$pkgdir/usr/share/licenses/libarchive/COPYING"
}
