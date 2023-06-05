<?php

    $AUTOCONFIG['dbtype'] = 'mysql';
    $AUTOCONFIG['dbname'] = getenv('MYSQL_DATABASE');
    $AUTOCONFIG['dbuser'] = getenv('MYSQL_USER');
    $AUTOCONFIG['dbpass'] = getenv('MYSQL_PASSWORD');
    $AUTOCONFIG['dbhost'] = getenv('MYSQL_HOST');
    $AUTOCONFIG['directory'] = getenv('NEXTCLOUD_DATA_DIR') ?: '/var/www/html/data';
