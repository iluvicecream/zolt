package protocol

import "bytes"

type HttpResponse struct {
	StatusCode  int
	ContentType string
	Body        bytes.Buffer
	Headers     []HttpHeader
}

type HttpHeader struct {
	Key   string
	Value string
}
