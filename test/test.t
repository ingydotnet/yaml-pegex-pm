use lib 'inc';
use lib '../pegex-pm/lib';
use lib '../testml-pm/lib';

use TestML;

TestML->new(
    testml => join('', <DATA>),
    bridge => 'main',
)->run;

use base 'TestML::Bridge';
use TestML::Util;
use YAML::Pegex::Grammar;
use YAML::Pegex::AST;

sub parse {
    my ($self, $yaml) = @_;
    # local $ENV{PERL_PEGEX_DEBUG} = 1;
    $yaml = $yaml->{value};
    my $parser = Pegex::Parser->new(
        grammar => 'YAML::Pegex::Grammar'->new,
        receiver => "YAML::Pegex::AST"->new,
        # debug => 1,
    );
    # use XXX; XXX($parser->grammar->tree);
    str $parser->parse($yaml);
}

__DATA__

%TestML 0.1.0

# Diff = 1

Label = 'YAML to Events - $BlockLabel'
*yaml.parse == *events

%Include mapping.tml
