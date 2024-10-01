FROM golang:1.23 AS build

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY *.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -o app

FROM build-stage AS test
RUN go test -v ./...

FROM gcr.io/distroless/static-debian12 AS release

WORKDIR /

COPY --from=build /app/app /app

USER nonroot:nonroot

ENTRYPOINT ["/app"]
