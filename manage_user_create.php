<?php
# MantisBT - A PHP based bugtracking system

# MantisBT is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 2 of the License, or
# (at your option) any later version.
#
# MantisBT is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with MantisBT.  If not, see <http://www.gnu.org/licenses/>.

/**
 * Create a User
 *
 * @package MantisBT
 * @copyright Copyright 2000 - 2002  Kenzaburo Ito - kenito@300baud.org
 * @copyright Copyright 2002  MantisBT Team - mantisbt-dev@lists.sourceforge.net
 * @link http://www.mantisbt.org
 *
 * @uses core.php
 * @uses access_api.php
 * @uses authentication_api.php
 * @uses constant_inc.php
 * @uses form_api.php
 * @uses gpc_api.php
 * @uses helper_api.php
 * @uses html_api.php
 * @uses lang_api.php
 * @uses print_api.php
 * @uses string_api.php
 * @uses utility_api.php
 */

require_once( 'core.php' );
require_api( 'access_api.php' );
require_api( 'authentication_api.php' );
require_api( 'constant_inc.php' );
require_api( 'config_api.php' );
require_api( 'form_api.php' );
require_api( 'gpc_api.php' );
require_api( 'helper_api.php' );
require_api( 'html_api.php' );
require_api( 'lang_api.php' );
require_api( 'print_api.php' );
require_api( 'string_api.php' );
require_api( 'utility_api.php' );

form_security_validate( 'manage_user_create' );

auth_reauthenticate();

$f_username        = gpc_get_string( 'username' );
$f_realname        = gpc_get_string( 'realname', '' );
$f_password        = gpc_get_string( 'password', '' );
$f_password_verify = gpc_get_string( 'password_verify', '' );
$f_use_temporary_password = gpc_get_bool( 'use_temporary_password', false );
$f_temporary_password = gpc_get_string( 'temporary_password', '' );
$f_temporary_password_verify = gpc_get_string( 'temporary_password_verify', '' );
$f_email           = gpc_get_string( 'email', '' );
$f_access_level    = gpc_get_string( 'access_level' );
$f_protected       = gpc_get_bool( 'protected' );
$f_enabled         = gpc_get_bool( 'enabled' );

if( $f_password != $f_password_verify ) {
	trigger_error( ERROR_USER_CREATE_PASSWORD_MISMATCH, ERROR );
}

if( $f_use_temporary_password ) {
	if( is_blank( $f_temporary_password ) ) {
		error_parameters( lang_get( 'password' ) );
		trigger_error( ERROR_EMPTY_FIELD, ERROR );
	}
	if( $f_temporary_password !== $f_temporary_password_verify ) {
		trigger_error( ERROR_USER_CREATE_PASSWORD_MISMATCH, ERROR );
	}
	$t_min_temporary_password_length = (int)config_get_global( 'syncro1_temporary_password_min_length', 12 );
	if( strlen( $f_temporary_password ) < $t_min_temporary_password_length ) {
		error_parameters( 'temporary_password' );
		trigger_error( ERROR_INVALID_FIELD_VALUE, ERROR );
	}
}

# Password won't be sent by email. It is entered by the admin
# Now, if the password is empty, confirm that that is what we wanted
if( is_blank( $f_password ) && (
	ON != config_get( 'send_reset_password' ) ||
	ON != config_get( 'enable_email_notification' ) )
) {
	helper_ensure_confirmed(
		lang_get( 'empty_password_sure_msg' ),
		lang_get( 'empty_password_button' ) );
}

$t_data = array(
	'query' => array(),
	'payload' => array(
		'username' => $f_username,
		'email' => $f_email,
		'access_level' => array( 'id' => $f_access_level ),
		'real_name' => $f_realname,
		'password' => $f_password,
		'use_temporary_password' => $f_use_temporary_password,
		'temporary_password' => $f_temporary_password,
		'protected' => $f_protected,
		'enabled' => $f_enabled
	)
);

$t_command = new UserCreateCommand( $t_data );
$t_result = $t_command->execute();

form_security_purge( 'manage_user_create' );

$t_user_id = $t_result['id'];
$t_redirect_url = 'manage_user_edit_page.php?user_id=' . $t_user_id;

layout_page_header( null, $t_redirect_url );
layout_page_begin( 'manage_overview_page.php' );

$t_access_level = get_enum_element( 'access_levels', $f_access_level );
$t_message = lang_get( 'created_user_part1' )
	. ' <span class="bold">' . $f_username . '</span> '
	. lang_get( 'created_user_part2' )
	. ' <span class="bold">' . $t_access_level . '</span><br />';
if( $f_use_temporary_password ) {
	$t_message .= '<span class="bold">Temporary password set. Give it to the user securely and ask them to change it from Account.</span>';
}
html_operation_successful( $t_redirect_url, $t_message );

layout_page_end();
