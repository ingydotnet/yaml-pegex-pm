#!/bin/bash

set -e

for file in test/yaml-test-suite/test/*.tml; do
  id=${file%.tml}
  id=${id##*/}
  grep "$id" test/white-list.txt &>/dev/null && continue
  echo
  echo === $id ===
  echo
  yaml=$(perl -p0e 's/.*\n\+\+\+ in-yaml\n//s;s/^\+\+\+ .*//ms'  $file)
  echo "$yaml"
done
