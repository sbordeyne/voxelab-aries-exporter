# Voxelab Aries Prometheus Exporter

A minimal dart application that polls the socket on Voxelab Aries 3D printers to
export the metrics there into Prometheus-compatible formats

## Usage

### With docker

Image name: sbordeyne/voxelab-aries-exporter:latest

Environment variables:

- `HOSTNAME`: The hostname of the prometheus endpoint, defaults to `0.0.0.0`
- `PORT`: The port of the prometheus endpoint, defaults to `9000`
- `ARIES_IP`: the IP on the local network of the 3D printer to collect metrics from
- `ARIES_PORT`: the port of the socket of the 3D printer, `8899` by default
- `SOCKET_POLLING_INTERVAL`: time, in milliseconds, to wait between each poll of the socket. Defautls to 1000ms (1 second).

### With kubernetes

This repository includes `kustomize` files to quickly deploy this exporter in the `monitoring` namespace.

`kubectl apply -k https://github.com/sbordeyne/voxelab-aries-prometheus-exporter/kubernetes/kustomize`

### Locally

```sh
export ARIES_IP="192.168.1.28"
dart pub get
dart run bin/server.dart
```

## Resource usage

This app is very minimal, the docker image takes only 8MB. Each socket poll is expected to transfer around 200 bytes over TCP/IP.

## Endpoints

- `/metrics`: Prometheus metrics endpoint, answers with metrics in the prometheus format every time it is scraped by a prometheus-compatible scraper
- `/health`: Health check for health/readiness probes
- `/`: Homepage, simple HTML to debug the endpoint in the browser
