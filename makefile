.PHONY: makefile global.mk project.mk
include global.mk   #Sysadmin settings for executibles etc.
include project.mk  #Provides analysis parametrisation


.PHONY: render
render: $(qmds)  $(staging_dir)/_quarto.yml $(staging_dir)/index.qmd ## Render the whole directory of generated qmds
	sed  -i 's#^  contents: .*#  contents: [$(subst $(space),$(comma),$(patsubst $(staging_dir)/%,%,$(qmds)))]#' $(staging_dir)/index.qmd
	$(QUARTO) render '$(staging_dir)' --output-dir $(RESULTS_DIR) --execute-dir $(CURDIR)

.PHONY: pages
pages: $(html_reports) ## Generate the renders individually
	sed  -i 's#^  contents: .*#  contents: [$(subst $(space),$(comma),$(patsubst $(staging_dir)/%,%,$(qmds)))]#' $(staging_dir)/index.qmd
	$(QUARTO) render '$(staging_dir)/index.qmd' --output-dir $(RESULTS_DIR) --execute-dir $(CURDIR)

$(html_reports) : $(staging_dir)/$(RESULTS_DIR)/%.html : $(staging_dir)/%.qmd $(staging_dir)/_quarto.yml $(staging_dir)/index.qmd
	$(QUARTO) render '$<' \
	  --output-dir $(RESULTS_DIR)/ \
	  --execute-dir $(CURDIR)

.PHONY: scripts
scripts: $(qmds) ## Generate all the parametrised scripts, into the staging directory. But don't render

$(qmds) : $(staging_dir)/%.qmd : $(staging_dir)/%.yml $(staging_dir)/%.params.yml
	cp $(filter %.qmd,$^) $@
	sed -e '/params:/,$$d' $(staging_dir)/$*.yml > $(staging_dir)/$*.tmp
	sed -i -e '/^$(metadata-subst-line)$$/ {' -e 'r $(staging_dir)/$*.tmp' -e 'd' -e '}' $@
	rm -f $(staging_dir)/$*.tmp
	sed -i -e 's#$(yaml-filename-placeholder)#$(staging_dir)/$*.params.yml#' $@
	sed -e 's/^/  /' $(staging_dir)/$*.params.yml > $(staging_dir)/$*.tmp
	sed  -i -e "/^${params-after-line}$$/r $(staging_dir)/$*.tmp" $@
	rm -f $(staging_dir)/$*.tmp


$(staging_dir)/%.params.yml: $(staging_dir)/%.yml
	sed -e '1,/^params:/d' $< > $@
	sed -i -e 's/^ *//' $@
	echo "${params}" | sed 's/ *-P *//; s/: */: /g; s/ *-P */\n/g;' >> $@
	echo "${all_params}" | sed 's/ *-P *//; s/: */: /g; s/ *-P */\n/g;' >> $@
	sed -i -e '/^$$/d' $@
	awk -F':' '!seen[$$1]++' $@ >> $@.tmp && mv $@.tmp $@


sed-section = sed -i '/^$(sections-before-line)$$/i \      - {section: $(1),contents: [$(subst $(space),$(comma),$(patsubst $(staging_dir)/%,%,$($(1)_qmds)))]}' $(2);

${staging_dir}/_quarto.yml: $(source_dir)/_quarto.yml $(qmds)
	cp -f $< $@
	$(foreach section,$(sections),$(call sed-section,$(section),$@))

${staging_dir}/index.qmd : $(source_dir)/index.qmd
	cp $< $@


# Separate a section-wide yml with a chunk per page into separate
# yml files. Chunks delimited by a title field.
# 

$(staging_dir)/%.yml:
	[  -z "$<" ] || awk -F': ' '/^title/{x=$$2;j=sprintf("%02d",i++)}{gsub(/[^[:alnum:]]/,"_",x);  if ("${staging_dir}/$(patsubst $(source_dir)/%.yml,%,$(filter %.yml,$^))_"j"_"x".yml" == "$@") print;}' $<  >$@
	[ ! -z "$<" ] || touch $@

# Create a makefile per section, that contains a variable derived from the
# source-file yaml stanzas.  The variable, named `section`_pages, will
# contain a list of all the yaml files in that section. And a rule that
# ensures the above rule will be invoked to generate the separate ymls
#

with-ymls=$(filter $(sections),$(patsubst $(source_dir)/%.yml,%,$(wildcard $(source_dir)/*.yml)))
without-ymls= $(filter-out $(with-ymls),$(sections))
mk-with-yml = $(patsubst %,$(staging_dir)/%.mk,$(with-ymls))
mk-no-yml = $(patsubst %,$(staging_dir)/%.mk,$(without-ymls))

$(mk-with-yml): $(staging_dir)/%.mk : $(source_dir)/%.yml
	mkdir -p $(staging_dir)
	awk -F': ' 'BEGIN {ORS=" "; print "$*_pages="}; /^title/{x=$$2;j=sprintf("%02d",i++); gsub(/[^[:alnum:]]/,"_",x); print "$*_"j"_"x;}' $< > $@
	echo -e '\n$*_yamls = $$(patsubst %,$(staging_dir)/%.yml,$${$*_pages})'>> $@
	echo -e '\n$${$*_yamls} : $<' >> $@

$(mk-no-yml):  $(staging_dir)/%.mk :
	mkdir -p $(staging_dir)
	echo "$*_pages = $*" >> $@

################################################################
## Cleaners
################################################################
clean: ## Remove caches and purely intermediate files
	rm -f $(staging_dir)/{$(subst $(space),$(comma),$(sections))}_*.yml
	rm -f $(staging_dir)/{$(subst $(space),$(comma),$(sections))}_*.qmd
	rm -f $(staging_dir)/{$(subst $(space),$(comma),$(sections))}_*.tmp
	rm -f $(staging_dir)/{index.qmd,_quarto.yml}
	rm -f slurm-$(notdir $(CURDIR))*.out


MAKEFLAGS += --no-builtin-rules
