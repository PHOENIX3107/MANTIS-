<?php
/** SYNCRO1 guarded “Raise ticket” action. */

form_security_validate( 'syncro1_action_raise' );
auth_ensure_user_authenticated();
$f_bug_id = gpc_get_int( 'bug_id' );
access_ensure_bug_level( DEVELOPER, $f_bug_id );
$t_bug = bug_get( $f_bug_id, true );
access_ensure_project_level( DEVELOPER, $t_bug->project_id );

if( !in_array( (int)$t_bug->status, array( NEW_, FEEDBACK ), true ) ) {
	form_security_purge( 'syncro1_action_raise' );
	throw new \Mantis\Exceptions\ClientException( plugin_lang_get( 'action_unavailable' ), ERROR_BUG_CONFLICTING_EDIT );
}

$t_user_id = auth_get_current_user_id();
db_param_push();
$t_query = 'UPDATE {bug} SET status=' . db_param() . ', last_updated=' . db_param()
	. ' WHERE id=' . db_param() . ' AND status IN (' . db_param() . ',' . db_param() . ')';
db_query( $t_query, array( ACKNOWLEDGED, db_now(), $f_bug_id, NEW_, FEEDBACK ) );
if( db_affected_rows() !== 1 ) {
	form_security_purge( 'syncro1_action_raise' );
	throw new \Mantis\Exceptions\ClientException( plugin_lang_get( 'action_conflict' ), ERROR_BUG_CONFLICTING_EDIT );
}

history_log_event_direct( $f_bug_id, 'status', $t_bug->status, ACKNOWLEDGED, $t_user_id );
plugin_history_log( $f_bug_id, 'action', '', 'ticket raised', $t_user_id );
$t_actor = user_get_name( $t_user_id );
bugnote_add( $f_bug_id, sprintf( plugin_lang_get( 'ticket_raised_note' ), $t_actor ), '0:00', false, BUGNOTE, '', $t_user_id, true );
email_bug_status_changed( $f_bug_id, 'ticket_raised' );
bug_clear_cache( $f_bug_id );

form_security_purge( 'syncro1_action_raise' );
print_header_redirect_view( $f_bug_id );
