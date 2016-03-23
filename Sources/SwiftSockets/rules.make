# GNUmakefile

ifeq ($(HAVE_SPM),yes)

all : $(SWIFT_BUILD_DIR)/$(PACKAGE)

clean :
	(cd $(PACKAGE_DIR); $(SWIFT_CLEAN_TOOL))

$(SWIFT_BUILD_DIR)/$(PACKAGE) : *.swift
	(cd $(PACKAGE_DIR); $(SWIFT_BUILD_TOOL))

else # got no Swift Package Manager

$(warning "Swift Package Manager not available, building via make.")

#$(error "Swift Package Manager is not available.")

ifeq ($($(PACKAGE)_SWIFT_FILES),)
$(PACKAGE)_SWIFT_FILES = $(wildcard *.swift)
endif

all : $(SWIFT_BUILD_DIR)/$(PACKAGE).swiftmodule

clean :
	rm -rf $(SWIFT_BUILD_DIR)

$(SWIFT_BUILD_DIR)/$(PACKAGE).swiftmodule : *.swift
	@mkdir -p $(@D)
	$(SWIFTC) $(SWIFT_INTERNAL_BUILD_FLAGS) \
	   -emit-module -module-name $(PACKAGE) \
           $($(PACKAGE)_SWIFT_FILES) \
           -o $@


endif
