FROM golang:1.23-alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags "-s -w -extldflags '-static'" \
    -a -installsuffix cgo \
    -o mcp-stockfish .

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y \
    stockfish \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 mcpuser
COPY --from=builder /app/mcp-stockfish /usr/local/bin/mcp-stockfish
RUN chmod +x /usr/local/bin/mcp-stockfish

ENV MCP_STOCKFISH_PATH=/usr/games/stockfish
ENV MCP_STOCKFISH_SERVER_MODE=http
ENV MCP_STOCKFISH_HTTP_HOST=0.0.0.0
ENV MCP_STOCKFISH_HTTP_PORT=8080

USER mcpuser
WORKDIR /home/mcpuser
EXPOSE 8080
ENTRYPOINT ["mcp-stockfish"]
