# GNUmakefile

ifeq ($(HAVE_SPM),yes)

all-tool    : $(SWIFT_BUILD_DIR)/$(PACKAGE)
all-library : $(SWIFT_BUILD_DIR)/$(PACKAGE)

clean :
	(cd $(PACKAGE_DIR); $(SWIFT_CLEAN_TOOL))

$(SWIFT_BUILD_DIR)/$(PACKAGE) : *.swift
	(cd $(PACKAGE_DIR); $(SWIFT_BUILD_TOOL))

run : $(SWIFT_BUILD_DIR)/$(PACKAGE)
	$<

else # got no Swift Package Manager

$(warning "Swift Package Manager not available, building via make.")

ifeq ($($(PACKAGE)_SWIFT_FILES),)
$(PACKAGE)_SWIFT_FILES = $(wildcard *.swift)
endif

MODULE_DIR=$(PACKAGE_DIR)/..
$(PACKAGE)_INCLUDE_DIRS += $(addsuffix /$(SWIFT_REL_BUILD_DIR),$(addprefix $(MODULE_DIR)/,$($(PACKAGE)_SWIFT_MODULES)))
$(PACKAGE)_LIB_DIRS     += $(addsuffix /$(SWIFT_REL_BUILD_DIR),$(addprefix $(MODULE_DIR)/,$($(PACKAGE)_SWIFT_MODULES)))
$(PACKAGE)_LIBS         += $($(PACKAGE)_SWIFT_MODULES)

SWIFT_INTERNAL_LINK_FLAGS = \
  $(addprefix -I,$($(PACKAGE)_INCLUDE_DIRS)) \
  $(addprefix -L,$($(PACKAGE)_LIB_DIRS)) \
  $(addprefix -l,$($(PACKAGE)_LIBS))

clean :
	rm -rf $(SWIFT_BUILD_DIR)

all-tool : $(SWIFT_BUILD_DIR)/$(PACKAGE)

all-library : $(SWIFT_BUILD_DIR)/$(SHARED_LIBRARY_PREFIX)$(PACKAGE)$(SHARED_LIBRARY_SUFFIX)

$(SWIFT_BUILD_DIR)/$(PACKAGE) : *.swift
	@mkdir -p $(@D)
	$(SWIFTC) $(SWIFT_INTERNAL_BUILD_FLAGS) \
	   -emit-executable \
	   -emit-module -module-name $(PACKAGE) \
           $($(PACKAGE)_SWIFT_FILES) \
           -o $@ $(SWIFT_INTERNAL_LINK_FLAGS)

$(SWIFT_BUILD_DIR)/$(SHARED_LIBRARY_PREFIX)$(PACKAGE)$(SHARED_LIBRARY_SUFFIX) : *.swift
	@mkdir -p $(@D)
	$(SWIFTC) $(SWIFT_INTERNAL_BUILD_FLAGS) \
	   -emit-library \
	   -emit-module -module-name $(PACKAGE) \
           $($(PACKAGE)_SWIFT_FILES) \
           -o $@ $(SWIFT_INTERNAL_LINK_FLAGS)

run : $(SWIFT_BUILD_DIR)/$(PACKAGE)
	LD_LIBRARY_PATH="$($(PACKAGE)_LIB_DIRS)" $<

endif
