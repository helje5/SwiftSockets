# GNUmakefile

UNAME_S := $(shell uname -s)

ifeq ($(UNAME_S),Darwin)
  #SWIFT_SNAPSHOT=swift-DEVELOPMENT-SNAPSHOT-2016-03-01-a
  ifneq ($(SWIFT_SNAPSHOT),)
    SWIFT_TOOLCHAIN_BASEDIR=/Library/Developer/Toolchains
    SWIFT_TOOLCHAIN=$(SWIFT_TOOLCHAIN_BASEDIR)/$(SWIFT_SNAPSHOT).xctoolchain/usr/bin
  else
    SWIFT_TOOLCHAIN_BASEDIR=/Library/Developer/Toolchains
    SWIFT_TOOLCHAIN=$(SWIFT_TOOLCHAIN_BASEDIR)/swift-latest.xctoolchain/usr/bin
  endif
else
  OS=$(shell lsb_release -si | tr A-Z a-z)
  VER=$(shell lsb_release -sr)
  #SWIFT_SNAPSHOT=swift-DEVELOPMENT-SNAPSHOT-2016-03-01-a-$(OS)$(VER)
  SWIFT_SNAPSHOT=
  ifneq ($(SWIFT_SNAPSHOT),)
    SWIFT_TOOLCHAIN_BASEDIR=$(HOME)/swift-not-so-much
    SWIFT_TOOLCHAIN=$(SWIFT_TOOLCHAIN_BASEDIR)/$(SWIFT_SNAPSHOT)/usr/bin
  endif
endif


ifneq ($(SWIFT_TOOLCHAIN),)
SWIFT_TOOLCHAIN_PREFIX=$(SWIFT_TOOLCHAIN)/
else
SWIFT_TOOLCHAIN_PREFIX=
endif


ifeq ($(debug),on)
SWIFT_INTERNAL_BUILD_FLAGS += -c debug
else
SWIFT_INTERNAL_BUILD_FLAGS += -c release
endif

SWIFT_INTERNAL_BUILD_FLAGS += -Xcc -fblocks -Xlinker -ldispatch


SWIFT_BUILD_TOOL=$(SWIFT_TOOLCHAIN_PREFIX)swift build $(SWIFT_INTERNAL_BUILD_FLAGS)
SWIFT_CLEAN_TOOL=$(SWIFT_TOOLCHAIN_PREFIX)swift build --clean
SWIFT_BUILD_DIR=$(PACKAGE_DIR)/.build/debug
