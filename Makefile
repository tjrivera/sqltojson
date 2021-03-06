PROG_NAME := sqltojson
GIT_VERSION := $(shell git log -1 --pretty=format:"%h (%ci)" .)

build:
	go build -ldflags "-X \"main.buildVersion=$(GIT_VERSION)\"" \
		-o "$(GOPATH)/bin/$(PROG_NAME)"

dist:
	mkdir -p dist

	gox -ldflags "-X \"main.buildVersion=$(GIT_VERSION)\"" \
    	-os "darwin linux windows" \
        -arch "amd64" \
        -output="./dist/{{.OS}}/{{.Arch}}/$(PROG_NAME)" 

.PHONY: dist
