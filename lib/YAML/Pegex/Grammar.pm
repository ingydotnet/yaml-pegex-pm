use strict; use warnings;
package YAML::Pegex::Grammar;
our $VERSION = '0.0.17';

use Pegex::Base;
extends 'Pegex::Grammar';

use constant file => './share/yaml-pgx/yaml.pgx';

has indent => [-1];
has last_seq_indent_pos => 0;

my $EOL = qr/\r?\n/;
my $EOD = qr/(?:$EOL)?(?=\z|\.\.\.\r?\n|\-\-\-\r?\n)/;
my $SPACE = qr/ /;
my $DASH = qr/\-/;
my $DASHSPACE = qr/(?=$DASH\s)/;
my $NONSPACE = qr/(?=[^\s\#])/;

sub rule_block_indent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indent = $self->{indent};
    pos($$buffer) = $pos;
    $$buffer =~ /\G${SPACE}{${\($indent->[-1]+1)},}$NONSPACE/g or return;
    push @$indent, length($&);
    return $parser->match_rule(pos($$buffer));
}

sub rule_block_ondent {
    my ($self, $parser, $buffer, $pos) = @_;
    pos($$buffer) = $pos;
    $$buffer =~ /\G${SPACE}{${\$self->{indent}[-1]}}$NONSPACE/g or return;
    return $parser->match_rule(pos($$buffer));
}

sub rule_block_undent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indent = $self->{indent};
    return unless @$indent;
    pos($$buffer) = $pos;
    return unless $$buffer =~ /\G$EOD|(?!$EOL {${\$indent->[-1]}})/g;
    pop @$indent;
    return $parser->match_rule($pos);
}

sub rule_block_sequence_indent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indent = $self->{indent};
    pos($$buffer) = $pos;
    my $last_pos = $self->{last_seq_indent_pos};
    if (substr($$buffer, $last_pos, $pos - $last_pos) =~ /^${DASH}${SPACE}+\z/) {
        $$buffer =~ /\G${SPACE}*$DASHSPACE/g or return;
        push @$indent, $indent->[-1] + $pos - $last_pos + length($&);
        return $parser->match_rule($self->{last_seq_indent_pos} = pos($$buffer));
    }
    my $count = $indent->[-1];
    $count++ unless $parser->{receiver}{kind}[-1] eq 'mapping';
    $$buffer =~ /\G${SPACE}{$count,}$DASHSPACE/g or return;
    push @$indent, length($&);
    return $parser->match_rule($self->{last_seq_indent_pos} = pos($$buffer));
}

sub rule_block_sequence_ondent {
    my ($self, $parser, $buffer, $pos) = @_;
    pos($$buffer) = $pos;
    $$buffer =~ /\G${SPACE}{${\$self->{indent}[-1]}}$DASHSPACE/g or return;
    return $parser->match_rule(pos($$buffer));
}

sub rule_block_sequence_undent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indent = $self->{indent};
    return unless @$indent;
    pos($$buffer) = $pos;
    return unless $$buffer =~ /\G$EOD|(?!$EOL {${\$indent->[-1]}})/g;
    pop @$indent;
    return $parser->match_rule($pos);
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

sub make_tree {   # Generated/Inlined by Pegex::Grammar (0.63)
  {
    '+grammar' => 'yaml',
    '+toprule' => 'yaml_stream',
    '+version' => '0.0.1',
    'EOS' => {
      '.rgx' => qr/\G\z/
    },
    '__' => {
      '.rgx' => qr/\G(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*/
    },
    'any_node' => {
      '.any' => [
        {
          '.ref' => 'yaml_alias'
        },
        {
          '.ref' => 'yaml_node'
        }
      ]
    },
    'block_key' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'yaml_props'
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
      '.any' => [
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
    'block_mapping_or_scalar' => {
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
                  '.all' => [
                    {
                      '.ref' => '__'
                    },
                    {
                      '.ref' => 'block_ondent'
                    }
                  ]
                },
                {
                  '.ref' => 'block_pair'
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
    'block_node' => {
      '.any' => [
        {
          '.ref' => 'block_sequence'
        },
        {
          '.ref' => 'block_mapping_or_scalar'
        },
        {
          '.ref' => 'block_scalar'
        }
      ]
    },
    'block_pair' => {
      '.all' => [
        {
          '.ref' => 'block_key'
        },
        {
          '.ref' => 'any_node'
        }
      ]
    },
    'block_plain_scalar' => {
      '.rgx' => qr/\G(?![&\*!\{\}\[\]%"'`\@\#])(.*?)(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?=:\s|\r?\n|\z)/
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
          '.all' => [
            {
              '.ref' => 'block_sequence_entry'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.all' => [
                    {
                      '.ref' => '__'
                    },
                    {
                      '.ref' => 'block_sequence_ondent'
                    }
                  ]
                },
                {
                  '.ref' => 'block_sequence_entry'
                }
              ]
            }
          ]
        },
        {
          '.ref' => 'block_sequence_undent'
        }
      ]
    },
    'block_sequence_entry' => {
      '.all' => [
        {
          '.ref' => 'block_sequence_marker'
        },
        {
          '.ref' => 'any_node'
        }
      ]
    },
    'block_sequence_marker' => {
      '.rgx' => qr/\G\-(?:(?=[\ \t])(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)|(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*)/
    },
    'directive_tag' => {
      '.rgx' => qr/\G%TAG(?=[\ \t])(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)!(.*)!(?=[\ \t])(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(\S+)(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*/
    },
    'directive_yaml' => {
      '.rgx' => qr/\G%YAML(?=[\ \t])(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)1\.2(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*/
    },
    'document_end' => {
      '.rgx' => qr/\G/
    },
    'document_foot' => {
      '.rgx' => qr/\G\.\.\.(?:\r?\n|\z)/
    },
    'document_head' => {
      '.rgx' => qr/\G\-\-\-/
    },
    'document_start' => {
      '.rgx' => qr/\G(?=.)/
    },
    'double_quoted_scalar' => {
      '.rgx' => qr/\G"((?:\\"|[^"])*)"/
    },
    'flow_collection' => {
      '.any' => [
        {
          '.ref' => 'flow_sequence'
        },
        {
          '.ref' => 'flow_mapping'
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
      '.rgx' => qr/\G(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)\}(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)/
    },
    'flow_mapping_pair' => {
      '.all' => [
        {
          '.any' => [
            {
              '.ref' => 'json_key'
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
      '.rgx' => qr/\G\{(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)/
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
              '.ref' => 'yaml_props'
            },
            {
              '.ref' => 'x'
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
      '.rgx' => qr/\G(?![&\*!\{\}\[\]%"'`\@\#])(.*?)(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?=[&\*!\{\}\[\]%"',]|:\ |,\ |\r?\n|\z)/
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
      '.rgx' => qr/\G(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)\](?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)/
    },
    'flow_sequence_start' => {
      '.rgx' => qr/\G\[(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)/
    },
    'json_key' => {
      '.rgx' => qr/\G"((?:\\"|[^"])*)":(?=\S)/
    },
    'list_separator' => {
      '.rgx' => qr/\G(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?),(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)/
    },
    'pair_separator' => {
      '.rgx' => qr/\G(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?):(?=\s)(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)/
    },
    'single_quoted_scalar' => {
      '.rgx' => qr/\G'((?:''|[^'])*)'/
    },
    'stream_end' => {
      '.ref' => 'EOS'
    },
    'stream_start' => {
      '.rgx' => qr/\G(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*/
    },
    'x' => {
      '.rgx' => qr/\G(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)/
    },
    'yaml_alias' => {
      '.rgx' => qr/\G\*(\w+)(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)/
    },
    'yaml_document' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'directive_yaml'
        },
        {
          '+min' => 0,
          '.ref' => 'directive_tag'
        },
        {
          '.any' => [
            {
              '.all' => [
                {
                  '.ref' => 'document_head'
                },
                {
                  '.any' => [
                    {
                      '.all' => [
                        {
                          '.rgx' => qr/\G[\ \t]+/
                        },
                        {
                          '.ref' => 'block_scalar'
                        },
                        {
                          '.ref' => '__'
                        }
                      ]
                    },
                    {
                      '.all' => [
                        {
                          '.ref' => '__'
                        },
                        {
                          '.ref' => 'yaml_node'
                        }
                      ]
                    }
                  ]
                }
              ]
            },
            {
              '.all' => [
                {
                  '.ref' => 'document_start'
                },
                {
                  '.ref' => 'yaml_node'
                }
              ]
            }
          ]
        },
        {
          '.ref' => '__'
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
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'yaml_props'
        },
        {
          '.rgx' => qr/\G(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*/
        },
        {
          '.any' => [
            {
              '.all' => [
                {
                  '.rgx' => qr/\G(?=[\{\[])/
                },
                {
                  '.ref' => 'flow_collection'
                }
              ]
            },
            {
              '.ref' => 'block_node'
            }
          ]
        }
      ]
    },
    'yaml_props' => {
      '.rgx' => qr/\G(?:(?:\&(\w+)(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?))(?:(\!\S*)(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?))?|(?:(\!\S*)(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?))(?:\&(\w+)(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?))?)((?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:(?:[\ \t]*(?:(?:(?<=\s)|(?<=^))\#.*)?)(?:\r?\n|\z))*)/
    },
    'yaml_stream' => {
      '.all' => [
        {
          '.ref' => 'stream_start'
        },
        {
          '+min' => 0,
          '.ref' => 'yaml_document'
        },
        {
          '.ref' => 'stream_end'
        }
      ]
    }
  }
}

{
    no warnings 'redefine';
    *make_tree = \&make_tree_dynamic if $ENV{YAML_PEGEX_DEV};
}

1;
