################################################################
## PARAMETERS
##
## Overall project parameters (shared, or section-specific).
## Some examples. The variable name will be used as the field
## name - make sure you add them to the relevant `(section)?_param_names`
## 'index' of parameters, otherwise the pre-processor won't know
## to inject them.
################################################################

data-source=extdata/first
input_matrix = '$(data-source)data.csv'
input_feature_meta = '$(data-source)metadata.csv'
plot_formula = '~treatment'
subset = true
res_dir = '$(RESULTS_DIR)'

# Let later processes know which of those to include in every section -
# needs to be stored in the `_param_names` variable:
_param_names = input_matrix input_feature_meta plot_formula subset res_dir

# List of sections
# These will get used to pick up script names, and  yml metadata,
# so name everything in the 'source-dir' (`./building-blocks` by default)
# after one one of these
sections=Description Analysis Down-stream

# section specific
row_distance = 'euclidean'
nclust= 4
# `section`_param_names will determine which parameters get included
# every page of that section
Analysis_param_names = row_distance nclust

#Not necessary that each section has params


################################################################
## SECTIONS
##
## Section handling pre-amble
## Need to put this here so that any section-to-section
## dependencies can be put here also, but oughtn't need
## to change any of the underlying logic
################################################################
makefiles=$(patsubst %,$(staging_dir)/%.mk,$(sections))

#These makefiles will create a variable for each section, that lists the pages in
# that section.
include $(makefiles)

all_params=$(call params-of-section,) -P qmd_name:'$*'
#Set up dependencies and variables for each section
# The variables will contain the section_qmds and section_htmls
# The dependencies will contain the original qmd script and the
# target-specific params variable
# (`sections` from projects.mk, `section-dependency-template from global.mk)
$(foreach section,$(sections),$(eval $(call section-dependency-template,$(section))))
# Collate all the section files together
qmds=$(strip $(foreach section,$(sections),$($(section)_qmds)))
html_reports=$(strip $(foreach section,$(sections),$($(section)_htmls)))


## Section-to-section dependencies
## If certain reports need to be written before others.
## For 'make render' we rely on the linear progression through the sections,
## but for 'make pages' we can specify e.g.

# Down-stream_htmls: Analysis_htmls
# Analysis_htmls: Description_htmls



