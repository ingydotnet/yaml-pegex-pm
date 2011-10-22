##
# name:      Pegex::YAML::Grammar
# abstract:  Pegex Grammar Parser for YAML
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011

package Pegex::YAML::Grammar;
use Mo;
extends 'Pegex::Grammar';

use constant text => '../yaml-pgx/yaml.pgx';

sub tree {
}

1;
