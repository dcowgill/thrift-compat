.PHONY: thrift thrift-go thrift-rb test test-go test-rb clean

all: thrift test

test: test-go test-rb

test-go:
	go test ./...

test-rb:
	ruby ts_compat.rb

clean: thrift-clean

THRIFT_SOURCES := $(wildcard thrift/*.thrift)

THRIFT_GO_TARGETS := $(patsubst thrift/%.thrift,gen/go/%/GoUnusedProtection__.go,$(THRIFT_SOURCES))
THRIFT_RB_TARGETS := $(patsubst thrift/%.thrift,gen/rb/%_constants.rb,$(THRIFT_SOURCES))

GO_THRIFT_IMPORT := github.com/dcowgill/thrift-go/thrift
GO_THRIFT_PKG_PREFIX := github.com/dcowgill/thrift-compat/gen/go/

$(THRIFT_GO_TARGETS): gen/go/%/GoUnusedProtection__.go : thrift/%.thrift
	thrift -strict -out ./gen/go -gen go:package_prefix=$(GO_THRIFT_PKG_PREFIX),thrift_import=$(GO_THRIFT_IMPORT) $<
	go fmt ./gen/go/...

$(THRIFT_RB_TARGETS): gen/rb/%_constants.rb : thrift/%.thrift
	thrift -strict -out ./gen/rb -gen rb $<

thrift: thrift-out-dirs thrift-go thrift-rb

thrift-out-dirs:
	@mkdir -p gen/{go,rb}

thrift-go: $(THRIFT_GO_TARGETS)

thrift-rb: $(THRIFT_RB_TARGETS)

thrift-clean:
	@rm -rf gen/{go,rb}/*
