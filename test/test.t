use strict; use warnings; no warnings 'once';
use lib 'inc';
# use lib '../pegex-pm/lib';
# use lib '../testml-pm/lib';

use TestML;
use TestML::Compiler::Lite;
$TestML::Compiler::Lite::point_marker = '\+\+\+';

### Handy make/test commands:
# :wa|!YAML_PEGEX_DEV=1 make test
# :wa|!make unit DEBUG=1 ONLY=27NA
# :wa|!make compile
# :wa|!make list
# :wa|!make list-all

$main::DEBUG = $ENV{DEBUG} // 0;
$main::MAX = $ENV{MAX} // $main::DEBUG ? 1000 : 0;
$ENV{ONLY} ||= '';

my @tests = ();
my $name_id_map = {};
my $testml = '';
if ($ENV{ONLY}) {
    @tests = ($ENV{ONLY});
    open my $tml, '<', 'test/only.tml' or die;
    $testml = do { local $/; <$tml> };
    $testml =~ s/XXXX/$ENV{ONLY}/ or die;
}
else {
    open my $tml, '<', 'test/all.tml' or die;
    while ($_ = <$tml>) {
        $testml .= $_;
        next unless /^%Include yaml-test-suite\/test\/([A-Z2-9]{4})\.tml$/;
        push @tests, $1;
    }
}

for my $id (@tests) {
    open my $tml, "test/yaml-test-suite/test/$id.tml" or die;
    my $name = <$tml>;
    chomp $name;
    $name =~ s/^=== // or die;
    $name_id_map->{$name} = $id;
}

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
        # Hack to get test id in label:
        my $id;
        {
            my $name = $self->runtime->{function}{namespace}{Block}{label};
            $id = $name_id_map->{$name};
            $self->runtime->{function}{namespace}{Label}{value} = "($id) $name";
        }
        $YAML::DumpCode = 1;
        $yaml = $yaml->{value};
        $yaml =~ s/<SPC>/ /g;
        $yaml =~ s/<TAB>/\t/g;
        $yaml =~ s/<NEL>\n\z//;
        my $parser = Pegex::Parser->new(
            grammar => 'YAML::Pegex::Grammar'->new,
            receiver => 'YAML::Pegex::Receiver::Test'->new,
            debug => $main::DEBUG,
            maxparse => $main::MAX,
        );
        # use XXX; XXX($parser->grammar->tree->{ws});

        my $events;
        eval {
            $events = $parser->parse($yaml);
        } || die "$id parse failure:\n$@";

        str join '', map { "$_\n" } @$events;
    }

    sub normalize {
        my ($self, $want) = @_;
        $want = $want->{value};
        $want =~ s/<SPC>/ /g;
        $want =~ s/<TAB>/\t/g;
        str $want;
    }
}
