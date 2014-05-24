package YAML::Pegex::Grammar;
use base 'Pegex::Grammar';

use constant file => 'share/yaml.pgx';

sub make_tree {
  {
    '+toprule' => 'yaml_stream',
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
      '.ref' => 'node_scalar'
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
    'block_sequence' => {
      '+min' => 1,
      '.ref' => 'block_sequence_entry'
    },
    'block_sequence_entry' => {
      '.rgx' => qr/\G\-\ +([^:\r\n]+)\r?\n/
    },
    'block_undent' => {
      '.rgx' => qr/\G/
    },
    'block_value' => {
      '.ref' => 'node_scalar'
    },
    'document_foot' => {
      '.rgx' => qr/\G\.\.\.\r?\n/
    },
    'document_head' => {
      '.rgx' => qr/\G\-\-\-(?:\ +|(?=\r?\n))/
    },
    'flow_mapping' => {
      '.rgx' => qr/\G\s*\{\s*/
    },
    'flow_sequence' => {
      '.rgx' => qr/\G\s*\[\s*/
    },
    'ignore_line' => {
      '.rgx' => qr/\G(?:[\ \t]*|\#.*)\r?\n/
    },
    'mapping_separator' => {
      '.rgx' => qr/\G:\ +/
    },
    'node_alias' => {
      '.rgx' => qr/\G&(\w+)/
    },
    'node_anchor' => {
      '.rgx' => qr/\G&(\w+)/
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
    'node_scalar' => {
      '.rgx' => qr/\G([^:\r\n]+)/
    },
    'node_tag' => {
      '.rgx' => qr/\G!!?(\w+)/
    },
    'yaml_document' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'document_head'
        },
        {
          '.ref' => 'yaml_node'
        },
        {
          '+max' => 1,
          '.ref' => 'document_foot'
        }
      ]
    },
    'yaml_node' => {
      '.all' => [
        {
          '+max' => 1,
          '.ref' => 'node_prefix'
        },
        {
          '.any' => [
            {
              '.ref' => 'flow_mapping'
            },
            {
              '.ref' => 'flow_sequence'
            },
            {
              '.ref' => 'block_mapping'
            },
            {
              '.ref' => 'block_sequence'
            },
            {
              '.ref' => 'node_scalar'
            },
            {
              '.ref' => 'node_alias'
            }
          ]
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
