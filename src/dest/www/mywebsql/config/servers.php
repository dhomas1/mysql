<?php
$ALLOW_CUSTOM_SERVERS = FALSE;
$ALLOW_CUSTOM_SERVER_TYPES = "mysql";

$SERVER_LIST = array(
  'MySQL'           => array(
    'host'   => 'localhost',
    'driver' => extension_loaded('mysqli') ? 'mysqli' : 'mysql5'
  ),
);
?>
