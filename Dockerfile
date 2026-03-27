# syntax=docker/dockerfile:1.7

ARG GO_IMAGE=golang:1.22-bookworm
ARG LAMBDA_BASE=public.ecr.aws/lambda/provided:al2023

FROM --platform=$BUILDPLATFORM ${GO_IMAGE} AS build
WORKDIR /src

ARG TARGETOS=linux
ARG TARGETARCH=arm64

COPY go.mod go.sum ./
RUN --mount=type=cache,target=/go/pkg/mod go mod download

COPY . .

RUN --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath -ldflags="-s -w" -tags lambda.norpc \
    -o /out/main ./cmd/proxy

FROM --platform=linux/arm64 ${LAMBDA_BASE}
COPY --from=build /out/main ./main
ENTRYPOINT ["./main"]
