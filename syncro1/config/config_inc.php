<?php
/**
 * SYNCRO1 environment-driven MantisBT configuration.
 *
 * This is a template. It is copied into config/config_inc.php by the Docker
 * image and rendered from the same source by production deployment scripts.
 */

if( !function_exists( 'syncro1_env' ) ) {
	function syncro1_env( $p_name, $p_default = null, $p_required = false ) {
		$t_value = getenv( $p_name );
		if( false === $t_value || '' === $t_value ) {
			if( $p_required ) {
				throw new RuntimeException( "SYNCRO1 configuration missing required environment variable: $p_name" );
			}
			return $p_default;
		}
		return $t_value;
	}

	function syncro1_csv_env( $p_name, $p_default ) {
		$t_values = explode( ',', syncro1_env( $p_name, $p_default ) );
		$t_values = array_map( 'trim', $t_values );
		$t_values = array_map( 'strtolower', $t_values );
		return array_values( array_filter( array_unique( $t_values ), 'strlen' ) );
	}
}

$t_syncro1_environment = strtolower( syncro1_env( 'SYNCRO1_ENV', 'development' ) );
$t_syncro1_production = 'production' === $t_syncro1_environment;

$t_syncro1_app_domain = syncro1_env( 'APP_DOMAIN', 'bugs.syncro1.com', $t_syncro1_production );
$t_syncro1_app_url = rtrim( syncro1_env( 'APP_URL', 'http://' . $t_syncro1_app_domain . '/', $t_syncro1_production ), '/' ) . '/';
$t_syncro1_salt = syncro1_env( 'CRYPTO_MASTER_SALT', '', $t_syncro1_production );

$g_path = $t_syncro1_app_url;
$g_hostname = syncro1_env( 'DB_HOST', 'mysql', $t_syncro1_production );
$g_db_username = syncro1_env( 'DB_USER', 'mantis', $t_syncro1_production );
$g_db_password = syncro1_env( 'DB_PASSWORD', 'mantis_local_password', $t_syncro1_production );
$g_database_name = syncro1_env( 'DB_NAME', 'mantis', $t_syncro1_production );
$g_db_type = 'mysqli';
$g_crypto_master_salt = $t_syncro1_salt ?: 'local-only-change-me-0123456789';
$g_default_timezone = syncro1_env( 'APP_TIMEZONE', 'UTC' );
$g_window_title = syncro1_env( 'APP_NAME', 'SYNCRO1 Bug Tracker' );

$g_allow_signup = OFF;
$g_allow_anonymous_login = OFF;
$g_allow_account_delete = OFF;
$g_max_failed_login_count = 5;
$g_limit_email_domains = syncro1_csv_env( 'ALLOWED_EMAIL_DOMAINS', 'syncro1.com,syncrosquad.com' );
$g_allow_blank_email = OFF;

$g_access_levels_enum_string = '10:viewer,25:user,40:updater,55:developer,70:manager,90:administrator';
$g_admin_site_threshold = ADMINISTRATOR;
$g_manage_user_threshold = ADMINISTRATOR;
$g_manage_project_threshold = ADMINISTRATOR;
$g_manage_configuration_threshold = ADMINISTRATOR;
$g_manage_plugin_threshold = ADMINISTRATOR;
$g_default_new_account_access_level = REPORTER;
$g_handle_bug_threshold = DEVELOPER;
$g_update_bug_threshold = DEVELOPER;
$g_update_bug_assign_threshold = DEVELOPER;
$g_monitor_bug_threshold = DEVELOPER;
$g_monitor_add_others_bug_threshold = DEVELOPER;
$g_monitor_delete_others_bug_threshold = DEVELOPER;
$g_show_monitor_list_threshold = DEVELOPER;
$g_view_history_threshold = DEVELOPER;
$g_add_bugnote_threshold = DEVELOPER;
$g_tag_attach_threshold = DEVELOPER;
$g_private_bug_threshold = DEVELOPER;
$g_private_bugnote_threshold = DEVELOPER;
$g_show_user_email_threshold = DEVELOPER;
$g_show_user_realname_threshold = DEVELOPER;
$g_show_realname = OFF;
$g_limit_view_unless_threshold = DEVELOPER;
$g_allow_reporter_reopen = OFF;
$g_allow_reporter_close = OFF;
$g_allow_reporter_upload = ON;
$g_export_issues_threshold = DEVELOPER;
$g_view_summary_threshold = DEVELOPER;
$g_view_changelog_threshold = DEVELOPER;
$g_roadmap_view_threshold = DEVELOPER;

$g_status_enum_string = '10:new,20:feedback,30:ticket raised,40:confirmed,50:assigned,60:in progress,80:resolved,90:closed';
$g_status_colors = array(
	'new' => '#fcbdbd',
	'feedback' => '#e3b7eb',
	'ticket raised' => '#ffcd85',
	'confirmed' => '#fff494',
	'assigned' => '#c2dfff',
	'in progress' => '#b8d8ff',
	'resolved' => '#d2f5b0',
	'closed' => '#c9ccc4',
);
$g_status_enum_workflow = array(
	NEW_ => '30:ticket raised,20:feedback,80:resolved',
	FEEDBACK => '10:new,30:ticket raised,80:resolved',
	ACKNOWLEDGED => '50:assigned,60:in progress,20:feedback,80:resolved',
	ASSIGNED => '60:in progress,30:ticket raised,20:feedback,80:resolved',
	IN_PROGRESS => '80:resolved,50:assigned,20:feedback',
	RESOLVED => '10:new,90:closed,60:in progress',
	CLOSED => '50:assigned',
);
$g_set_status_threshold = array(
	NEW_ => DEVELOPER,
	FEEDBACK => DEVELOPER,
	ACKNOWLEDGED => DEVELOPER,
	ASSIGNED => DEVELOPER,
	IN_PROGRESS => DEVELOPER,
	RESOLVED => DEVELOPER,
	CLOSED => DEVELOPER,
);
$g_update_bug_status_threshold = DEVELOPER;
$g_reopen_bug_threshold = DEVELOPER;
$g_bug_resolved_status_threshold = RESOLVED;
$g_bug_closed_status_threshold = CLOSED;
$g_bug_readonly_status_threshold = RESOLVED;
$g_bug_submit_status = NEW_;
$g_bug_feedback_status = FEEDBACK;
$g_bug_assigned_status = ASSIGNED;
$g_bug_reopen_status = NEW_;

$g_bug_report_page_fields = array(
	'attachments', 'category_id', 'os', 'os_build', 'platform', 'product_build',
	'product_version', 'reproducibility', 'severity', 'steps_to_reproduce',
	'additional_info', 'view_state',
);
$g_bug_view_page_fields = array(
	'attachments', 'category_id', 'date_submitted', 'description', 'handler', 'id',
	'last_updated', 'os', 'os_build', 'platform', 'product_build', 'product_version',
	'project', 'reporter', 'reproducibility', 'resolution', 'severity', 'status',
	'steps_to_reproduce', 'summary', 'view_state', 'additional_info',
);
$g_bug_update_page_fields = array(
	'attachments', 'additional_info', 'category_id', 'description', 'handler', 'id',
	'os', 'os_build', 'platform', 'priority', 'product_build', 'product_version',
	'project', 'reproducibility', 'resolution', 'severity', 'status',
	'steps_to_reproduce', 'summary', 'target_version', 'view_state',
);

$t_syncro1_max_upload_mb = max( 1, (int)syncro1_env( 'MAX_UPLOAD_MB', '20' ) );
$g_allow_file_upload = ON;
$g_file_upload_method = DATABASE;
$g_absolute_path_default_upload_folder = rtrim( syncro1_env( 'UPLOAD_DIR', '/var/lib/syncro1/uploads' ), DIRECTORY_SEPARATOR ) . DIRECTORY_SEPARATOR;
$g_attachments_file_permissions = 0400;
$g_max_file_size = $t_syncro1_max_upload_mb * 1024 * 1024;
$g_allowed_files = 'png,jpg,jpeg,gif,webp,txt';
$g_disallowed_files = 'php,php3,php4,php5,php6,php7,php8,phtml,phar,exe,bat,cmd,sh,js,html,htm,xhtml,svg,jsp,asp,aspx';
$g_file_download_xsendfile_enabled = OFF;

$g_phpMailer_method = PHPMAILER_METHOD_SMTP;
$g_smtp_host = syncro1_env( 'SMTP_HOST', 'mailpit', $t_syncro1_production );
$g_smtp_port = (int)syncro1_env( 'SMTP_PORT', '1025', $t_syncro1_production );
$g_smtp_username = syncro1_env( 'SMTP_USER', '' );
$g_smtp_password = syncro1_env( 'SMTP_PASS', '' );
$g_smtp_connection_mode = $t_syncro1_production ? 'tls' : '';
$g_from_email = syncro1_env( 'MAIL_FROM', 'bugs@syncro1.com', $t_syncro1_production );
$g_return_path_email = $g_from_email;
$g_webmaster_email = syncro1_env( 'ADMIN_EMAIL', 'admin@syncro1.com', $t_syncro1_production );
$g_from_name = syncro1_env( 'APP_NAME', 'SYNCRO1 Bug Tracker' );
$g_enable_email_notification = ON;
$g_send_reset_password = ON;
$g_email_send_using_cronjob = ( 'production' === $t_syncro1_environment ) ? ON : OFF;

$g_news_enabled = OFF;
$g_enable_sponsorship = OFF;
$g_time_tracking_enabled = OFF;
$g_time_tracking_with_billing = OFF;
$g_rss_enabled = OFF;
$g_wiki_enable = OFF;
$g_show_version = OFF;
$g_webservice_rest_enabled = OFF;
$g_cookie_samesite = 'Strict';
$g_form_security_validation = ON;
$g_session_validation = ON;
$g_display_errors = array();
$g_show_detailed_errors = OFF;
$g_log_level = LOG_EMAIL | LOG_DATABASE | LOG_USER;
$g_log_destination = 'file:/var/log/syncro1/mantis.log';
