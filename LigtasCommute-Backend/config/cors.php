<?php

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    // You can keep '*' while supports_credentials is false,
    // or tighten it to localhost origins you actually use:
    // 'allowed_origins' => ['http://localhost:*', 'http://127.0.0.1:*'],
    'allowed_origins' => ['*'],

    'allowed_origins_patterns' => [],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    // IMPORTANT for Bearer token flows from Flutter Web
    'supports_credentials' => false,
];
