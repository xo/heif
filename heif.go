// Package heif wraps the [libheif] C library to encode and decode images.
//
// [libheif]: https://github.com/strukturag/libheif
package heif

/*
#cgo CFLAGS: -I${SRCDIR}
#cgo darwin,amd64 LDFLAGS: -L${SRCDIR}/libheif/darwin_amd64 -lheif
#cgo darwin,arm64 LDFLAGS: -L${SRCDIR}/libheif/darwin_arm64 -lheif
#cgo linux,amd64 LDFLAGS: -L${SRCDIR}/libheif/linux_amd64 -lheif
#cgo linux,arm64 LDFLAGS: -L${SRCDIR}/libheif/linux_arm64 -lheif
#cgo linux,arm LDFLAGS: -L${SRCDIR}/libheif/linux_arm -lheif
#cgo solaris,amd64 LDFLAGS: -L${SRCDIR}/libheif/solaris_amd64 -lheif
#cgo windows,amd64 LDFLAGS: -L${SRCDIR}/libheif/windows_amd64 -lheif

#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "libheif/heif.h"

char* version() {
	char* s = malloc(sizeof(LIBHEIF_VERSION));
	strncpy(s, LIBHEIF_VERSION, sizeof(LIBHEIF_VERSION));
	return s;
}

*/
import "C"

import (
	"image"
	"io"
	"unsafe"
)

// Version returns the heif version.
func Version() string {
	v := C.version()
	ver := C.GoString(v)
	C.free(unsafe.Pointer(v))
	return ver
}

// Decode decodes a image from the reader.
func Decode(r io.Reader) (image.Image, error) {
	img, err := DefaultDecoder.Decode(r)
	if err != nil {
		return nil, err
	}
	return img.Image()
}

// DecodeConfig decodes an image's config from the reader.
func DecodeConfig(r io.Reader) (image.Config, error) {
	return DefaultDecoder.DecodeConfig(r)
}

// Encode encodes a heif image to the writer.
func Encode(w io.Writer, img image.Image) error {
	return DefaultEncoder.Encode(w, img)
}

// Image is the interface for images.
type Image interface {
	Config() (image.Config, error)
	Image() (image.Image, error)
	Next() bool
	Close() error
	Err() error
}
