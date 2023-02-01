.DEFAULT_GOAL=help

# command to invoke quarto
QUARTO=quarto


################################################################
## Directories
################################################################
# Location of qmds and multi-yaml files
source_dir=building-blocks
# Place where qmds will be generated
staging_dir=staging
# place within the staging directory where renders will be placed
RESULTS_DIR = results

################################################################
## Placeholders
##
## We need to insert lines into scripts at various places.
## Here, we let 'make' know where we want those injections
## to happen
################################################################
## If we need the filename of the yml file that contains the
## parameters. File won't have the initial `params:`, nor will
## the individual lines be indented
yaml-filename-placeholder={{YAML_FROM_MAKE}}

## The (indented) parameters will be injected immediately after
## every match of
params-after-line=params:

## The relevant metadata (title, etc) will replace the following line
metadata-subst-line=metadata-files:

## Marker in the _quarto above which the sidebar info will be placed
sections-before-line=\#sections get inserted above

################################################################
## Logic necessary for the project-specific part
## Nothing beyond this point _should_ need customising
################################################################

# Macros to turn section heading into qmd/html filenames
# $(1)_pages is a variable that will get set by the `section`.mk file
# and will contain the page names derived from the multi-stanza
# yml source file for that section.
qmds-of-section = $(patsubst %,$(staging_dir)/%.qmd,$($(1)_pages))
htmls-of-section = $(patsubst %,$(staging_dir)/$(RESULTS_DIR)/%.html,$($(1)_pages))
params-of-section = $(foreach p,$($(1)_param_names),$(patsubst %,-P %:$($(p)),$(p)))

define section-dependency-template = 
$(1)_htmls=$(call htmls-of-section,$(1))
$(1)_qmds=$(call qmds-of-section,$(1))
$$($(1)_qmds): $(source_dir)/$(1).qmd
$$($(1)_qmds): params=$(call params-of-section,$(1))
endef


#Standard makefile hacks
comma:= ,
space:= $() $()
empty:= $()
define newline

$(empty)
endef


################################################################
# Standard Goals
################################################################

print-%: ## `make print-varname` will show varname's value
	@echo "$*"="$($*)"


$(V).SILENT: 


.PHONY: help
help: ## Show help message
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m\033[0m\n"} /^[$$()% 0-9a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
