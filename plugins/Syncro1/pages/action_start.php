<?php
/** SYNCRO1 atomic “Start work” action. */

form_security_validate( 'syncro1_action_start' );
auth_ensure_user_authenticated();
$f_bug_id = gpc_get_int( 'bug_id' );
access_ensure_bug_level( DEVELOPER, $f_bug_id );
$t_bug = bug_get( $f_bug_id, true );
access_ensure_project_level( DEVELOPER, $t_bug->project_id );
$t_user_id = auth_get_current_user_id();

if( !in_array( (int)$t_bug->status, array( ACKNOWLEDGED, ASSIGNED ), true ) ) {
	form_security_purge( 'syncro1_action_start' );
	throw new \Mantis\Exceptions\ClientException( plugin_lang_get( 'action_unavailable' ), ERROR_BUG_CONFLICTING_EDIT );
}

# One conditional UPDATE is the race gate: only one concurrent developer can
# claim an unassigned issue while it remains in the eligible state.
db_param_push();
$t_query = 'UPDATE {bug} SET status=' . db_param() . ', handler_id=' . db_param() . ', last_updated=' . db_param()
	. ' WHERE id=' . db_param() . ' AND status IN (' . db_param() . ',' . db_param() . ')'
	. ' AND (handler_id=' . db_param() . ' OR handler_id=' . db_param() . ')';
db_query( $t_query, array( IN_PROGRESS, $t_user_id, db_now(), $f_bug_id, ACKNOWLEDGED, ASSIGNED, NO_USER, $t_user_id ) );
if( db_affected_rows() !== 1 ) {
	form_security_purge( 'syncro1_action_start' );
	throw new \Mantis\Exceptions\ClientException( plugin_lang_get( 'action_conflict' ), ERROR_BUG_CONFLICTING_EDIT );
}

history_log_event_direct( $f_bug_id, 'status', $t_bug->status, IN_PROGRESS, $t_user_id );
history_log_event_direct( $f_bug_id, 'handler_id', $t_bug->handler_id, $t_user_id, $t_user_id );
plugin_history_log( $f_bug_id, 'action', '', 'work started', $t_user_id );
email_owner_changed( $f_bug_id, $t_bug->handler_id, $t_user_id );
email_bug_status_changed( $f_bug_id, 'in_progress' );
bug_clear_cache( $f_bug_id );

form_security_purge( 'syncro1_action_start' );
print_header_redirect_view( $f_bug_id );
