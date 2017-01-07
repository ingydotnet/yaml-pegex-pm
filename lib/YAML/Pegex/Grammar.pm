use strict; use warnings;
package YAML::Pegex::Grammar;
our $VERSION = '0.0.17';

use Pegex::Base;
extends 'Pegex::Grammar';

use constant file => './share/yaml-pgx/yaml.pgx';

has indent => [];

my $EOL = qr/\r?\n/;
my $EOD = qr/(?:$EOL)?(?=\z|\.\.\.\r?\n|\-\-\-\r?\n)/;
my $SPACE = qr/ /;
my $DASH = qr/\-/;
my $DASHSPACE = qr/(?=$DASH\s)/;
my $NONSPACE = qr/(?=[^\s\#])/;
my $NOTHING = qr//;

sub rule_block_indent {
    my ($self, $parser, $buffer, $pos) = @_;
    return if $pos >= length($$buffer);
    my $indents = $self->{indent};
    pos($$buffer) = $pos;
    if ($pos == 0) {
        $$buffer =~ /\G($SPACE*)$NONSPACE/g or die;
        push @$indents, length($1);
        return $parser->match_rule($pos);
    }
    my $len = @$indents ? $indents->[-1] + 1 : 0;
    $$buffer =~ /\G$EOL(${SPACE}{$len,})$NONSPACE/g or return;
    push @$indents, length($1);
    return $parser->match_rule($pos);
}

sub rule_block_indent_sequence {
    my ($self, $parser, $buffer, $pos) = @_;
    return if $pos >= length($$buffer);
    my $indents = $self->{indent};
    pos($$buffer) = $pos;
    if ($pos == 0) {
        $$buffer =~ /\G($SPACE*)$DASHSPACE/g or return;
        push @$indents, length($1);
        return $parser->match_rule($pos);
    }
    my $len = 0;
    if (@$indents) {
        $len = $indents->[-1];
        $len++ unless $parser->{receiver}{kind}[-1] eq 'mapping';
    }
    # warn ">$len\n";
    $$buffer =~ /\G$EOL(${SPACE}{$len,})$DASHSPACE/g or return;
    push @$indents, length($1);
    return $parser->match_rule($pos);
}

sub rule_block_ondent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indents = $self->{indent};
    my $len = $indents->[-1];
    my $RE = $pos > 0 ? $EOL : $NOTHING;
    pos($$buffer) = $pos;
    $$buffer =~ /\G$RE(${SPACE}{$len})$NONSPACE/g or return;
    return $parser->match_rule(pos($$buffer));
}

sub rule_block_ondent_sequence {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indents = $self->{indent};
    my $len = $indents->[-1];
    my $RE = $pos > 0 ? $EOL : $NOTHING;
    pos($$buffer) = $pos;
    $$buffer =~ /\G$RE(${SPACE}{$len})$DASHSPACE/g or return;
    return $parser->match_rule(pos($$buffer));
}

sub rule_block_undent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indents = $self->{indent};
    return unless @$indents;
    my $len = $indents->[-1];
    pos($$buffer) = $pos;
    if ($$buffer =~ /\G$EOD|(?!$EOL {$len})/g) {
        pop @$indents;
        return $parser->match_rule($pos);
    }
    return;
}

sub make_tree {
    use Pegex::Bootstrap;
    use IO::All;
    my $grammar = io->file(file)->all;
    Pegex::Bootstrap->new->compile($grammar)->tree;
}
sub make_treeXXX {
# sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.61)
  {
    '+grammar' => 'yaml',
    '+toprule' => 'yaml_stream',
    '+version' => '0.0.1',
    'EOL' => {
      '.rgx' => qr/\G\r?\n/
    },
    'block_key' => {
      '.rgx' => qr/\G(?![&\*\{\}\[\]%"'`\@\#])(.+?)(?:\s+[\ \t]*\#.*)?(?=:\s|\r?\n|\z):(?:\ +|\ *(?=\r?\n))/
    },
    'block_mapping' => {
      '.all' => [
        {
          '.ref' => 'block_indent'
        },
        {
          '.all' => [
            {
              '.ref' => 'block_mapping_pair'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '+min' => 0,
                  '.all' => [
                    {
                      '.ref' => 'EOL'
                    },
                    {
                      '.ref' => 'ignore_line'
                    }
                  ]
                },
                {
                  '.ref' => 'block_mapping_pair'
                }
              ]
            },
            {
              '+max' => 1,
              '+min' => 0,
              '.all' => [
                {
                  '.ref' => 'EOL'
                },
                {
                  '.ref' => 'ignore_line'
                }
              ]
            }
          ]
        },
        {
          '.ref' => 'block_undent'
        }
      ]
    },
    'block_mapping_pair' => {
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
          '.ref' => 'block_indent_sequence'
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
          '.ref' => 'block_ondent_sequence'
        },
        {
          '.rgx' => qr/\G\-(?:\ +|\ *(?=\r?\n))/
        },
        {
          '.ref' => 'yaml_node'
        }
      ]
    },
    'document_end' => {
      '.rgx' => qr/\G/
    },
    'document_foot' => {
      '.rgx' => qr/\G\.\.\.\r?\n/
    },
    'document_head' => {
      '.rgx' => qr/\G\r?\n?\-\-\-(?:\ +|(?=\r?\n))/
    },
    'document_start' => {
      '.rgx' => qr/\G(?=[\s\S]*[^\r?\n])/
    },
    'double_quoted_scalar' => {
      '.rgx' => qr/\G"((?:\\"|[^"])*)"/
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
          '.ref' => 'flow_node'
        },
        {
          '.ref' => 'flow_mapping_separator'
        },
        {
          '.ref' => 'flow_node'
        }
      ]
    },
    'flow_mapping_separator' => {
      '.rgx' => qr/\G\s*:(?:\ +|\ *(?=\r?\n))/
    },
    'flow_mapping_start' => {
      '.rgx' => qr/\G\s*\{\s*/
    },
    'flow_node' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'yaml_prefix'
        },
        {
          '.any' => [
            {
              '.ref' => 'yaml_alias'
            },
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
    },
    'flow_plain_scalar' => {
      '.rgx' => qr/\G(?![&\*\{\}\[\]%"'`\@\#])(.+?)(?=[&\*\{\}\[\]%"',]|:\ |,\ |\r?\n|\z)/
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
      '.rgx' => qr/\G\s*\[\s*/
    },
    'folded_scalar' => {
      '.rgx' => qr/\G\>\r?\nXXX/
    },
    'ignore_line' => {
      '.rgx' => qr/\G(?:[\ \t]*\#.*|[\ \t]*)(?=\r?\n)/
    },
    'list_separator' => {
      '.rgx' => qr/\G\s*,\s*/
    },
    'literal_scalar' => {
      '.rgx' => qr/\G\|\r?\nXXX/
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
          '.all' => [
            {
              '.ref' => 'yaml_node'
            },
            {
              '+max' => 1,
              '.ref' => 'EOL'
            }
          ]
        },
        {
          '+max' => 1,
          '.ref' => 'ignore_line'
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
                  '.ref' => 'block_sequence'
                },
                {
                  '.ref' => 'block_mapping'
                },
                {
                  '.ref' => 'block_scalar'
                }
              ]
            }
          ]
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
          '+max' => 1,
          '.all' => [
            {
              '.ref' => 'ignore_line'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'EOL'
                },
                {
                  '.ref' => 'ignore_line'
                }
              ]
            }
          ]
        },
        {
          '+min' => 0,
          '.all' => [
            {
              '.ref' => 'yaml_document'
            },
            {
              '+min' => 0,
              '.ref' => 'ignore_line'
            }
          ]
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

1;
