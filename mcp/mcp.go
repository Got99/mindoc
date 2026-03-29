// mcp.go 负责 MCP Server 的核心注册与入口组织。
// 它把 MinDoc 的部分能力以 MCP 协议的形式暴露出来。
package mcp

import (
	"github.com/mark3labs/mcp-go/server"
)

// MCPServer MinDoc MCP Server
type MCPServer struct {
	server *server.MCPServer
}

// NewMCPServer creates a new MinDoc MCP Server
func NewMCPServer() *MCPServer {
	mcpServer := server.NewMCPServer(
		"MinDoc MCP Server",
		"1.0.0",
		server.WithRecovery(),
	)

	mcpServer.AddTool(GetGlobalSearchMcpTool(), GlobalSearchMcpHandler)

	return &MCPServer{
		server: mcpServer,
	}
}

// ServeHTTP Run starts the server
func (s *MCPServer) ServeHTTP() *server.StreamableHTTPServer {
	return server.NewStreamableHTTPServer(s.server)
}
