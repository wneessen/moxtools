FROM --platform=${BUILDPLATFORM} alpine:latest AS builder
WORKDIR /app

RUN set -x && apk upgrade
RUN set -x && apk add go npm

ARG TARGETARCH

COPY *.json ./ 
COPY *.sh ./ 
COPY go.mod go.sum ./
COPY vendor ./vendor

RUN npm install

RUN GO_VERSION=$(grep '^go ' go.mod | awk '{print $2}') && \
    go install golang.org/dl/go${GO_VERSION}@latest && \
    /root/go/bin/go${GO_VERSION} download && \
    mkdir /root/bin && \
    ln -s /root/go/bin/go${GO_VERSION} /root/bin/go

RUN /root/bin/go mod download 

COPY s ./s
COPY *.go ./
COPY *.ts ./ 

## build0
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} /root/bin/go build -buildvcs=false -ldflags="-w -s -extldflags '-static'" -o ./moxtools ./main.go
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} /root/bin/go vet ./...
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} /root/bin/go run vendor/github.com/mjl-/sherpadoc/cmd/sherpadoc/*.go -adjust-function-names none -rename 'dmarc Policy DMARCPolicy' API >s/api.json
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} /root/bin/go run vendor/github.com/mjl-/sherpats/cmd/sherpats/main.go -bytes-to-string -slices-nullable -maps-nullable -nullable-optional -namespace api api <s/api.json >api.ts

## frontend
RUN ./tsc.sh ./s/app.js lib.ts api.ts app.ts

## build1
RUN CGO_ENABLED=0 GOOS=linux GOARCH=${TARGETARCH} /root/bin/go build -buildvcs=false -ldflags="-w -s -extldflags '-static'" -o ./moxtools ./main.go

FROM scratch
LABEL maintainer="wn@neessen.dev"
COPY ["docker-files/passwd", "/etc/passwd"]
COPY ["docker-files/group", "/etc/group"]
COPY --from=builder ["/etc/ssl/certs/ca-certificates.crt", "/etc/ssl/cert.pem"]

WORKDIR /moxtools
COPY --from=builder /app/moxtools ./

EXPOSE 8080
EXPOSE 8081

ENTRYPOINT ["/moxtools/moxtools"]
