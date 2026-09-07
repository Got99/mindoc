package routers

import (
	"net"
	"net/http"
	"strconv"
	"strings"
	"unicode"

	"github.com/beego/beego/v2/server/web"
	"github.com/beego/beego/v2/server/web/context"
)

const untrustedDomainMessage = "Access through untrusted domain"

// FilterTrustedDomain 限制 MinDoc 只能通过 trusted_domains 中配置的地址访问。
// 配置为空时保持原有行为，不做域名限制。
func FilterTrustedDomain(ctx *context.Context) {
	filterTrustedDomain(ctx, web.AppConfig.DefaultString("trusted_domains", ""))
}

func filterTrustedDomain(ctx *context.Context, trustedDomains string) {
	if isTrustedDomain(ctx.Request.Host, trustedDomains) {
		return
	}

	ctx.Output.Header("Content-Type", "text/plain; charset=utf-8")
	ctx.Output.SetStatus(http.StatusBadRequest)
	_ = ctx.Output.Body([]byte(untrustedDomainMessage))
}

func isTrustedDomain(requestHost, trustedDomains string) bool {
	if strings.TrimSpace(trustedDomains) == "" {
		return true
	}

	normalizedRequestHost, ok := normalizeTrustedDomain(requestHost)
	if !ok {
		return false
	}

	for _, configuredHost := range strings.Split(trustedDomains, ",") {
		normalizedConfiguredHost, valid := normalizeTrustedDomain(configuredHost)
		if valid && normalizedRequestHost == normalizedConfiguredHost {
			return true
		}
	}

	return false
}

// normalizeTrustedDomain 对域名大小写、尾部的点和 IP 字面量做归一化。
// 端口会保留，因此 example.com 与 example.com:8443 是两个不同的可信地址。
func normalizeTrustedDomain(authority string) (string, bool) {
	authority = strings.TrimSpace(authority)
	if authority == "" || strings.ContainsAny(authority, "/\\?#@") {
		return "", false
	}

	if strings.HasPrefix(authority, "[") {
		closingBracket := strings.IndexByte(authority, ']')
		if closingBracket < 0 {
			return "", false
		}

		ip := net.ParseIP(authority[1:closingBracket])
		if ip == nil {
			return "", false
		}

		remainder := authority[closingBracket+1:]
		if remainder == "" {
			return "[" + strings.ToLower(ip.String()) + "]", true
		}
		if !strings.HasPrefix(remainder, ":") {
			return "", false
		}

		port, ok := normalizePort(remainder[1:])
		if !ok {
			return "", false
		}
		return net.JoinHostPort(strings.ToLower(ip.String()), port), true
	}

	if strings.ContainsAny(authority, "[]") {
		return "", false
	}

	colonCount := strings.Count(authority, ":")
	if colonCount > 1 {
		ip := net.ParseIP(authority)
		if ip == nil {
			return "", false
		}
		return "[" + strings.ToLower(ip.String()) + "]", true
	}

	host := authority
	port := ""
	if colonCount == 1 {
		var err error
		host, port, err = net.SplitHostPort(authority)
		if err != nil {
			return "", false
		}
		normalizedPort, ok := normalizePort(port)
		if !ok {
			return "", false
		}
		port = normalizedPort
	}

	host = strings.TrimSuffix(strings.ToLower(host), ".")
	if !isValidTrustedHostname(host) {
		return "", false
	}
	if ip := net.ParseIP(host); ip != nil {
		host = strings.ToLower(ip.String())
	}

	if colonCount == 1 {
		return net.JoinHostPort(host, port), true
	}
	return host, true
}

func normalizePort(port string) (string, bool) {
	portNumber, err := strconv.Atoi(port)
	if err != nil || portNumber < 1 || portNumber > 65535 {
		return "", false
	}
	return strconv.Itoa(portNumber), true
}

func isValidTrustedHostname(host string) bool {
	if host == "" || strings.HasPrefix(host, ".") || strings.Contains(host, "..") {
		return false
	}

	for _, char := range host {
		if unicode.IsLetter(char) || unicode.IsDigit(char) {
			continue
		}
		switch char {
		case '.', '-', '_':
			continue
		default:
			return false
		}
	}
	return true
}
