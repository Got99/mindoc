package controllers

import (
	"strings"
	"testing"
)

func TestBuildBlogAppendAPIExample(t *testing.T) {
	apiURL := buildBlogAppendAPIURL("http://127.0.0.1:8181/")
	if apiURL != "http://127.0.0.1:8181/api/v1/blog/content" {
		t.Fatalf("unexpected API URL: %q", apiURL)
	}

	example := buildBlogAppendAPIExample("http://127.0.0.1:8181", "test-token")
	for _, want := range []string{
		"http://127.0.0.1:8181/api/v1/blog/content",
		"Authorization: Bearer test-token",
		`"content": "## 标题\n追加内容"`,
		`"type": "add"`,
		`"position": "tail"`,
	} {
		if !strings.Contains(example, want) {
			t.Fatalf("example does not contain %q:\n%s", want, example)
		}
	}
	if strings.Contains(example, "?token=") {
		t.Fatalf("token must not be included in the URL:\n%s", example)
	}
}

func TestParseBlogAppendRequestBody(t *testing.T) {
	t.Run("v1 payload", func(t *testing.T) {
		req, err := parseBlogAppendRequestBody("application/json", []byte(`{
            "content": "first\nsecond",
            "type": "add",
            "position": "tail"
        }`))
		if err != nil {
			t.Fatal(err)
		}
		if req.Content != "first\nsecond" || req.Type != "add" || req.Position != "tail" {
			t.Fatalf("unexpected request: %#v", req)
		}
	})

	t.Run("json with charset", func(t *testing.T) {
		req, err := parseBlogAppendRequestBody("application/json; charset=utf-8", []byte(`{
            "blog_id": 1,
            "position": "head",
            "content": "first\nsecond",
            "token": "json-token"
        }`))
		if err != nil {
			t.Fatal(err)
		}
		if req.BlogID != 1 || req.Position != "head" || req.Content != "first\nsecond" || req.Token != "json-token" {
			t.Fatalf("unexpected request: %#v", req)
		}
	})

	t.Run("invalid json", func(t *testing.T) {
		if _, err := parseBlogAppendRequestBody("application/json", []byte(`{"blog\_id": 1}`)); err == nil {
			t.Fatal("expected invalid JSON to be rejected")
		}
	})
}

func TestApplyBlogContent(t *testing.T) {
	tests := []struct {
		name       string
		current    string
		newContent string
		writeType  string
		position   string
		want       string
	}{
		{name: "add to tail", current: "old", newContent: "new", writeType: "add", position: "tail", want: "old\n\nnew"},
		{name: "add to head", current: "old", newContent: "new", writeType: "add", position: "head", want: "new\n\nold"},
		{name: "overwrite", current: "old", newContent: "new", writeType: "overwrite", position: "tail", want: "new"},
		{name: "empty document", current: "", newContent: "new", writeType: "add", position: "tail", want: "new"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := applyBlogContent(tt.current, tt.newContent, tt.writeType, tt.position)
			if got != tt.want {
				t.Fatalf("got %q, want %q", got, tt.want)
			}
		})
	}
}

func TestResolveBlogAppendAPIToken(t *testing.T) {
	tests := []struct {
		name          string
		paramToken    string
		bodyToken     string
		headerToken   string
		authorization string
		want          string
	}{
		{name: "query parameter", paramToken: "query-token", bodyToken: "body-token", want: "query-token"},
		{name: "json body", bodyToken: "body-token", headerToken: "header-token", want: "body-token"},
		{name: "custom header", headerToken: "header-token", authorization: "Bearer bearer-token", want: "header-token"},
		{name: "bearer token", authorization: "bearer bearer-token", want: "bearer-token"},
		{name: "invalid authorization", authorization: "Basic credentials", want: ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := resolveBlogAppendAPIToken(tt.paramToken, tt.bodyToken, tt.headerToken, tt.authorization)
			if got != tt.want {
				t.Fatalf("got %q, want %q", got, tt.want)
			}
		})
	}
}
