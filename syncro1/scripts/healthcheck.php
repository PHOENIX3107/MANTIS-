<?php
/** Deep localhost health check; never prints database credentials. */

$t_root = dirname( __DIR__, 2 );
require_once $t_root . '/core.php';
require_api( 'database_api.php' );
$t_result = db_query( 'SELECT 1 AS healthy' );
$t_row = db_fetch_array( $t_result );
if( !$t_row || (int)$t_row['healthy'] !== 1 ) {
	error_log( 'SYNCRO1 deep health check failed' );
	if( function_exists( 'http_response_code' ) ) {
		http_response_code( 503 );
	}
	echo "unhealthy\n";
	exit( 1 );
}
echo "ok\n";
