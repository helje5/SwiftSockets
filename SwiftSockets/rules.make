# GNUmakefile

all : $(SWIFT_BUILD_DIR)/$(PACKAGE)

$(SWIFT_BUILD_DIR)/$(PACKAGE) : *.swift
	(cd $(PACKAGE_DIR); $(SWIFT_BUILD_TOOL))
