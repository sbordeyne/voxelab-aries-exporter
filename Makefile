IMAGE_NAME := sbordeyne/voxelab-aries-exporter
TAG := latest

.PHONY: build

build:
	docker build -t $(IMAGE_NAME):$(TAG) .
	docker push $(IMAGE_NAME):$(TAG)
