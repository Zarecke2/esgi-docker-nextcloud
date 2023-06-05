<?php

  $CONFIG = array(
    'memcache.distributed' => '\OC\Memcache\Redis',
    'memcache.locking' => '\OC\Memcache\Redis',
    'redis' => array(
      'host' => getenv('REDIS_HOST'),
      'password' => (string) getenv('REDIS_HOST_PASSWORD'),
    ),
  );
 $CONFIG['redis']['port'] = (int) getenv('REDIS_HOST_PORT');
 
