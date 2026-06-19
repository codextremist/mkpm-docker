mkpm_version := 1.0.0

QUIET ?= @

define newline


endef

mkpm_pkg_manifest = $(file < $(mkpm_pkg_dir)/mkpkg)
ifndef mkpm_pkg_manifest
$(error Missing mkpkg file)
endif

$(eval mkpm_pkg_$(subst $(newline),$(newline)mkpm_pkg_,$(mkpm_pkg_manifest)))

mkpm_pkg_main ?= Makefile
mkpm_pkgs_dir ?= .mkpkgs

mkpm_local_pkgs = $(filter file://%,$(mkpm_pkg_dependencies))
mkpm_remote_pkgs = $(filter-out file://%,$(mkpm_pkg_dependencies))

mkpm_include_local_pkgs = $(foreach pkg,$(mkpm_local_pkgs),$(mkpm_pkgs_dir)/$(notdir $(subst file://,,$(pkg)))@local/$(mkpm_pkg_main))
mkpm_include_remote_pkgs = $(foreach pkg,$(mkpm_remote_pkgs),$(mkpm_pkgs_dir)/$(pkg)/$(mkpm_pkg_main))

mkpm_include_pkgs = $(mkpm_include_local_pkgs) $(mkpm_include_remote_pkgs)

define get-pkg
$(subst @, ,$(subst /, ,$(subst $(mkpm_pkgs_dir)/, ,$1)))
endef

define get-version
$(if $(word 2,$(call get-pkg,$1)),$(word 2,$(call get-pkg,$1)),latest)
endef

define get-name
$(word 1,$(call get-pkg,$1))
endef

.ONESHELL:

# .mkpkgs/mkpm-help@local
$(mkpm_include_local_pkgs): | mkpkg
	$(QUIET)mkdir -p $(@D)
	$(QUIET)ln -sfn $(subst file://,,$(filter %$(call get-name,$@),$(mkpm_local_pkgs)))/* $(@D)

$(mkpm_include_remote_pkgs): | mkpkg
	$(QUIET)mkdir -p $(@D)
	$(QUIET)cd $(@D)
	$(QUIET)curl -sLO https://github.com/codextremist/$(call get-name,$@)/archive/refs/tags/v$(call get-version,$@).tar.gz && tar -xvf v$(call get-version,$@).tar.gz -C ./ --strip-components=1
	$(QUIET)rm v$(call get-version,$@).tar.gz

mkpm-remove-packages: ## Remove all mkpm packages
	rm -rf $(mkpm_pkgs_dir)

mkpm-remove-outdated-packages: ## Remove outdated mkpm packages
	rm -rf $(filter-out $(patsubst %,$(mkpm_pkgs_dir)/%,$(_mkpm_pkg_dependencies)),$(wildcard $(mkpm_pkgs_dir)/*))


mkpm_included := true