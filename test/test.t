use strict; use warnings; no warnings 'once';
use lib 'inc';
use lib '../pegex-pm/lib';
use lib '../testml-pm/lib';

use TestML;
use TestML::Compiler::Lite;
$TestML::Compiler::Lite::point_marker = '\+\+\+';

# Try next:
# 3ALJ - Block seq in seq
# 57H4 - Various block tags
# 6JWB - Various block tags
# 7BUB - Block seq in map with comments and anchor/alias
# 93JH - Simple block seq of map
# 9U5K - Simple block seq of map
# AZW3 - Simple block seq of map
# G4RS - Unicode and other escapes
# J7PZ - Map in seq with top level tag
# J9HZ - Simple seq in map, but comments in a couple places
# JQ4R - Map in seq in map
# KZN9 - Seq of flow seq with interesting values
# L9U5 - Flow seq with pair
# MZX3 - Seq of various scalar styles
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
# :wa|!time prove -lv test/
# :wa|!ONLY=V55R prove -lv test/
# :wa|!DEBUG=1 MAX=0 ONLY=UT92 prove -lv test/ |& less
# :!perl -Ilib -MYAML::Pegex::Grammar=compile
# :!./test/list-tests.sh > need

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

        my $events = $parser->parse($yaml);
        # Remove unnecessary STREAM events
        if (@$events > 4) {
            shift @$events;
            pop @$events;
        }

        # Remove unnecessary DOCUMENT events
        if ($events->[0] eq '+DOC' and $events->[-1] eq '-DOC') {
            shift @$events;
            pop @$events;
        }

        str join '', map { "$_\n" } @$events;
    }
}

__DATA__

%TestML 0.1.0
Diff = 1
Label = 'YAML to Events - $BlockLabel'

*in-yaml.parse == *test-event

