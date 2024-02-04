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
	"image/color"
	"io"
)

// DefaultDecoder is the default decoder.
var DefaultDecoder = NewDecoder()

// Decoder wraps calling the [libheif] C library to decode [image.Image] data.
//
// [libheif]: https://github.com/strukturag/libheif
type Decoder struct{}

// NewDecoder creates a new heif image decoder.
func NewDecoder(opts ...DecoderOption) *Decoder {
	dec := new(Decoder)
	for _, o := range opts {
		o(dec)
	}
	dec.buildOpts()
	// r.init()
	// runtime.SetFinalizer(r, (*Heif).finalize)
	return dec
}

// buildOpts builds the decoder options.
func (dec *Decoder) buildOpts() {
}

/*
func (r *Heif) init() {
	C.heif_init(nil)
}

// finalize finalizes the C allocations.
func (r *Heif) finalize() {
	C.heif_deinit()
	runtime.SetFinalizer(r, nil)
}
*/

// DecodeConfig parses decodes the image config.
func (dec *Decoder) DecodeConfig(r io.Reader) (image.Config, error) {
	/*
		if r.opts == nil {
			return image.Config{}, errors.New("options not initialized")
		}
		tree, errno := C.parse(data, r.opts)
		if errno != nil {
			return image.Config{}, NewParseError(errno)
		}
		// height/width
		size := C.reheif_get_image_size(tree)
		width, height := int(size.width), int(size.height)
		// destroy
		C.resvg_tree_destroy(tree)
	*/
	width, height := 200, 200
	return image.Config{
		ColorModel: color.RGBAModel,
		Width:      width,
		Height:     height,
	}, nil
}

// Decode decodes the an image.
func (dec *Decoder) Decode(r io.Reader) (Image, error) {
	return nil, nil
}

// DecoderOption is a decoder option.
type DecoderOption func(*Decoder)

// imageDecoder
type imageDecoder struct{}

// heifReader wraps a [bufio.Reader] for use with libheif's reader
// functionality.
type heifReader struct {
	r *bufio.Reader
}

// newReader creates a new heif reader.
func newReader(r io.Reader) *heifReader {
	return &heifReader{
		r: bufio.NewReader(r),
	}
}
