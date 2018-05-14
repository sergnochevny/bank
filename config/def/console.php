<?php
return [
  'define' => [
    'ENABLE_SEF' => true,
    'DS' => '/'
  ],
  'ini_set' => [
    'display_errors' => 'On',
    'mysql.connect_timeout' => 60,
    'error_reporting' => (E_ALL & (~E_DEPRECATED)),
    'always_populate_raw_post_data' => -1,
  ],
  'date_default_timezone_set' => [['UTC']],
  'setlocale' => [
    [LC_ALL, 'en_US'],
    [LC_TIME, 'UTC']
  ],
  'DBS' => [
    'connections' => [
      'default' => [
        'host' => "localhost",
        'user' => "root",
        'password' => "",
        'db' => [
          'default' => 'bank'
        ]
      ]
    ]
  ],
  'layouts' => "main_layout",
  'per_page_items' => ['6', '12', '24'],
];
