use lib 'inc';
use lib '../pegex-pm/lib';
use lib '../testml-pm/lib';

use TestML;
use TestML::Compiler::Lite;

TestML->new(
    testml => join('', <DATA>),
    bridge => 'main',
    compiler => 'TestML::Compiler::Lite',
)->run;

use base 'TestML::Bridge';
use TestML::Util;
use Pegex::Parser;
use YAML::Pegex::Grammar;
use YAML::Pegex::Receiver::Test;

sub parse {
    my ($self, $yaml) = @_;
    $YAML::DumpCode = 1;
    $yaml = $yaml->{value};
    my $parser = Pegex::Parser->new(
        grammar => 'YAML::Pegex::Grammar'->new,
        receiver => 'YAML::Pegex::Receiver::Test'->new,
        # debug => 1,
        # maxparse => 70,
    );
    # use XXX; XXX($parser->grammar->tree);
    str $parser->parse($yaml);
}

__DATA__

%TestML 0.1.0

Diff = 1

Label = 'YAML to Events - $BlockLabel'
*yaml.parse == *events

%Include mapping.tml
%Include sequence.tml
%Include indent.tml
%Include footer.tml
%Include misc.tml
