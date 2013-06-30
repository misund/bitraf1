TARGETS:=$(shell git submodule --quiet foreach echo packages/'$$name-$$sha1'.zip)

all: $(TARGETS)

list-targets:
	@for t in $(TARGETS); do echo $$t; done

$(TARGETS):
	@env -i ./package.sh $@ packages
