package heif

/*

#include <stdlib.h>
#include <string.h>
#include <errno.h>

#include "libheif/heif.h"

*/
import "C"

import (
	"bufio"
	"image"
	"io"
)

// DefaultEncoder is the default encoder.
var DefaultEncoder = NewEncoder()

// Encoder wraps calling the [libheif] C library to encode [image.Image] data.
//
// [libheif]: https://github.com/strukturag/libheif
type Encoder struct{}

// NewEncoder creates a new heif image encoder.
func NewEncoder(opts ...EncoderOption) *Encoder {
	enc := new(Encoder)
	for _, o := range opts {
		o(enc)
	}
	enc.buildOpts()
	// r.init()
	// runtime.SetFinalizer(r, (*Heif).finalize)
	return enc
}

// buildOpts builds the encoder options.
func (enc *Encoder) buildOpts() {
}

// Encode encodes the an image.
func (enc *Encoder) Encode(w io.Writer, img image.Image) error {
	return nil
}

// EncoderOption is a encoder option.
type EncoderOption func(*Encoder)

// heifWriter wraps a [bufio.Writer] for use with libheif's writer
// functionality.
type heifWriter struct {
	w *bufio.Writer
}

// newWriter creates a new heif writer.
func newWriter(w io.Writer) *heifWriter {
	return &heifWriter{
		w: bufio.NewWriter(w),
	}
}
