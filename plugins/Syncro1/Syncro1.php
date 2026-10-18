<?php
/**
 * SYNCRO1 MantisBT integration plugin.
 *
 * GPL-2.0-or-later; see the upstream MantisBT license and copyright headers.
 */

use Mantis\Exceptions\ClientException;

require_once __DIR__ . '/EmailPolicy.php';

class Syncro1Plugin extends MantisPlugin {
	public function register() {
		$this->name = plugin_lang_get( 'title' );
		$this->description = plugin_lang_get( 'description' );
		$this->page = '';
		$this->version = MANTIS_VERSION;
		$this->requires = array( 'MantisCore' => '2.28.0' );
		$this->author = 'SYNCRO1';
		$this->contact = 'admin@syncro1.com';
		$this->url = 'https://syncro1.com';
	}

	public function hooks() {
		return array(
			'EVENT_LAYOUT_RESOURCES' => 'resources',
			'EVENT_VIEW_BUG_EXTRA' => 'issue_actions',
			'EVENT_UPDATE_BUG_DATA' => 'guard_bug_update',
			'EVENT_USER_EMAIL_VALIDATE' => 'validate_user_email',
		);
	}

	public function resources() {
		echo '<link rel="stylesheet" href="' . string_attribute( plugin_file( 'syncro1.css' ) ) . '">' . "\n";
		echo '<link rel="icon" type="image/svg+xml" href="' . string_attribute( plugin_file( 'syncro1-logo.svg' ) ) . '">' . "\n";
	}

	/**
	 * Strict company-domain policy. The upstream limit_email_domains option is
	 * still configured as primary control; this callback protects all common API
	 * paths before a user row is created or updated.
	 */
	public function validate_user_email( $p_event, $user_id, $email, $operation ) {
		$t_email = is_string( $email ) ? $email : '';
		$t_allowed = config_get_global( 'limit_email_domains' );
		if( !is_array( $t_allowed ) ) {
			$t_allowed = array();
		}
		$t_allowed = array_values( array_filter( array_map( 'strtolower', array_map( 'trim', $t_allowed ) ), 'strlen' ) );
		$t_allowed_text = implode( ', ', array_map( static function( $p_domain ) { return '@' . $p_domain; }, $t_allowed ) );

		# A caller must provide an exact address. Do not silently canonicalize user input.
		$t_valid = syncro1_email_is_allowed( $t_email, $t_allowed );

		if( !$t_valid ) {
			throw new ClientException(
				sprintf( plugin_lang_get( 'email_domain_error' ), $t_allowed_text ),
				ERROR_EMAIL_INVALID
			);
		}
	}

	/**
	 * Enforce role/status rules on native update forms and API calls too. The
	 * native Mantis checks remain active; this plugin guard protects the custom
	 * status and reporter reopen semantics consistently.
	 */
	public function guard_bug_update( $p_event, $p_updated_bug, $p_existing_bug ) {
		if( $p_updated_bug->status === $p_existing_bug->status ) {
			if( $p_updated_bug->status === IN_PROGRESS && $p_updated_bug->handler_id === NO_USER
				&& access_has_bug_level( DEVELOPER, $p_existing_bug->id ) ) {
				$p_updated_bug->handler_id = auth_get_current_user_id();
			}
			return $p_updated_bug;
		}

		if( !bug_check_workflow( $p_existing_bug->status, $p_updated_bug->status ) ) {
			throw new ClientException( plugin_lang_get( 'workflow_error' ), ERROR_CUSTOM_FIELD_INVALID_VALUE );
		}

		$t_user_id = auth_get_current_user_id();
		$t_reporter_reopen = $p_existing_bug->reporter_id === $t_user_id
			&& $p_existing_bug->status >= RESOLVED
			&& $p_updated_bug->status === config_get( 'bug_reopen_status' )
			&& config_get( 'allow_reporter_reopen' );
		if( !access_has_bug_level( DEVELOPER, $p_existing_bug->id ) && !$t_reporter_reopen ) {
			throw new ClientException( plugin_lang_get( 'status_access_error' ), ERROR_ACCESS_DENIED );
		}

		if( $p_updated_bug->status === IN_PROGRESS && $p_updated_bug->handler_id === NO_USER ) {
			$p_updated_bug->handler_id = $t_user_id;
		}
		return $p_updated_bug;
	}

	/** Render action forms after the issue notes, using the verified view event. */
	public function issue_actions( $p_event, $p_bug_id ) {
		if( !auth_is_user_authenticated() || !access_has_bug_level( DEVELOPER, $p_bug_id ) ) {
			return;
		}
		$t_bug = bug_get( $p_bug_id, true );
		$t_can_raise = in_array( (int)$t_bug->status, array( NEW_, FEEDBACK ), true );
		$t_can_start = in_array( (int)$t_bug->status, array( ACKNOWLEDGED, ASSIGNED ), true );
		if( !$t_can_raise && !$t_can_start ) {
			return;
		}

		echo '<div class="syncro1-issue-actions widget-box widget-color-blue2">';
		echo '<div class="widget-header widget-header-small"><h4 class="widget-title lighter">'
			. string_display_line( plugin_lang_get( 'actions_title' ) ) . '</h4></div><div class="widget-body"><div class="widget-main">';
		if( $t_can_raise ) {
			$this->render_action_form( 'action_raise', $p_bug_id, plugin_lang_get( 'raise_ticket' ) );
		}
		if( $t_can_start ) {
			$this->render_action_form( 'action_start', $p_bug_id, plugin_lang_get( 'start_work' ) );
		}
		echo '</div></div></div>';
	}

	private function render_action_form( $p_page, $p_bug_id, $p_label ) {
		echo '<form method="post" action="' . string_attribute( plugin_page( $p_page ) ) . '" class="syncro1-action-form">';
		echo form_security_field( 'syncro1_' . $p_page );
		echo '<input type="hidden" name="bug_id" value="' . (int)$p_bug_id . '">';
		echo '<button type="submit" class="btn btn-sm btn-primary btn-white btn-round">' . string_display_line( $p_label ) . '</button>';
		echo '</form>';
	}
}
