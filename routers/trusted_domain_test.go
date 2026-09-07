package routers

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/beego/beego/v2/server/web/context"
)

func TestIsTrustedDomain(t *testing.T) {
	tests := []struct {
		name           string
		requestHost    string
		trustedDomains string
		want           bool
	}{
		{name: "disabled", requestHost: "192.0.2.10:8181", trustedDomains: "", want: true},
		{name: "exact domain", requestHost: "docs.example.com", trustedDomains: "docs.example.com", want: true},
		{name: "case and trailing dot", requestHost: "DOCS.EXAMPLE.COM.", trustedDomains: "docs.example.com", want: true},
		{name: "one of multiple domains", requestHost: "docs.internal", trustedDomains: "docs.example.com, docs.internal", want: true},
		{name: "untrusted domain", requestHost: "other.example.com", trustedDomains: "docs.example.com", want: false},
		{name: "direct ipv4 rejected", requestHost: "192.0.2.10:8181", trustedDomains: "docs.example.com", want: false},
		{name: "configured ipv4 and port", requestHost: "192.0.2.10:8181", trustedDomains: "192.0.2.10:8181", want: true},
		{name: "port must match", requestHost: "docs.example.com:8443", trustedDomains: "docs.example.com", want: false},
		{name: "port normalization", requestHost: "docs.example.com:8443", trustedDomains: "docs.example.com:08443", want: true},
		{name: "ipv6", requestHost: "[2001:0db8::1]", trustedDomains: "[2001:db8::1]", want: true},
		{name: "ipv6 and port", requestHost: "[2001:0db8::1]:8443", trustedDomains: "[2001:db8::1]:8443", want: true},
		{name: "bare configured ipv6", requestHost: "[2001:db8::1]", trustedDomains: "2001:db8::1", want: true},
		{name: "url is not a domain", requestHost: "docs.example.com", trustedDomains: "https://docs.example.com", want: false},
		{name: "wildcards are not enabled", requestHost: "docs.example.com", trustedDomains: "*.example.com", want: false},
		{name: "invalid nonempty configuration denies", requestHost: "docs.example.com", trustedDomains: ",", want: false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := isTrustedDomain(tt.requestHost, tt.trustedDomains); got != tt.want {
				t.Fatalf("isTrustedDomain(%q, %q) = %v, want %v", tt.requestHost, tt.trustedDomains, got, tt.want)
			}
		})
	}
}

func TestFilterTrustedDomainRejectsRequest(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "http://192.0.2.10:8181/static/app.js", nil)
	recorder := httptest.NewRecorder()
	ctx := context.NewContext()
	ctx.Reset(recorder, request)

	filterTrustedDomain(ctx, "docs.example.com")

	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusBadRequest)
	}
	if body := recorder.Body.String(); body != untrustedDomainMessage {
		t.Fatalf("body = %q, want %q", body, untrustedDomainMessage)
	}
	if contentType := recorder.Header().Get("Content-Type"); contentType != "text/plain; charset=utf-8" {
		t.Fatalf("Content-Type = %q", contentType)
	}
	if !ctx.ResponseWriter.Started {
		t.Fatal("response was not marked as started")
	}
}

func TestFilterTrustedDomainAllowsRequest(t *testing.T) {
	request := httptest.NewRequest(http.MethodGet, "https://docs.example.com/static/app.js", nil)
	recorder := httptest.NewRecorder()
	ctx := context.NewContext()
	ctx.Reset(recorder, request)

	filterTrustedDomain(ctx, "docs.example.com")

	if ctx.ResponseWriter.Started {
		t.Fatal("allowed request unexpectedly wrote a response")
	}
}
