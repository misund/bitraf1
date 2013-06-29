TARGETS:=$(shell git submodule --quiet  foreach  echo packages/'$$name-$$sha1'.zip)

all: $(TARGETS)

$(TARGETS):
	@env -i ./package.sh $@ packages
