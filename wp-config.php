/**
 * Improve error logging and move outside web root.
 * Adapted from https://gist.github.com/jrfnl/5925642
 */
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_DISPLAY', false );
@error_reporting( -1 ); // everything, including E_STRICT and other newly introduced error levels.
@ini_set( 'log_errors', true );
@ini_set( 'log_errors_max_len', '0' );
@ini_set( 'error_log', '/var/www/droplet3.hellyer.kiwi/wordpress-error.log' );