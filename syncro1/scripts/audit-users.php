#!/usr/bin/env php
<?php
/** List users whose email is outside the configured exact domains. */

$t_root = dirname( __DIR__, 2 );
require_once $t_root . '/core.php';
require_api( 'database_api.php' );
$t_allowed = array_values( array_filter( array_map( 'strtolower', array_map( 'trim', explode( ',', getenv( 'ALLOWED_EMAIL_DOMAINS' ) ?: 'syncro1.com,syncrosquad.com' ) ) ), 'strlen' ) );
$t_result = db_query( 'SELECT id, username, email, enabled FROM {user} ORDER BY id' );
$t_bad = 0;
while( $t_row = db_fetch_array( $t_result ) ) {
	$t_email = (string)$t_row['email'];
	$t_at = strrpos( $t_email, '@' );
	$t_domain = false === $t_at ? '' : strtolower( substr( $t_email, $t_at + 1 ) );
	$t_valid = $t_email !== '' && trim( $t_email ) === $t_email && false !== filter_var( $t_email, FILTER_VALIDATE_EMAIL ) && in_array( $t_domain, $t_allowed, true );
	if( !$t_valid ) {
		$t_bad++;
		printf( "INVALID id=%d username=%s email=%s enabled=%d\n", $t_row['id'], $t_row['username'], $t_email, $t_row['enabled'] );
	}
}
if( $t_bad > 0 ) {
	fwrite( STDERR, "$t_bad account(s) violate ALLOWED_EMAIL_DOMAINS.\n" );
	exit( 2 );
}
fwrite( STDOUT, "All accounts match the configured email domains.\n" );
