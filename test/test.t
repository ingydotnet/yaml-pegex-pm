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
            # debug => 1,
            # maxparse => 70,
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

# %Include yaml-dev-kit/test/name/blank-lines.tml
%Include yaml-dev-kit/test/name/block-submapping.tml
%Include yaml-dev-kit/test/name/document-with-footer.tml
%Include yaml-dev-kit/test/name/empty-stream.tml
# %Include yaml-dev-kit/test/name/example-3-23-various-explicit-tags.tml
%Include yaml-dev-kit/test/name/flow-mapping.tml
%Include yaml-dev-kit/test/name/flow-sequence.tml
%Include yaml-dev-kit/test/name/multi-level-mapping-indent.tml
%Include yaml-dev-kit/test/name/multiple-entry-block-sequence.tml
%Include yaml-dev-kit/test/name/multiple-pair-block-mapping.tml
# %Include yaml-dev-kit/test/name/sequence-indent.tml
%Include yaml-dev-kit/test/name/simple-mapping-indent.tml
%Include yaml-dev-kit/test/name/single-entry-block-sequence.tml
%Include yaml-dev-kit/test/name/single-pair-block-mapping.tml
%Include yaml-dev-kit/test/name/spec-example-2-1-sequence-of-scalars.tml
# %Include yaml-dev-kit/test/name/spec-example-2-13-in-literals-newlines-are-preserved.tml
# %Include yaml-dev-kit/test/name/spec-example-2-2-mapping-scalars-to-scalars.tml
# %Include yaml-dev-kit/test/name/spec-example-2-3-mapping-scalars-to-sequences.tml
