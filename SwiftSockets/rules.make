# GNUmakefile

all : $(SWIFT_BUILD_DIR)/$(PACKAGE)

clean :
	(cd $(PACKAGE_DIR); $(SWIFT_CLEAN_TOOL))

$(SWIFT_BUILD_DIR)/$(PACKAGE) : *.swift
	(cd $(PACKAGE_DIR); $(SWIFT_BUILD_TOOL))
