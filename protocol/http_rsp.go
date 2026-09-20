package protocol

import (
	"bytes"
	"net/http"
)

type HttpResponse struct {
	StatusCode  int
	ContentType string
	Body        bytes.Buffer
	Headers     http.Header
}
