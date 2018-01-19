<?php
/**
 * WordPress configuration file generated by Wodby.
 */

/**
 * Absolute path to the WordPress directory.
 */
if (!defined('ABSPATH')) {
  define('ABSPATH', __DIR__ . '/');
}

/**
 * Sets up wodby-specific configuration (must placed before wp-settings.php include).
 */
require_once '{{ getenv "CONF_DIR" }}/wodby.wp-config.php';

/**
 * Sets up WordPress vars and included files.
 */
require_once ABSPATH . 'wp-settings.php';