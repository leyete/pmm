SHELL		?= sh
PREFIX		?= /usr/local

PROJECT		?= $(CURDIR)
BIN			?= ${PROJECT}/bin
LIB			?= ${PROJECT}/lib

TARGET		?= ${BIN}/pmm
GLOB		?= $(filter-out ${LIB}/main.zsh,$(sort $(wildcard ${LIB}/*.zsh)))
GLOB		+= $(sort $(wildcard ${LIB}/operations/*.zsh))
GLOB		+= ${LIB}/main.zsh

HEADER		= \#!/usr/bin/env zsh
FOOTER		= \# vim: ft=zsh foldenable fdm=marker foldmarker=[[[,]]] et fenc=utf-8
BANNER		= \#                   ____  ____ ___  ____ ___ \n$\
\#                  / __ \/ __ \`__ \/ __ \`__ \ \n$\
\#                 / /_/ / / / / / / / / / / /\n$\
\#                / .___/_/ /_/ /_/_/ /_/ /_/ \n$\
\#               /_/                          \n$\
\#\n$\
\#                 Personal Module Manager\n$\
\#\n$\
\# Tool for deploying and managing different environments and tools\n$\
\# (as modules) like a package manager.\n$\
\#\n$\
\# Author: leyeT.\n$\
\# License: WTFPL.\n$\

VERSION			?= dev
VERSION_FILE	= ${PROJECT}/VERSION

WITH_DEBUG		?= false

define ised
	sed $(1) $(2) > "$(2).tmp"
	mv "$(2).tmp" "$(2)"
endef

.PHONY: build install all clean install-deps

build:
	@echo :: Building Personal Module Manager...
	@printf "${HEADER}\n" > ${TARGET}
	@printf "${BANNER}\n" >> ${TARGET}
	@for src in ${GLOB}; do printf ":: --> $$(basename $$src)\n"; cat "$$src" >> ${TARGET}; printf "\n" >> ${TARGET}; done
	@printf "${FOOTER}" >> ${TARGET}
	@echo "${VERSION}" > ${VERSION_FILE}
	@$(call ised,"s/{{__PMM_WITH_DEBUG__}}/${WITH_DEBUG}/",${TARGET})
	@$(call ised,"s/{{__PMM_VERSION__}}/$$(cat ${VERSION_FILE})/",${TARGET}) 
	@$(call ised,"s/{{__PMM_REVISION__}}/$$(git log -n1 --format=%h -- lib)/",${TARGET})
	@$(call ised,"s/{{__PMM_REVISION_DATE__}}/$$(git log -n1 --format='%ai' -- lib)/",${TARGET})
	@echo :: Done.

install:
	mkdir -p ${PREFIX}/bin && cp ${TARGET} ${PREFIX}/bin/pmm && chmod +x ${PREFIX}/bin/pmm

clean:
	rm -f ${PREFIX}/bin/pmm

all: clean build install
