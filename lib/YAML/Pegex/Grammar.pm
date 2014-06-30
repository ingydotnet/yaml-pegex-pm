use strict; use warnings;
package YAML::Pegex::Grammar;
use Pegex::Base;
extends 'Pegex::Grammar';

use constant file => '../yaml-pgx/yaml.pgx';

has indent => [];

sub rule_block_indent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indents = $self->{indent};
    pos($$buffer) = $pos;
    return if $pos >= length($$buffer);
    if ($pos == 0) {
        $$buffer =~ /\G( *)(?=[^\s\#])/g or die;
        push @$indents, length($1);
        return $parser->match_rule($pos);
    }
    my $len = @$indents ? $indents->[-1] + 1 : 0;
    $$buffer =~ /\G\r?\n( {$len,})(?=[^\s\#])/g or return;
    push @$indents, length($1);
    return $parser->match_rule($pos);
}

sub rule_block_ondent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indents = $self->{indent};
    my $len = $indents->[-1];
    my $re = $pos > 0 ? '\r?\n' : '';
    pos($$buffer) = $pos;
    $$buffer =~ /\G$re( {$len})(?=[^\s\#])/g or return;
    return $parser->match_rule(pos($$buffer));
}

sub rule_block_undent {
    my ($self, $parser, $buffer, $pos) = @_;
    my $indents = $self->{indent};
    return unless @$indents;
    my $len = $indents->[-1];
    pos($$buffer) = $pos;
    if ($$buffer =~ /\G((?:\r?\n)?)\z/) {
        $pos += length($1);
    }
    elsif ($$buffer =~ /\G\r?\n( {$len})/g) {
        return;
    }
    pop @$indents;
    return $parser->match_rule($pos);
}

# sub make_tree {
#     use Pegex::Bootstrap;
#     use IO::All;
#     my $grammar = io->file(file)->all;
#     Pegex::Bootstrap->new->compile($grammar)->tree;
# }
# sub make_treeXXX {
sub make_tree {
  {
    '+grammar' => 'yaml',
    '+toprule' => 'yaml_stream',
    '+version' => '0.0.1',
    'SPACE' => {
      '.rgx' => qr/\G\ /
    },
    'block_key' => {
      '.ref' => 'block_scalar'
    },
    'block_mapping' => {
      '.all' => [
        {
          '.ref' => 'block_indent'
        },
        {
          '+min' => 1,
          '.ref' => 'block_mapping_pair'
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
          '.ref' => 'block_mapping_separator'
        },
        {
          '.ref' => 'block_value'
        }
      ]
    },
    'block_mapping_separator' => {
      '.rgx' => qr/\G:(?:\ +|\ *(?=\r?\n))/
    },
    'block_node' => {
      '.any' => [
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
    },
    'block_scalar' => {
      '.rgx' => qr/\G(\|\r?\nXXX|\>\r?\nXXX|"[^"]*"|'[^']*'|(?![&\*\#\{\}\[\]%`\@]).+?(?=:\s|\r?\n|\z))/
    },
    'block_sequence' => {
      '.all' => [
        {
          '.ref' => 'block_sequence_entry'
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.ref' => 'list_separator'
            },
            {
              '.ref' => 'block_sequence_entry'
            }
          ]
        },
        {
          '+max' => 1,
          '.ref' => 'list_separator'
        }
      ]
    },
    'block_sequence_entry' => {
      '.rgx' => qr/\G\-\ +(\|\r?\nXXX|\>\r?\nXXX|"[^"]*"|'[^']*'|(?![&\*\#\{\}\[\]%`\@]).+?(?=:\s|\r?\n|\z))\r?\n/
    },
    'block_value' => {
      '.any' => [
        {
          '.ref' => 'flow_mapping'
        },
        {
          '.ref' => 'flow_sequence'
        },
        {
          '.ref' => 'block_node'
        }
      ]
    },
    'document_foot' => {
      '.rgx' => qr/\G\.\.\.\r?\n/
    },
    'document_head' => {
      '.rgx' => qr/\G\-\-\-(?:\ +|(?=\r?\n))/
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
      '.rgx' => qr/\G\s*\}\s*/
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
      '.rgx' => qr/\G:(?:\ +|\ *(?=\r?\n))/
    },
    'flow_mapping_start' => {
      '.rgx' => qr/\G\s*\{\s*/
    },
    'flow_node' => {
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
    },
    'flow_scalar' => {
      '.rgx' => qr/\G("[^"]*"|'[^']*'|(?![&\*\#\{\}\[\]%`\@]).+?(?=[&\*\#\{\}\[\]%,]|:\ |,\ |\r?\n|\z))/
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
              '.ref' => 'flow_sequence_entry'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'list_separator'
                },
                {
                  '.ref' => 'flow_sequence_entry'
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
      '.rgx' => qr/\G\s*\]\s*/
    },
    'flow_sequence_entry' => {
      '.ref' => 'flow_scalar'
    },
    'flow_sequence_start' => {
      '.rgx' => qr/\G\s*\[\s*/
    },
    'ignore_line' => {
      '.rgx' => qr/\G(?:\#.*|[\ \t]*)(?=\r?\n)/
    },
    'list_separator' => {
      '.rgx' => qr/\G,\ +/
    },
    'node_alias' => {
      '.rgx' => qr/\G\*(\w+)/
    },
    'node_anchor' => {
      '.rgx' => qr/\G\&(\w+)/
    },
    'node_prefix' => {
      '.any' => [
        {
          '.all' => [
            {
              '.ref' => 'node_anchor'
            },
            {
              '+max' => 1,
              '.all' => [
                {
                  '+min' => 1,
                  '.ref' => 'SPACE'
                },
                {
                  '.ref' => 'node_tag'
                }
              ]
            }
          ]
        },
        {
          '.all' => [
            {
              '.ref' => 'node_tag'
            },
            {
              '+max' => 1,
              '.all' => [
                {
                  '+min' => 1,
                  '.ref' => 'SPACE'
                },
                {
                  '.ref' => 'node_anchor'
                }
              ]
            }
          ]
        }
      ]
    },
    'node_tag' => {
      '.rgx' => qr/\G!!?(\w+)/
    },
    'top_node' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'node_prefix'
        },
        {
          '.any' => [
            {
              '.ref' => 'node_alias'
            },
            {
              '.ref' => 'flow_mapping'
            },
            {
              '.ref' => 'flow_sequence'
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
    },
    'yaml_document' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'document_head'
        },
        {
          '.ref' => 'top_node'
        },
        {
          '+max' => 1,
          '.ref' => 'ignore_line'
        },
        {
          '+max' => 1,
          '.ref' => 'document_foot'
        }
      ]
    },
    'yaml_stream' => {
      '.all' => [
        {
          '+min' => 0,
          '.ref' => 'ignore_line'
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
        }
      ]
    }
  }
}

1;
