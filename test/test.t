use lib 'inc';
use lib '../pegex-pm/lib';
use lib '../testml-pm/lib';

use TestML;
use TestML::Compiler::Lite;
$TestML::Compiler::Lite::point_marker = '\+\+\+';

TestML->new(
    testml => join('', <DATA>),
    bridge => 'Bridge',
    compiler => 'TestML::Compiler::Lite',
)->run;

{
    package Bridge;
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
            debug => $main::DEBUG,
            maxparse => $main::MAX,
        );
        # use XXX; XXX($parser->grammar->tree);
        str $parser->parse($yaml);
    }
}

BEGIN {
    $main::MAX = 0;
    $main::DEBUG = 0;
}
__DATA__

%TestML 0.1.0
Diff = 1
Label = 'YAML to Events - $BlockLabel'

*in-yaml.parse == *test-event

# Working so far:
%Include yaml-test-suite/test/54T7.tml
%Include yaml-test-suite/test/65WH.tml
%Include yaml-test-suite/test/98YD.tml
%Include yaml-test-suite/test/9FMG.tml
%Include yaml-test-suite/test/9J7A.tml
%Include yaml-test-suite/test/AVM7.tml
%Include yaml-test-suite/test/D9TU.tml
%Include yaml-test-suite/test/DHP8.tml
%Include yaml-test-suite/test/FQ7F.tml
%Include yaml-test-suite/test/J5UC.tml
%Include yaml-test-suite/test/K4SU.tml
%Include yaml-test-suite/test/KMK3.tml
%Include yaml-test-suite/test/PBJ2.tml
%Include yaml-test-suite/test/RLU9.tml
%Include yaml-test-suite/test/S4T7.tml
%Include yaml-test-suite/test/SYW4.tml

# Try next:
# = Indentation seq of maps
# %Include yaml-test-suite/test/229Q.tml

# These were attempted but not working yet:
# |  %Include yaml-test-suite/test/6JQW.tml
# hangs  %Include yaml-test-suite/test/77H8.tml
# hangs  %Include yaml-test-suite/test/H2RW.tml

# tinita has these working in another parser:
# %Include yaml-test-suite/test/2JQS.tml
# %Include yaml-test-suite/test/6FWR.tml
# %Include yaml-test-suite/test/8G76.tml
# %Include yaml-test-suite/test/96L6.tml
# %Include yaml-test-suite/test/G992.tml
# %Include yaml-test-suite/test/MYW6.tml
