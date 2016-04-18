# GNUmakefile

UNAME_S := $(shell uname -s)

SHARED_LIBRARY_PREFIX=lib

ifeq ($(UNAME_S),Darwin)
  #SWIFT_SNAPSHOT=swift-DEVELOPMENT-SNAPSHOT-2016-03-01-a
  ifneq ($(SWIFT_SNAPSHOT),)
    SWIFT_TOOLCHAIN_BASEDIR=/Library/Developer/Toolchains
    SWIFT_TOOLCHAIN=$(SWIFT_TOOLCHAIN_BASEDIR)/$(SWIFT_SNAPSHOT).xctoolchain/usr/bin
  else
    SWIFT_TOOLCHAIN_BASEDIR=/Library/Developer/Toolchains
    SWIFT_TOOLCHAIN=$(SWIFT_TOOLCHAIN_BASEDIR)/swift-latest.xctoolchain/usr/bin
  endif
  SHARED_LIBRARY_SUFFIX=.dylib
else
  OS=$(shell lsb_release -si | tr A-Z a-z)
  VER=$(shell lsb_release -sr)
  #SWIFT_SNAPSHOT=swift-DEVELOPMENT-SNAPSHOT-2016-03-01-a-$(OS)$(VER)
  SWIFT_SNAPSHOT=
  ifneq ($(SWIFT_SNAPSHOT),)
    SWIFT_TOOLCHAIN_BASEDIR=$(HOME)/swift-not-so-much
    SWIFT_TOOLCHAIN=$(SWIFT_TOOLCHAIN_BASEDIR)/$(SWIFT_SNAPSHOT)/usr/bin
  endif
  SWIFT_INTERNAL_BUILD_FLAGS  += -Xcc -fblocks -Xlinker -ldispatch
  SHARED_LIBRARY_SUFFIX=.so
endif


ifneq ($(SWIFT_TOOLCHAIN),)
  SWIFT_TOOLCHAIN_PREFIX=$(SWIFT_TOOLCHAIN)/
  SWIFT_BIN=$(SWIFT_TOOLCHAIN_PREFIX)swift
  SWIFT_BUILD_TOOL_BIN=$(SWIFT_BIN)-build
  ifeq ("$(wildcard $(SWIFT_BUILD_TOOL_BIN))", "")
    HAVE_SPM=no
  else
    HAVE_SPM=yes
  endif
else
  SWIFT_TOOLCHAIN_PREFIX=
  SWIFT_BIN=swift
  SWIFT_BUILD_TOOL_BIN=$(SWIFT_BIN)-build
  WHICH_SWIFT_BUILD_TOOL_BIN=$(shell which $(SWIFT_BUILD_TOOL_BIN))
  ifeq ("$(wildcard $(WHICH_SWIFT_BUILD_TOOL_BIN))", "")
    HAVE_SPM=no
  else
    HAVE_SPM=yes
  endif
endif

SWIFTC=$(SWIFT_BIN)c


ifeq ($(debug),on)
  ifeq ($(HAVE_SPM),yes)
    SWIFT_INTERNAL_BUILD_FLAGS += --configuration debug
  else
    SWIFT_INTERNAL_BUILD_FLAGS += -g
  endif
  SWIFT_REL_BUILD_DIR=.build/debug
else
  ifeq ($(HAVE_SPM),yes)
    SWIFT_INTERNAL_BUILD_FLAGS += --configuration release
  endif
  SWIFT_REL_BUILD_DIR=.build/release
endif
SWIFT_BUILD_DIR=$(PACKAGE_DIR)/$(SWIFT_REL_BUILD_DIR)


# Note: the invocations must not use swift-build, but 'swift build'
SWIFT_BUILD_TOOL=$(SWIFT_BIN) build $(SWIFT_INTERNAL_BUILD_FLAGS)
SWIFT_CLEAN_TOOL=$(SWIFT_BIN) build --clean
