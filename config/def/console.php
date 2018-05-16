<?php
return [
    'define' => [
        'ENABLE_SEF' => true,
        'DS' => '/'
    ],
    'set_time_limit' => 1800,
    'ini_set' => [
        'display_errors' => 'On',
        'mysql.connect_timeout' => 60,
        'error_reporting' => (E_ALL & (~E_DEPRECATED)),
        'always_populate_raw_post_data' => -1,
    ],
    'date_default_timezone_set' => 'UTC',
    'setlocale' => [
        [LC_ALL,'en_US'],
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
    ]
];
