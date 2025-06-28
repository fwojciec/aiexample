# syntax=docker/dockerfile:1

# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy dependency files first for better caching
COPY go.mod go.sum ./
# Download dependencies as a separate layer for caching
RUN go mod download && go mod verify

# Copy source code
COPY . .

# Build arguments for cross-compilation
ARG TARGETOS
ARG TARGETARCH

# Build with security and optimization flags
RUN CGO_ENABLED=0 \
    GOOS=${TARGETOS:-linux} \
    GOARCH=${TARGETARCH:-amd64} \
    go build \
    -ldflags='-w -s -extldflags "-static"' \
    -trimpath \
    -o bookscanner ./cmd/server

# Production stage
FROM gcr.io/distroless/static-debian12:nonroot AS production

# Copy the binary from builder
COPY --from=builder /app/bookscanner /bookscanner

# Use non-root user
USER nonroot:nonroot

EXPOSE 8080

ENTRYPOINT ["/bookscanner"]

