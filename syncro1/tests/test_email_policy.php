#!/usr/bin/env php
<?php
require_once dirname( __DIR__, 2 ) . '/plugins/Syncro1/EmailPolicy.php';

$t_allowed = array( 'syncro1.com', 'syncrosquad.com' );
$t_cases = array(
	'a@evil.com' => false,
	'a@syncro1.com.evil.com' => false,
	'a@evilsyncro1.com' => false,
	'a@sub.syncro1.com' => false,
	'a@syncro1.com@evil.com' => false,
	'a@syncro1.co' => false,
	'' => false,
	'  a@syncro1.com' => false,
	'a@syncro1.com  ' => false,
	'a@ѕyncro1.com' => false,
	'A@SYNCRO1.COM' => true,
	'first.last+tag@syncrosquad.com' => true,
);

$t_failures = array();
foreach( $t_cases as $t_email => $t_expected ) {
	$t_actual = syncro1_email_is_allowed( $t_email, $t_allowed );
	if( $t_actual !== $t_expected ) {
		$t_failures[] = $t_email === '' ? '<empty>' : $t_email;
	}
}
if( $t_failures ) {
	fwrite( STDERR, "Email policy failures: " . implode( ', ', $t_failures ) . "\n" );
	exit( 1 );
}
fwrite( STDOUT, "Email policy cases passed: " . count( $t_cases ) . "\n" );
