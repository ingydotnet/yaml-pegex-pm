use strict; use warnings; no warnings 'once';
use lib 'inc';
# use lib '../pegex-pm/lib';
# use lib '../testml-pm/lib';

use TestML;
use TestML::Compiler::Lite;
$TestML::Compiler::Lite::point_marker = '\+\+\+';

# Try next:
# 57H4 - Various block tags
# 6JWB - Various block tags
# 93JH - Simple block seq of map
# 9U5K - Simple block seq of map
# AZW3 - Simple block seq of map
# G4RS - Unicode and other escapes
# J7PZ - Map in seq with top level tag
# JQ4R - Map in seq in map
# KZN9 - Seq of flow seq with interesting values
# L9U5 - Flow seq with pair
# NP9H - \$ in double quoted string
# P2AD - Seq of folded and literal
# QF4Y - Pair in flow seq
# RR7F - Simple ? explicit key
# UGM3 - Invoice example
# UT92 - Empty documents

# Categories of unsolved problems:
# - empty keys and values
# - empty documents
# - map in seq
# - folded scalars
# - multiline plain scalars
# - explicit key '?'
# - directives %TAG and %YAML
# - prefixed block scalar keys
# - block collection keys
# - flow seq with pairs
# - flow map with singles

# Test commands:
# :wa|!make test
# :wa|!make unit DEBUG=1 ONLY=27NA
# :wa|!make compile
# :wa|!make list
# :wa|!make list-all

$main::DEBUG = $ENV{DEBUG} // 0;
$main::MAX = $ENV{MAX} // $main::DEBUG ? 1000 : 0;
$ENV{ONLY} ||= '';

my @tests = ();
my $name_id_map = {};
if ($ENV{ONLY}) {
    @tests = ($ENV{ONLY});
}
else {
    open my $fh, '<', 'test/white-list.txt' or die;
    while ($_ = <$fh>) {
        chomp;
        length or last;
        next if /^#/;
        push @tests, $_;
    }
}

for my $id (@tests) {
    open my $tml, "test/yaml-test-suite/test/$id.tml" or die;
    my $name = <$tml>;
    chomp $name;
    $name =~ s/^=== // or die;
    $name_id_map->{$name} = $id;
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

__DATA__

%TestML 0.1.0
Diff = 1
Label = 'YAML to Events - $BlockLabel'

*in-yaml.parse == *test-event.normalize

