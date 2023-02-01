## Pre-processor for parametrised quarto websites

I couldn't find a
[Quarto-](https://github.com/quarto-dev/quarto-cli)native way to
generate multiple pages on a website that all stem from a common
`section.qmd` that can be parametrised in different ways. This
repository presents a `makefile` that takes a set of such common
'parent' scripts along with a correspondingly named
`section.yml`. This latter isn't quite a conformant yaml file, as it
will contain multiple 'stanzas' where identical key names (such as
`params`, or `title`) will appear across these stanzas, and true yaml
doesn't allow such duplications.

Instead, this 'multi-stanza' yml file will get pre-processed by the
makefile, chunking it up and then injecting it into its associated
`*.qmd` file.

The format of multi-stanza file is as follows:

```yml
title: Default
description: Default analysis
categories: [Default, linear]
params:
  assay: raw
  subset: true

title: "Log, no outlier"
description: Experiment with different settings 
categories: [log]
params:
  assay: log
  subset: '!is.na(outcome)'
```

This will get split up into two valid yml files, to produce two pages
in the subsequent website.  Further, the metadata (defined to be the
fields in each stanza _prior_ to the `params` field) will get injected
into the metadata section of the page, whereas the parameters (fields
within a stanza following the `params:` line) will get injected into
the parameter section.  This allows one to have other metadata, such
as 'author' in the original `qmd` file, but add others in a
page-specific manner.

The `section` name (which links `section.qmd` and `section.yml`) is
generic, one can have multiple sections, and they'll all get expanded
out, such as the toy examples
[Analysis.yml](building-blocks/Analysis.yml) and
[Down-stream.yml](building-blocks/Down-stream.yml).

In the [project makefile](project.mk) one can define other parameters
that are either global (across all sections - for example the common
path to the source data), or section specific (inherited by all pages
within a section).  The parameters will get over-ridden in the natural
manner: page-specific parameters take precedence over section specific
ones, and global ones are only taken into account if they aren't
over-ridden by either of the other two 'scopes'.

The [project makefile](project.mk) is where sections are defined -
unless you have a `sections = ...` line in that file, they won't get
picked up. In the [settings makefile](global.mk) we set various
preferences in how the scripts are read and made. Most importantly, we
have a `source_dir` where the 'parent' qmds and ymls are read from
(defaults to `./building-blocks`) and a `staging_dir` (defaults to
`./staging`) which is where all the generated files will be placed.
Also in that settings file are the various 'markers' whose presence in
the parental scripts will be as beacons as to where the parameters and
metadata must be injected.

`qmd` files in the `source_dir` directory that have no accompanying
multi-stanza yml file will be treated as singletons.  They will
inherit the parameters from the `project.mk` file that are set at
project and global scope - but they will need to provide their own
metadata.

## Installation

Simply clone this directory into a system that has (GNU) versions of
`make`, `sed` and `awk`. You'll need Quarto installed (edit [settings
makefile](global.mk) if you have a non-standard way of invoking quarto.)

## Preparation

Replace the contents of the `./building-blocks` directory with your
quarto source files, and a correspondingly named `yml` file with as
many stanzas as parameter-sets that you want the qmd exposed to.  Customise
the `project.mk` file so that all the basenames of the quarto files
are listed in the `sections=` line.  Set any other section or global
parameters in that file, as described in `project.mk` itself.

Customise the `./building-blocks/index.qmd` and
`./building-blocks/_quarto.yml` files as you see fit. They both get
modified when being moved to the staging area, to inject the
'contents', so you may need to reverse-engineer the relevant recipes
in the makefile if you change the structure substantially but want to
preserve that feature.

## Running

`make` by itself will give a mini-help page on the actual execution.
But `make scripts`, if everything is set up correctly, will generate
the staging directory, and populate it with 'expanded out' qmds that
contain the relevant parameter values in the yaml front-matter.

There's also the option to `make pages` which will individually render
those qmds into html pages.  Or `make render` which will render the
project as a whole.  The difference being that the former is
potentially parallelisable.

One can add command-line variables, so e.g. `make scripts
sections=Analysis RESULTS_DIR=v0.1` will only generate pages for that
section and a different name for the staged results directory; or you
can override 'global' scope parameters by `make render alpha=0.01` -
but in turn that will be overriden if section- or page-specific values
have been set (in the `project.mk` or multi-stanza yml file,
respectively.)

## Caveats

`make` can become quite contorted, and that is the case here. It's
probably best not to use underscores in your section names.  Also, to
keep dependencies down, it's doing very basic yaml parsing in `bash`,
so composite values of parameters might cause issues.
