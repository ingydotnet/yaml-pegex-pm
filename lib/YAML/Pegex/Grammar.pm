use strict; use warnings;
package YAML::Pegex::Grammar;
our $VERSION = '0.0.17';

use Pegex::Base;
extends 'Pegex::Grammar';

use constant file => './share/yaml-pgx/yaml.pgx';

has indent => [-1];

my $EOL = qr/\r?\n/;
my $EOD = qr/(?:$EOL)?(?=\z|\.\.\.\r?\n|\-\-\-\r?\n)/;
my $SPACE = qr/ /;
my $DASH = qr/\-/;
my $DASHSPACE = qr/(?=$DASH\s)/;
my $NONSPACE = qr/(?=[^\s\#])/;
my $NOTHING = qr//;

sub rule_block_indent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indent = $self->{indent};
    pos($$buffer) = $pos;
    my $count = $indent->[-1] + 1;
    $$buffer =~ /\G(?:\A|$EOL)(${SPACE}{$count,})$NONSPACE/g or return;
    push @$indent, length($1);
    return $parser->match_rule($pos);
}

sub rule_block_ondent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indent = $self->{indent};
    my $count = $indent->[-1];
    my $RE = $pos > 0 ? $EOL : $NOTHING;
    pos($$buffer) = $pos;
    $$buffer =~ /\G$RE(${SPACE}{$count})$NONSPACE/g or return;
    return $parser->match_rule(pos($$buffer));
}

sub rule_block_undent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indent = $self->{indent};
    return unless @$indent;
    my $count = $indent->[-1];
    pos($$buffer) = $pos;
    return unless $$buffer =~ /\G$EOD|(?!$EOL {$count})/g;
    pop @$indent;
    return $parser->match_rule($pos);
}

sub rule_block_sequence_indent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indent = $self->{indent};
    pos($$buffer) = $pos;
    my $count = $indent->[-1];
    $count++ unless $parser->{receiver}{kind}[-1] eq 'mapping';
    $$buffer =~ /\G(?:\A|$EOL)(${SPACE}{$count,})$DASHSPACE/g or return;
    push @$indent, length($1);
    return $parser->match_rule($pos);
}

sub rule_block_sequence_ondent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indent = $self->{indent};
    my $count = $indent->[-1];
    my $RE = $pos > 0 ? $EOL : $NOTHING;
    pos($$buffer) = $pos;
    $$buffer =~ /\G$RE(${SPACE}{$count})$DASHSPACE/g or return;
    return $parser->match_rule(pos($$buffer));
}

sub rule_folded_scalar {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indent = $self->{indent}[-1] + 1;
    my $chomp = 0;
    my $keep = 0;
    pos($$buffer) = $pos;
    $$buffer =~ /\G\>([-+]?)?$EOL/g or return;
    my $ind = $1;
    $chomp = 1 if $ind =~ /\-/;
    $keep = 1 if $ind =~ /\+/;
    $pos = pos($$buffer);
    my $value = '';
    my $pad = 0;
    while ($$buffer =~ /\G(?:\ {$indent}|\ *(?=\n))(.*\n)/g) {
        my $line = " $1";
        if (not $pad) {
            if ($line =~ s/^(\ +)(?=[^\ \n])//) {
                $pad = length $1;
            }
            else {
                $line = "\n";
            }
        }
        elsif ($line !~ s/^\ {$pad}//) {
            last if $line =~ /[^\ \n]/;
            $line = "\n";
        }
        $value .= $line;
        $pos = pos($$buffer);
    }

    # my $debug = $value;
    # $debug =~ s/ /_/g;
    # warn ">>\n$debug<<";

    # Reformat folded value:
    $value =~ s/^(?=[^\ \n\t])(.+)\n(?=[^\ \n])/$1 /mg;
    $value =~ s{^(?=[^\ \n\t])(.+)\n(\n+)(?=[^\ \n\t])}
               {$1 . ("\n" x length($2))}meg;

    if (not $keep) {
        $value =~ s/\n+\z/\n/;
        chomp $value if $chomp or $value eq "\n";
    }
    $parser->match_rule(--$pos, [$value]);
}

sub rule_literal_scalar {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indent = $self->{indent}[-1] + 1;
    my $pad = 0;
    my $chomp = 0;
    my $keep = 0;
    pos($$buffer) = $pos;
    $$buffer =~ /\G\|(\d*[-+]?)?$EOL/g or return;
    my $ind = $1;
    $pad = $1 if $ind =~ /(\d+)/;
    $chomp = 1 if $ind =~ /\-/;
    $keep = 1 if $ind =~ /\+/;
    $pos = pos($$buffer);
    my $value = '';
    while ($$buffer =~ /\G(?:\ {$indent}|\ *(?=\n))(.*\n)/g) {
        my $line = " $1";
        if (not $pad) {
            $line =~ s/^(\ +)(?=\S)//
                ? ($pad = length $1)
                : ($line = "\n");
        }
        elsif ($line !~ s/^\ {$pad}//) {
            last if $line =~ /\S/;
            $line = "\n";
        }
        $value .= $line;
        $pos = pos($$buffer);
    }
    if (not $keep) {
        $value =~ s/\n+\z/\n/;
        chomp $value if $chomp or $value eq "\n";
    }
    $parser->match_rule(--$pos, [$value]);
}

# Set YAML_PEGEX_DEV=1 to make grammar compile every time
sub make_tree_dynamic {
    use Pegex::Bootstrap;
    use IO::All;
    my $grammar = io->file(file)->all;
    Pegex::Bootstrap->new->compile($grammar)->tree;
}

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.61)
  {
    '+grammar' => 'yaml',
    '+toprule' => 'yaml_stream',
    '+version' => '0.0.1',
    'EOL' => {
      '.rgx' => qr/\G\r?\n/
    },
    'block_key' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'yaml_prefix'
        },
        {
          '.ref' => 'block_key_scalar'
        },
        {
          '.ref' => 'pair_separator'
        }
      ]
    },
    'block_key_scalar' => {
      '.rgx' => qr/\G(?![&\*\{\}\[\]%"'`\@\#])(.+?)(?:\s+[\ \t]*\#.*)?(?=:\s|\r?\n|\z)/
    },
    'block_mapping' => {
      '.all' => [
        {
          '.ref' => 'block_indent'
        },
        {
          '.all' => [
            {
              '.ref' => 'block_pair'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'ignore_lines'
                },
                {
                  '.ref' => 'block_pair'
                }
              ]
            },
            {
              '+max' => 1,
              '.ref' => 'ignore_lines'
            }
          ]
        },
        {
          '.ref' => 'block_undent'
        }
      ]
    },
    'block_node' => {
      '.any' => [
        {
          '.all' => [
            {
              '+max' => 1,
              '.ref' => 'block_prefix'
            },
            {
              '.any' => [
                {
                  '.ref' => 'block_sequence'
                },
                {
                  '.ref' => 'block_mapping'
                }
              ]
            }
          ]
        },
        {
          '.all' => [
            {
              '+max' => 1,
              '.ref' => 'EOL'
            },
            {
              '+max' => 1,
              '.ref' => 'yaml_prefix'
            },
            {
              '.ref' => 'block_scalar'
            }
          ]
        }
      ]
    },
    'block_pair' => {
      '.all' => [
        {
          '.ref' => 'block_ondent'
        },
        {
          '.ref' => 'block_key'
        },
        {
          '.ref' => 'yaml_node'
        }
      ]
    },
    'block_plain_scalar' => {
      '.rgx' => qr/\G(?![&\*\{\}\[\]%"'`\@\#])(.+?)(?:\s+[\ \t]*\#.*)?(?=:\s|\r?\n|\z)/
    },
    'block_prefix' => {
      '.all' => [
        {
          '.ref' => 'yaml_prefix'
        },
        {
          '.rgx' => qr/\G(?=\r?\n)/
        }
      ]
    },
    'block_scalar' => {
      '.any' => [
        {
          '.ref' => 'literal_scalar'
        },
        {
          '.ref' => 'folded_scalar'
        },
        {
          '.ref' => 'double_quoted_scalar'
        },
        {
          '.ref' => 'single_quoted_scalar'
        },
        {
          '.ref' => 'block_plain_scalar'
        }
      ]
    },
    'block_sequence' => {
      '.all' => [
        {
          '.ref' => 'block_sequence_indent'
        },
        {
          '+min' => 1,
          '.ref' => 'block_sequence_entry'
        },
        {
          '.ref' => 'block_undent'
        }
      ]
    },
    'block_sequence_entry' => {
      '.all' => [
        {
          '.ref' => 'block_sequence_ondent'
        },
        {
          '.ref' => 'block_sequence_marker'
        },
        {
          '.ref' => 'yaml_node'
        }
      ]
    },
    'block_sequence_marker' => {
      '.rgx' => qr/\G\-(?:\ +|(?=\r?\n))/
    },
    'directive_tag' => {
      '.rgx' => qr/\G\r?\n?%TAG\ +!(.*)!\ +(\S+)\ *(?=\r?\n)/
    },
    'document_end' => {
      '.rgx' => qr/\G/
    },
    'document_foot' => {
      '.rgx' => qr/\G\.\.\.\r?\n/
    },
    'document_head' => {
      '.rgx' => qr/\G\r?\n?\-\-\-(?:(?:[\ \t]*\#.*|[\ \t]*(?=\r?\n))|\ +|(?=\r?\n))/
    },
    'document_start' => {
      '.rgx' => qr/\G(?=[\s\S]*[^\r?\n])/
    },
    'double_quoted_scalar' => {
      '.rgx' => qr/\G"((?:\\"|[^"])*)"/
    },
    'flow_collection' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'yaml_prefix'
        },
        {
          '.any' => [
            {
              '.ref' => 'flow_sequence'
            },
            {
              '.ref' => 'flow_mapping'
            }
          ]
        }
      ]
    },
    'flow_mapping' => {
      '.all' => [
        {
          '.ref' => 'flow_mapping_start'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'flow_mapping_pair'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'list_separator'
                },
                {
                  '.ref' => 'flow_mapping_pair'
                }
              ]
            },
            {
              '+max' => 1,
              '.ref' => 'list_separator'
            }
          ]
        },
        {
          '.ref' => 'flow_mapping_end'
        }
      ]
    },
    'flow_mapping_end' => {
      '.rgx' => qr/\G\s*\}\ */
    },
    'flow_mapping_pair' => {
      '.all' => [
        {
          '.any' => [
            {
              '.all' => [
                {
                  '.ref' => 'double_quoted_scalar'
                },
                {
                  '.ref' => 'pair_separator_json'
                }
              ]
            },
            {
              '.all' => [
                {
                  '.ref' => 'flow_node'
                },
                {
                  '.ref' => 'pair_separator'
                }
              ]
            }
          ]
        },
        {
          '.ref' => 'flow_node'
        }
      ]
    },
    'flow_mapping_start' => {
      '.rgx' => qr/\G\{\s*/
    },
    'flow_node' => {
      '.any' => [
        {
          '.ref' => 'yaml_alias'
        },
        {
          '.all' => [
            {
              '+max' => 1,
              '.ref' => 'yaml_prefix'
            },
            {
              '.any' => [
                {
                  '.ref' => 'flow_sequence'
                },
                {
                  '.ref' => 'flow_mapping'
                },
                {
                  '.ref' => 'flow_scalar'
                }
              ]
            }
          ]
        }
      ]
    },
    'flow_plain_scalar' => {
      '.rgx' => qr/\G(?![&\*\{\}\[\]%"'`\@\#])(.*?)(?=[&\*\{\}\[\]%"',]|:\ |,\ |\r?\n|\z)/
    },
    'flow_scalar' => {
      '.any' => [
        {
          '.ref' => 'double_quoted_scalar'
        },
        {
          '.ref' => 'single_quoted_scalar'
        },
        {
          '.ref' => 'flow_plain_scalar'
        }
      ]
    },
    'flow_sequence' => {
      '.all' => [
        {
          '.ref' => 'flow_sequence_start'
        },
        {
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'flow_node'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'list_separator'
                },
                {
                  '.ref' => 'flow_node'
                }
              ]
            },
            {
              '+max' => 1,
              '.ref' => 'list_separator'
            }
          ]
        },
        {
          '.ref' => 'flow_sequence_end'
        }
      ]
    },
    'flow_sequence_end' => {
      '.rgx' => qr/\G\s*\]\ */
    },
    'flow_sequence_start' => {
      '.rgx' => qr/\G\[\s*/
    },
    'ignore_lines' => {
      '.rgx' => qr/\G(?:(?:[\ \t]*\#.*|[\ \t]*(?=\r?\n))(?:\r?\n(?:[\ \t]*\#.*|[\ \t]*(?=\r?\n)))*)?/
    },
    'list_separator' => {
      '.rgx' => qr/\G\s*,\s*/
    },
    'pair_separator' => {
      '.rgx' => qr/\G\s*:(?:\ +|\ *(?=\r?\n))/
    },
    'pair_separator_json' => {
      '.rgx' => qr/\G\s*:\ */
    },
    'single_quoted_scalar' => {
      '.rgx' => qr/\G'((?:''|[^'])*)'/
    },
    'stream_end' => {
      '.rgx' => qr/\G\r?\n?/
    },
    'stream_start' => {
      '.rgx' => qr/\G/
    },
    'yaml_alias' => {
      '.rgx' => qr/\G\*(\w+)/
    },
    'yaml_anchor' => {
      '.rgx' => qr/\G\&(\w+)\s*/
    },
    'yaml_document' => {
      '.all' => [
        {
          '+min' => 0,
          '.ref' => 'directive_tag'
        },
        {
          '.any' => [
            {
              '.ref' => 'document_head'
            },
            {
              '.ref' => 'document_start'
            }
          ]
        },
        {
          '.ref' => 'yaml_node'
        },
        {
          '+max' => 1,
          '.ref' => 'EOL'
        },
        {
          '.ref' => 'ignore_lines'
        },
        {
          '.any' => [
            {
              '.ref' => 'document_foot'
            },
            {
              '.ref' => 'document_end'
            }
          ]
        }
      ]
    },
    'yaml_node' => {
      '.any' => [
        {
          '.ref' => 'yaml_alias'
        },
        {
          '.ref' => 'flow_collection'
        },
        {
          '.ref' => 'block_node'
        }
      ]
    },
    'yaml_prefix' => {
      '.any' => [
        {
          '.all' => [
            {
              '.ref' => 'yaml_anchor'
            },
            {
              '+max' => 1,
              '.ref' => 'yaml_tag'
            }
          ]
        },
        {
          '.all' => [
            {
              '.ref' => 'yaml_tag'
            },
            {
              '+max' => 1,
              '.ref' => 'yaml_anchor'
            }
          ]
        }
      ]
    },
    'yaml_stream' => {
      '.all' => [
        {
          '.ref' => 'stream_start'
        },
        {
          '.ref' => 'ignore_lines'
        },
        {
          '+min' => 0,
          '.ref' => 'yaml_document'
        },
        {
          '.ref' => 'stream_end'
        }
      ]
    },
    'yaml_tag' => {
      '.rgx' => qr/\G(\!\S*)\s*/
    }
  }
}

{
    no warnings 'redefine';
    *make_tree = \&make_tree_dynamic if $ENV{YAML_PEGEX_DEV};
}

1;
