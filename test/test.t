use strict; use warnings; no warnings 'once';
use lib 'inc';
use lib '../pegex-pm/lib';
use lib '../testml-pm/lib';

use TestML;
use TestML::Compiler::Lite;
$TestML::Compiler::Lite::point_marker = '\+\+\+';

# Try next:
# MZX3 J9HZ 93JH 9U5K 5C5M 5BVJ 229Q 5NYZ 6JQW 77H8 H2RW UT92

$main::MAX = $ENV{MAX} // 0;
$main::DEBUG = $ENV{DEBUG} // 0;
$ENV{ONLY} ||= '';

my @tests = ();
if ($ENV{ONLY}) {
    @tests = ($ENV{ONLY});
}
else {
    open my $fh, '<', 'test/white-list.txt';
    @tests = map { chomp; $_ } <$fh>;
}

my $testml = join '', <DATA>, map
    "%Include yaml-test-suite/test/$_.tml\n",
    @tests;

TestML->new(
    testml => $testml,
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

__DATA__

%TestML 0.1.0
Diff = 1
Label = 'YAML to Events - $BlockLabel'

*in-yaml.parse == *test-event

# Try next:
# Simple seq of maps
# %Include yaml-test-suite/test/93JH.tml
# %Include yaml-test-suite/test/9U5K.tml
# Simple sequence of flow maps
# %Include yaml-test-suite/test/5C5M.tml
# = Simple literal and folded
# %Include yaml-test-suite/test/5BVJ.tml
# = Indentation seq of maps
# %Include yaml-test-suite/test/229Q.tml
# - Mapping scalar on next line
# %Include yaml-test-suite/test/5NYZ.tml

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
