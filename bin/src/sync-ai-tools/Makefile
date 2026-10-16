.PHONY: build install

build:
	go build -ldflags="-s -w" -o sync-ai-tools main.go

install: build
	cp sync-ai-tools ~/bin/sync-ai-tools
