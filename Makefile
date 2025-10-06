PROJECT = main
OUTDIR  = build

TEX      = lualatex
TEXFLAGS = -interaction=nonstopmode -file-line-error -synctex=1 -halt-on-error -shell-escape -output-directory=$(OUTDIR)
BIBER    = biber

SOURCES = $(wildcard *.tex) \
          $(wildcard chapters/*.tex) \
          $(wildcard tex/*.tex) \
          $(wildcard sections/*.tex) \
          $(wildcard *.bib) \
          $(wildcard bib/*.bib) \
          $(wildcard figures/*) \
          $(wildcard images/*)

OPEN    = $(shell command -v xdg-open >/dev/null 2>&1 && echo xdg-open || echo open)

.PHONY: all watch clean clobber open help test

all: $(OUTDIR)/$(PROJECT).pdf

$(OUTDIR):
	mkdir -p $(OUTDIR)

$(OUTDIR)/chapters:
	mkdir -p $@

# Ensure build/chapters exists BEFORE compiling, so \include can write chapter .aux
$(OUTDIR)/$(PROJECT).pdf: $(SOURCES) | $(OUTDIR) $(OUTDIR)/chapters
	$(TEX) $(TEXFLAGS) $(PROJECT).tex
	@if [ -f "$(OUTDIR)/$(PROJECT).bcf" ]; then (cd "$(OUTDIR)" && $(BIBER) "$(PROJECT)"); $(TEX) $(TEXFLAGS) $(PROJECT).tex; fi
	$(TEX) $(TEXFLAGS) $(PROJECT).tex

watch:
	@sh -c 'if command -v entr >/dev/null 2>&1; then printf "%s\n" $(SOURCES) | tr " " "\n" | entr -c make; elif command -v inotifywait >/dev/null 2>&1; then while inotifywait -e close_write,move,create,delete -r .; do make; done; elif command -v fswatch >/dev/null 2>&1; then fswatch -o . | while read _; do make; done; else echo "Install entr or inotify-tools or fswatch for watch"; exit 1; fi'

open: $(OUTDIR)/$(PROJECT).pdf
	@$(OPEN) "$<" >/dev/null 2>&1 || true

clean:
	@rm -f $(OUTDIR)/*.aux $(OUTDIR)/*.log $(OUTDIR)/*.toc $(OUTDIR)/*.out \
	       $(OUTDIR)/*.bbl $(OUTDIR)/*.blg $(OUTDIR)/*.bcf $(OUTDIR)/*.run.xml \
	       $(OUTDIR)/*.synctex.gz
	@rm -f $(OUTDIR)/chapters/*.aux 2>/dev/null || true

clobber: clean
	@rm -f $(OUTDIR)/$(PROJECT).pdf
	@rmdir $(OUTDIR)/chapters 2>/dev/null || true
	@rmdir $(OUTDIR) 2>/dev/null || true

help:
	@printf "Targets:\n  make        build once\n  make watch  watch & rebuild (needs entr/inotifywait/fswatch)\n  make open   open pdf\n  make clean  remove aux\n  make clobber remove aux+pdf\n  make test   quick sanity checks\n"

test:
	@$(TEX) --version >/dev/null 2>&1 || { echo "lualatex not found"; exit 1; }
	@printf "OK: lualatex present\n"

