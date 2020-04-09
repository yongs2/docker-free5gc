#MAKEFILE

IMG_NAME := free5gc-v3
IMG_TAG := latest
REGISTRY_URL=192.168.5.69:5000

.PHONY: build
build:
	docker build -t ${IMG_NAME} -f Dockerfile .

.PHONY: run
run:
	docker run -d \
		--network=host \
		--rm --name ${IMG_NAME} ${IMG_NAME} || :

.PHONY: push
push:
	docker tag ${IMG_NAME} ${REGISTRY_URL}/${IMG_NAME}:${IMG_TAG}
	docker push ${REGISTRY_URL}/${IMG_NAME}:${IMG_TAG}

.PHONY: exec
exec:
	docker exec -it ${IMG_NAME} /bin/bash

.PHONY: stop
stop:
	docker stop ${IMG_NAME} || :

.PHONY: logs
logs:
	docker logs -f ${IMG_NAME} || :
