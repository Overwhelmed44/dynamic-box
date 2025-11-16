FROM --platform=$BUILDPLATFORM golang:1.25 AS builder

WORKDIR /src

COPY go.mod go.sum ./
RUN go mod download

COPY . .

ARG TARGETOS TARGETARCH
ENV CGO_ENABLED=0
ENV GOOS=$TARGETOS
ENV GOARCH=$TARGETARCH

RUN apt-get update && apt-get install -y git build-essential \
    && go build -v -trimpath -tags \
        "with_gvisor,with_quic,with_dhcp,with_wireguard,with_utls,with_acme,with_clash_api,with_tailscale,with_ccm" \
        -o /out/sing-box \
        ./cmd/sing-box

FROM --platform=$TARGETPLATFORM debian:stable-slim

RUN apt-get update && apt-get install -y \
    bash \
    tzdata \
    ca-certificates \
    nftables \
    iproute2 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /out/sing-box /usr/local/bin/sing-box

ENTRYPOINT ["sing-box"]
