FROM --platform=${BUILDPLATFORM} archlinux:latest AS builder
WORKDIR /app

RUN set -x && pacman -Sy --noconfirm
RUN set -x && pacman -S --noconfirm go npm

ARG TARGETARCH

COPY *.json ./ 
COPY *.sh ./ 
COPY go.mod go.sum ./
COPY vendor ./vendor

RUN npm install
RUN go mod download

COPY s ./s
COPY *.go ./
COPY *.ts ./ 

## build0
RUN GOOS=linux GOARCH=${TARGETARCH} go build -buildvcs=false -ldflags="-w -s -extldflags '-static'" -o ./moxtools ./main.go
RUN GOOS=linux GOARCH=${TARGETARCH} go vet ./...
RUN GOOS=linux GOARCH=${TARGETARCH} go run vendor/github.com/mjl-/sherpadoc/cmd/sherpadoc/*.go -adjust-function-names none -rename 'dmarc Policy DMARCPolicy' API >s/api.json
RUN GOOS=linux GOARCH=${TARGETARCH} go run vendor/github.com/mjl-/sherpats/cmd/sherpats/main.go -bytes-to-string -slices-nullable -maps-nullable -nullable-optional -namespace api api <s/api.json >api.ts

## frontend
RUN ./tsc.sh ./s/app.js lib.ts api.ts app.ts

## build1
RUN GOOS=linux GOARCH=${TARGETARCH} go build -buildvcs=false -ldflags="-w -s -extldflags '-static'" -o ./moxtools ./main.go

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
