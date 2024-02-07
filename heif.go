// Package heif wraps the [libheif] C library to encode and decode images.
//
// [libheif]: https://github.com/strukturag/libheif
package heif

/*

// link to libde265, x265-git, aom, libwebp (libsharpyuv), svt-av1, zlib, libheif

#cgo CFLAGS: -I${SRCDIR}

#cgo LDFLAGS: -static -lheif -lde265 -lx265 -laom -lwebp -lwebpdecoder -lwebpdemux -lwebpmux -lsharpyuv -lSvtAv1Enc -lz -lm -lstdc++
#cgo darwin,amd64 LDFLAGS: -L${SRCDIR}/libheif/darwin_amd64
#cgo darwin,arm64 LDFLAGS: -L${SRCDIR}/libheif/darwin_arm64
#cgo linux,amd64 LDFLAGS: -L${SRCDIR}/libheif/linux_amd64
#cgo linux,arm64 LDFLAGS: -L${SRCDIR}/libheif/linux_arm64
#cgo linux,arm LDFLAGS: -L${SRCDIR}/libheif/linux_arm
#cgo windows,amd64 LDFLAGS: -L${SRCDIR}/libheif/windows_amd64

#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "libheif/heif.h"

*/
import "C"

import (
	"image"
	"io"
)

// Version returns the heif version.
func Version() string {
	return C.GoString(C.heif_get_version())
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
