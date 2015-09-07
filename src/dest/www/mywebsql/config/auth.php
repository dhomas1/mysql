<?php
define('AUTH_TYPE', 'LOGIN');
$secure_login_available = (extension_loaded('openssl') && extension_loaded('gmp')) || extension_loaded('bcmath');
define('SECURE_LOGIN', $secure_login_available);
define('AUTH_SERVER', 'localhost|mysql5');
?>
