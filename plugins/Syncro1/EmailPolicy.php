<?php
/** Pure SYNCRO1 email policy used by the plugin and CLI tests. */

function syncro1_email_is_allowed( $p_email, array $p_allowed_domains ) {
	if( !is_string( $p_email ) || $p_email === '' || trim( $p_email ) !== $p_email ) {
		return false;
	}
	if( preg_match( '/\s/', $p_email ) || preg_match( '/[^\x00-\x7F]/', $p_email ) ) {
		return false;
	}
	if( false === filter_var( $p_email, FILTER_VALIDATE_EMAIL ) ) {
		return false;
	}
	$t_at = strrpos( $p_email, '@' );
	if( false === $t_at || $t_at < 1 || $t_at === strlen( $p_email ) - 1 ) {
		return false;
	}
	$t_domain = strtolower( substr( $p_email, $t_at + 1 ) );
	$t_allowed = array_values( array_filter( array_map( 'strtolower', array_map( 'trim', $p_allowed_domains ) ), 'strlen' ) );
	return in_array( $t_domain, $t_allowed, true );
}
