#!/bin/bash

set -e

for file in test/yaml-test-suite/test/*.tml; do
  id=${file%.tml}
  id=${id##*/}
  if [[ $1 != all ]]; then
    grep "$id" test/white-list.txt &>/dev/null && continue
  fi
  echo
  echo === $id ===
  echo
  yaml=$(perl -p0e 's/.*\n\+\+\+ in-yaml\n//s;s/^\+\+\+ .*//ms'  $file)
  echo "$yaml"
done
