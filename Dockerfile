FROM golang:1.23-alpine AS builder
RUN apk add --no-cache git
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY *.go ./
ARG VERSION=dev
ARG COMMIT_HASH
ARG BUILD_TIME
RUN CGO_ENABLED=0 GOOS=linux go build \
    -ldflags "-X main.version=${VERSION} -s -w -extldflags '-static'" \
    -a -installsuffix cgo \
    -o mcp-stockfish .

FROM alpine:3.19
RUN apk add --no-cache \
    stockfish \
    ca-certificates \
    && rm -rf /var/cache/apk/*
RUN addgroup -g 1000 mcpuser && \
    adduser -D -s /bin/bash -u 1000 -G mcpuser mcpuser
COPY --from=builder /app/mcp-stockfish /usr/local/bin/mcp-stockfish
RUN chmod +x /usr/local/bin/mcp-stockfish
ENV MCP_STOCKFISH_PATH=/usr/bin/stockfish
ENV MCP_STOCKFISH_SERVER_MODE=http
ENV MCP_STOCKFISH_HTTP_HOST=0.0.0.0
ENV MCP_STOCKFISH_HTTP_PORT=8080
ENV PATH="/usr/local/bin:${PATH}"
USER mcpuser
WORKDIR /home/mcpuser
EXPOSE 8080
ENTRYPOINT ["mcp-stockfish"]
