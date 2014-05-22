package YAML::Pegex::Grammar;
use base 'Pegex::Grammar';

use constant file => 'share/yaml.pgx';

sub make_tree {
  {
    '+toprule' => 'document',
    'EOL' => {
      '.rgx' => qr/\G\r?\n/
    },
    'document' => {
      '.any' => [
        {
          '.ref' => 'mapping'
        },
        {
          '.ref' => 'sequence'
        },
        {
          '.ref' => 'scalar'
        }
      ]
    },
    'key' => {
      '.ref' => 'scalar'
    },
    'key_value_pair' => {
      '.all' => [
        {
          '.ref' => 'key'
        },
        {
          '.ref' => 'mapping_separator'
        },
        {
          '.ref' => 'value'
        }
      ]
    },
    'mapping' => {
      '+max' => 1,
      '.all' => [
        {
          '.ref' => 'key_value_pair'
        },
        {
          '+min' => 0,
          '-flat' => 1,
          '.all' => [
            {
              '.ref' => 'EOL'
            },
            {
              '.ref' => 'key_value_pair'
            }
          ]
        },
        {
          '+max' => 1,
          '.ref' => 'EOL'
        }
      ]
    },
    'mapping_separator' => {
      '.rgx' => qr/\G:\ +/
    },
    'scalar' => {
      '.rgx' => qr/\G([^:\r\n]+)/
    },
    'value' => {
      '.ref' => 'scalar'
    }
  }
}

1;
