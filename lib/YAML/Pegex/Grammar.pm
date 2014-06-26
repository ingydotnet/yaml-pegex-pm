package YAML::Pegex::Grammar;

use base 'Pegex::Grammar';

use constant file => '../yaml-pgx/yaml.pgx';

sub make_tree {
  {
    '+grammar' => 'yaml',
    '+toprule' => 'yaml_stream',
    '+version' => '0.0.1',
    'EOL' => {
      '.rgx' => qr/\G\r?\n/
    },
    'SPACE' => {
      '.rgx' => qr/\G\ /
    },
    'block_indent' => {
      '.rgx' => qr/\G/
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
          '.all' => [
            {
              '.ref' => 'block_mapping_pair'
            },
            {
              '+min' => 0,
              '-flat' => 1,
              '.all' => [
                {
                  '.ref' => 'ignore_line'
                },
                {
                  '.ref' => 'block_mapping_pair'
                }
              ]
            }
          ]
        },
        {
          '.all' => [
            {
              '.ref' => 'EOL'
            },
            {
              '.ref' => 'block_undent'
            }
          ]
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
          '.ref' => 'mapping_separator'
        },
        {
          '.ref' => 'block_value'
        }
      ]
    },
    'block_ondent' => {
      '.rgx' => qr/\G/
    },
    'block_scalar' => {
      '.rgx' => qr/\G(\|\r?\nXXX|\>\r?\nXXX|"[^"]*"|'[^']*'|(?![&\*\#\{\}\[\]%`]).+?(?=:\ |\r?\n|\z))/
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
      '.rgx' => qr/\G\-\ +(\|\r?\nXXX|\>\r?\nXXX|"[^"]*"|'[^']*'|(?![&\*\#\{\}\[\]%`]).+?(?=:\ |\r?\n|\z))\r?\n/
    },
    'block_undent' => {
      '.rgx' => qr/\G/
    },
    'block_value' => {
      '.any' => [
        {
          '.ref' => 'block_scalar'
        },
        {
          '.ref' => 'flow_node'
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
          '.ref' => 'mapping_separator'
        },
        {
          '.ref' => 'flow_node'
        }
      ]
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
      '.rgx' => qr/\G("[^"]*"|'[^']*'|(?![&\*\#\{\}\[\]%`]).+?(?=[&\*\#\{\}\[\]%,]|:\ |,\ |\r?\n|\z))/
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
      '.rgx' => qr/\G(?:[\ \t]*|\#.*)\r?\n/
    },
    'list_separator' => {
      '.rgx' => qr/\G,\ +/
    },
    'mapping_separator' => {
      '.rgx' => qr/\G:\ +/
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
