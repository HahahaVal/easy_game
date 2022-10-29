.PHONY: all clean

TOP=.
BIN_DIR=./bin
BUILD_DIR=./build
BUILD_CLUALIB_DIR=$(BUILD_DIR)/clualib
BUILD_CSERVICE_DIR=$(BUILD_DIR)/cservice
INCLUDE_DIR=$(BUILD_DIR)/include
PROTO_DIR=$(BUILD_DIR)/sproto

LUA_BIN="./skynet/3rd/lua/lua"

# set lua path
export LUA_CPATH=$(TOP)/$(BUILD_CLUALIB_DIR)/?.so
export LUA_PATH=$(TOP)/lualib/?.lua;$(TOP)/skynet/lualib/?.lua

all: build submodule


submodule:
	git submodule update --init


build:
	-mkdir -p $(BUILD_DIR)
	-mkdir -p $(BIN_DIR)
	-mkdir -p $(INCLUDE_DIR)
	-mkdir -p $(PROTO_DIR)
	
	-mkdir -p $(BUILD_CLUALIB_DIR)
	-mkdir -p $(BUILD_CSERVICE_DIR)


#############################skynet build
.PHONY: skynet
all: skynet
SKYNET_MAKEFILE=skynet/Makefile

$(SKYNET_MAKEFILE):
	git submodule update --init

SKYNET_DEP_PATH=SKYNET_BUILD_PATH=../$(BIN_DIR) \
		LUA_CLIB_PATH=../$(BUILD_CLUALIB_DIR) \
		CSERVICE_PATH=../$(BUILD_CSERVICE_DIR)

build-skynet: $(SKYNET_MAKEFILE)
	cd skynet && $(MAKE) PLAT=linux $(SKYNET_DEP_PATH)

skynet: build-skynet
	cp skynet/skynet-src/skynet_malloc.h $(INCLUDE_DIR)
	cp skynet/skynet-src/skynet.h $(INCLUDE_DIR)
	cp skynet/skynet-src/skynet_env.h $(INCLUDE_DIR)
	cp skynet/skynet-src/skynet_socket.h $(INCLUDE_DIR)
	cp skynet/3rd/lua/lua.h $(INCLUDE_DIR)
	cp skynet/3rd/lua/lauxlib.h $(INCLUDE_DIR)
	cp skynet/3rd/lua/lualib.h $(INCLUDE_DIR)
	cp skynet/3rd/lua/luaconf.h $(INCLUDE_DIR)

define CLEAN_SKYNET
	cd skynet && $(MAKE) $(SKYNET_DEP_PATH) clean
endef
CLEAN_ALL += $(CLEAN_SKYNET)


#############################sproto build
all: sproto

COMM_DIR=./comm
SPROTO_DIR=$(COMM_DIR)/sprotodump
CLIENT_SPROTO:= $(shell find $(COMM_DIR)/client_sproto -name "*.sproto")

sproto: $(PROTO_DIR)/sproto.spb $(PROTO_DIR)/sproto_list.lua

$(PROTO_DIR)/sproto.spb: $(CLIENT_SPROTO)
	LUA_PATH="$(SPROTO_DIR)/?.lua" $(LUA_BIN) $(SPROTO_DIR)/sprotodump.lua -spb $^ -o $@ -namespace

$(PROTO_DIR)/sproto_list.lua: $(CLIENT_SPROTO)
	LUA_PATH="$(SPROTO_DIR)/?.lua" $(LUA_BIN) $(SPROTO_DIR)/sprotodump.lua -lua $^ -o $@ -namespace
	cp $(PROTO_DIR)/sproto_list.lua lualib/


##########################clib build
all: luaclib

luaclib: $(BUILD_CLUALIB_DIR)/trie.so

CFLAGS ?= -g -O2 -Wall -fPIC -shared -std=c++11

LUACLIB_PATH=$(TOP)/luaclib
TRIE_PATH=$(LUACLIB_PATH)/trie_filter
INCLUDE_PATH ?= -I$(TRIE_PATH)

$(BUILD_CLUALIB_DIR)/trie.so: $(TRIE_PATH)/lTrieFilter.cpp $(TRIE_PATH)/TrieFilter.cpp
	g++ $(CFLAGS) $(INCLUDE_PATH) $^ -o $@


##########################levent build
all: levent

levent: 
	cd ./tool/levent && cmake . && make

clean:
	-rm -rf build
	$(CLEAN_ALL)
