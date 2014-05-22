##
# name:      Pegex::YAML
# abstract:  Pegex Grammar Parser for YAML
# author:    Ingy döt Net <ingy@cpan.org>
# license:   perl
# copyright: 2011
# see:
# - Pegex

use 5.010;

use Pegex 0.18 ();

package Pegex::YAML;
use Pegex::Mo;
extends 'Pegex::Module';

our $VERSION = '0.10';

use constant receiver => 'Pegex::YAML::AST';

1;

=head1 SYNOPSIS

    my $data = Pegex::YAML->parse($input);

=head1 DESCRIPTION

Pegex::YAML is a YAML parser written in Pegex.
