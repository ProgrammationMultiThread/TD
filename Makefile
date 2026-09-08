.DEFAULT_GOAL := all

# -------------------------------
# Configuration
# -------------------------------

SHELL       := bash
BUILDDIR    := build
DOCSDIR     := docs
COURSESDIR  := src/courses
ARCHIVESDIR := src/archives

# Discover courses and select the first one alphabetically by default.
COURSE_DIRS  := $(wildcard $(COURSESDIR)/*/)
ARCHIVE_DIRS := $(wildcard $(ARCHIVESDIR)/*/)

COURSES          := $(sort $(notdir $(patsubst %/,%,$(COURSE_DIRS))))
ARCHIVES         := $(sort $(notdir $(patsubst %/,%,$(ARCHIVE_DIRS))))
AVAILABLE_COURSES := $(sort $(COURSES) $(ARCHIVES))

# Persistent local selection, overridden with: make COURSE=xxx <target>
-include .current_course.mk
COURSE ?= $(or $(firstword $(COURSES)),$(firstword $(ARCHIVES)))
override COURSE := $(strip $(COURSE))

SRCDIR := $(firstword \
  $(wildcard $(COURSESDIR)/$(COURSE)) \
  $(wildcard $(ARCHIVESDIR)/$(COURSE)))

# Output directories mirror the course/document/correction structure.
COURSE_BUILDDIR     := $(BUILDDIR)/$(COURSE)
CORRECTION_BUILDDIR := $(COURSE_BUILDDIR)/correction
COURSE_DOCSDIR      := $(DOCSDIR)/$(COURSE)
CORRECTION_DOCSDIR  := $(COURSE_DOCSDIR)/correction

# LaTeX engine and number of compilation passes.
PDFLATEX ?= pdflatex
_PASSES  := 2
PDFLATEX_FLAGS := -halt-on-error -interaction=nonstopmode

# Path separator (Windows vs Unix)
ifeq ($(OS),Windows_NT)
  PATHSEP := ;
else
  PATHSEP := :
endif

# Add latex-libs to the project (local clone + TEXINPUTS)
LATEX_LIBS_DIR       := latex-libs
LATEX_LIBS_SSH_URL   := git@github.com:MatthieuPerrin/Latex-libs.git
LATEX_LIBS_HTTPS_URL := https://github.com/MatthieuPerrin/Latex-libs.git
export TEXINPUTS := $(CURDIR)/src/exercises//$(PATHSEP)$(CURDIR)/$(LATEX_LIBS_DIR)//$(PATHSEP)$(TEXINPUTS)

# -------------------------------
# Documents to generate
# -------------------------------

# Every .tex file directly inside the selected course directory is a driver.
MAIN      := $(basename $(notdir $(wildcard $(SRCDIR)/*.tex)))
MAIN_ONCE := $(MAIN:%=%-main)
CORR_ONCE := $(MAIN:%=%-correction)

MAIN_PDFS := $(MAIN:%=$(COURSE_DOCSDIR)/%.pdf)
CORR_PDFS := $(MAIN:%=$(CORRECTION_DOCSDIR)/%.pdf)

# -------------------------------
# Public targets
# -------------------------------

.PHONY: all main correction all-courses
.PHONY: configure list update clean cleanall help
.PHONY: $(MAIN) $(MAIN_ONCE) $(CORR_ONCE)

# Build every subject and correction for the selected course.
all: main correction

# Build every subject for the selected course.
main: _check-course $(MAIN_PDFS)

# Build every correction for the selected course.
correction: _check-course $(CORR_PDFS)

# Build every subject and correction for every course.
all-courses:
	@if [ -z "$(strip $(COURSES))" ]; then \
	  echo ">>> ERROR: no course found in $(COURSESDIR)"; \
	  exit 1; \
	fi
	@for course in $(COURSES); do \
	  echo ">>> Building course: $$course"; \
	  $(MAKE) --no-print-directory \
	    COURSE="$$course" \
	    all || exit $$?; \
	done

# Individual document aliases:
$(MAIN): %: $(COURSE_DOCSDIR)/%.pdf $(CORRECTION_DOCSDIR)/%.pdf

$(MAIN_ONCE): _PASSES := 1
$(MAIN_ONCE): %-main: $(COURSE_DOCSDIR)/%.pdf

$(CORR_ONCE): _PASSES := 1
$(CORR_ONCE): %-correction: $(CORRECTION_DOCSDIR)/%.pdf

# -------------------------------
# Compilation rules
# -------------------------------

# Subject
$(COURSE_DOCSDIR)/%.pdf: $(SRCDIR)/%.tex _force | _check-course _directories _deps
	$(PDFLATEX) $(PDFLATEX_FLAGS) \
	  -output-directory="$(COURSE_BUILDDIR)" \
	  -jobname="$*" \
	  "$<"
	@if [ "$(_PASSES)" -eq 2 ]; then \
	  $(PDFLATEX) $(PDFLATEX_FLAGS) \
	    -output-directory="$(COURSE_BUILDDIR)" \
	    -jobname="$*" \
	    "$<" || exit $$?; \
	fi
	@mv -f "$(COURSE_BUILDDIR)/$*.pdf" "$@"

# Correction
$(CORRECTION_DOCSDIR)/%.pdf: $(SRCDIR)/%.tex _force | _check-course _directories _deps
	@printf '\\PassOptionsToClass{correction}{td}\\input{%s}\n' \
	  "$(SRCDIR)/$*.tex" \
	  > "$(CORRECTION_BUILDDIR)/$*.tex"
	$(PDFLATEX) $(PDFLATEX_FLAGS) \
	  -output-directory="$(CORRECTION_BUILDDIR)" \
	  -jobname="$*" \
	  "$(CORRECTION_BUILDDIR)/$*.tex"
	@if [ "$(_PASSES)" -eq 2 ]; then \
	  $(PDFLATEX) $(PDFLATEX_FLAGS) \
	    -output-directory="$(CORRECTION_BUILDDIR)" \
	    -jobname="$*" \
	    "$(CORRECTION_BUILDDIR)/$*.tex" || exit $$?; \
	fi
	@mv -f "$(CORRECTION_BUILDDIR)/$*.pdf" "$@"

# -------------------------------
# Internal targets
# -------------------------------

.PHONY: _check-course _directories _deps _force

_check-course:
	@if [ -z "$(COURSE)" ] || [ ! -d "$(SRCDIR)" ]; then \
	  echo ">>> ERROR: course '$(COURSE)' not found"; \
	  echo ">>> Use 'make list' or 'make configure COURSE=<name>'."; \
	  exit 1; \
	fi
	@if ! compgen -G "$(SRCDIR)/*.tex" >/dev/null; then \
	  echo ">>> ERROR: no .tex driver found in $(SRCDIR)"; \
	  exit 1; \
	fi

_directories:
	@mkdir -p \
	  "$(COURSE_BUILDDIR)" \
	  "$(CORRECTION_BUILDDIR)" \
	  "$(COURSE_DOCSDIR)" \
	  "$(CORRECTION_DOCSDIR)"

# Ensure that the local latex-libs clone exists.
_deps:
	@if [ ! -d "$(LATEX_LIBS_DIR)/.git" ]; then \
	  echo ">>> Cloning latex-libs into $(LATEX_LIBS_DIR)"; \
	  git clone --depth 1 \
	    "$(LATEX_LIBS_SSH_URL)" \
	    "$(LATEX_LIBS_DIR)" 2>/dev/null \
	  || git clone --depth 1 \
	    "$(LATEX_LIBS_HTTPS_URL)" \
	    "$(LATEX_LIBS_DIR)"; \
	fi

# Force compilation because Make does not track files included by LaTeX.
_force:

# -------------------------------
# Course selection
# -------------------------------

# Usage: make configure COURSE=lea
configure:
	@c=$$(printf '%s' "$(COURSE)" | tr '[:upper:]' '[:lower:]'); \
	src="$(COURSESDIR)/$$c"; \
	if [ ! -d "$$src" ]; then src="$(ARCHIVESDIR)/$$c"; fi; \
	if [ ! -d "$$src" ]; then \
	  echo ">>> ERROR: course '$$c' not found"; \
	  echo ">>> Use 'make list' to list available courses."; \
	  exit 1; \
	fi; \
	if ! compgen -G "$$src/*.tex" >/dev/null; then \
	  echo ">>> ERROR: no .tex driver found in $$src"; \
	  exit 1; \
	fi; \
	printf 'COURSE := %s\n' "$$c" > .current_course.mk; \
	echo ">>> Current course: $$c"

# List available courses and their document drivers.
list:
	@if [ -z "$(strip $(AVAILABLE_COURSES))" ]; then \
	  echo "Available courses:"; \
	  echo "   (none)"; \
	  exit 0; \
	fi; \
	echo "Current courses:"; \
	if [ -z "$(strip $(COURSES))" ]; then echo "   (none)"; fi; \
	for d in $(COURSE_DIRS); do \
	  course=$${d%/}; \
	  course=$${course##*/}; \
	  if [ "$$course" = "$(COURSE)" ]; then \
	    printf " * %s (current)\n" "$$course"; \
	  else \
	    printf " - %s\n" "$$course"; \
	  fi; \
	  for f in "$$d"*.tex; do \
	    [ -e "$$f" ] || continue; \
	    name=$${f##*/}; \
	    printf "     %s\n" "$${name%.tex}"; \
	  done; \
	done; \
	echo "Archived courses:"; \
	if [ -z "$(strip $(ARCHIVES))" ]; then echo "   (none)"; fi; \
	for d in $(ARCHIVE_DIRS); do \
	  course=$${d%/}; \
	  course=$${course##*/}; \
	  if [ "$$course" = "$(COURSE)" ]; then \
	    printf " * %s (current)\n" "$$course"; \
	  else \
	    printf " - %s\n" "$$course"; \
	  fi; \
	  for f in "$$d"*.tex; do \
	    [ -e "$$f" ] || continue; \
	    name=$${f##*/}; \
	    printf "     %s\n" "$${name%.tex}"; \
	  done; \
	done

# -------------------------------
# Updates and cleaning
# -------------------------------

update:
	@echo ">>> Updating main repository"; \
	git pull --ff-only \
	  || echo ">>> Skipping main repository update (offline or non-fast-forward)."; \
	if [ -d "$(LATEX_LIBS_DIR)/.git" ]; then \
	  echo ">>> Updating $(LATEX_LIBS_DIR)"; \
	  git -C "$(LATEX_LIBS_DIR)" pull --ff-only \
	    || echo ">>> Skipping latex-libs update (offline or non-fast-forward)."; \
	else \
	  echo ">>> latex-libs not present; it will be cloned during the next build."; \
	fi

# Remove all LaTeX intermediate files for every course.
clean:
	@rm -rf "$(BUILDDIR)"
	@echo ">>> Removed build artifacts"

# Also remove generated course directories while preserving docs/.nojekyll.
cleanall: clean
	@for course in $(AVAILABLE_COURSES); do \
	  rm -rf "$(DOCSDIR)/$$course"; \
	done
	@echo ">>> Removed generated PDFs"

# -------------------------------
# Help
# -------------------------------

help:
	@echo "Usage:"
	@echo "  make | make all               – Build every subject and correction for the current course."
	@echo "  make main                     – Build every subject for the current course with two LaTeX passes."
	@echo "  make correction               – Build every correction for the current course with two LaTeX passes."
	@echo "  make all-courses              – Build every subject and correction for every current course."
	@echo "  make td                       – Build the subject and correction for td with two LaTeX passes."
	@echo "  make td-main                  – Build $(COURSE_DOCSDIR)/td.pdf with one LaTeX pass."
	@echo "  make td-correction            – Build $(CORRECTION_DOCSDIR)/td.pdf with one LaTeX pass."
	@echo "  make COURSE=<name> <target>   – Build a course without changing the persistent selection."
	@echo "  make configure COURSE=<name>  – Persistently select a current or archived course."
	@echo "  make list                     – List current and archived courses and their document drivers."
	@echo "  make update                   – Update the main repository and latex-libs."
	@echo "  make clean                    – Remove LaTeX intermediate files for every course."
	@echo "  make cleanall                 – Also remove every generated course directory from docs/."
