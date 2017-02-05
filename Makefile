# This Makefile is for running the tests. It clones the test suite at the
# preferred commit, and runs the tests. The test suite can be more permanent
# once things mature. ie Make it a suprepo. At that point this Makefile can go
# away.

TEST_SUITE_COMMIT ?= 8a19f3c45b88675601c6379332a7b7989cdeb35a
DEBUG ?= 0
ONLY ?= XXXX

.PHONY: test
test: test/yaml-test-suite
	time prove -lv test/

unit:
	YAML_PEGEX_DEV=1 DEBUG=$(DEBUG) prove -lv test/test.t 2>&1 | less -FRX

compile:
	perl -Ilib -MYAML::Pegex::Grammar=compile

list: test/yaml-test-suite
	./test/list-tests.sh

list-all: test/yaml-test-suite
	./test/list-tests.sh all

test/yaml-test-suite:
	git clone git@github.com:yaml/yaml-test-suite $@
	(cd $@; git reset --hard $(TEST_SUITE_COMMIT))

clean:
	rm -fr test/yaml-test-suite
