const fs = require( 'fs' );
const os = require( 'os' );
const path = require( 'path' );
const { execFileSync } = require( 'child_process' );
const { expect } = require( '@playwright/test' );

const BASE_URL = process.env.SYNCRO1_BASE_URL || 'http://localhost:8080';
const MAILPIT_URL = process.env.MAILPIT_URL || 'http://localhost:8025';
const COMPOSE_FILE = path.resolve( __dirname, '..', 'syncro1/docker/docker-compose.yml' );

function readDotEnv() {
	const values = {};
	const envPath = path.resolve( __dirname, '..', '.env' );
	if( !fs.existsSync( envPath ) ) {
		return values;
	}
	for( const line of fs.readFileSync( envPath, 'utf8' ).split( /\r?\n/ ) ) {
		const match = line.match( /^([A-Z0-9_]+)=(.*)$/ );
		if( match ) {
			values[match[1]] = match[2];
		}
	}
	return values;
}

const DOT_ENV = readDotEnv();
let lastLoginAt = 0;

function env( name, fallback ) {
	return process.env[name] || DOT_ENV[name] || fallback;
}

const ADMIN = {
	username: env( 'ADMIN_USERNAME', 'syn_admin' ),
	password: env( 'ADMIN_INITIAL_PASSWORD', 'change-this-local-password-16' ),
	email: env( 'ADMIN_EMAIL', 'admin@syncro1.com' ),
};

function sleep( milliseconds ) {
	return new Promise( resolve => setTimeout( resolve, milliseconds ) );
}

async function login( page, account ) {
	const minimumInterval = 6_500;
	const elapsed = Date.now() - lastLoginAt;
	if( elapsed < minimumInterval ) {
		await sleep( minimumInterval - elapsed );
	}
	lastLoginAt = Date.now();
	await page.goto( '/login_page.php' );
	await page.locator( '#username' ).fill( account.username );
	await page.locator( '#login-form input[type="submit"]' ).click();
	await page.locator( '#password' ).fill( account.password );
	await page.locator( 'input[type="submit"]' ).click();
	await page.waitForLoadState( 'domcontentloaded' );
	await expectNotLogin( page );
}

async function expectNotLogin( page ) {
	if( /login(?:_password)?_page\.php/.test( new URL( page.url() ).pathname ) ) {
		throw new Error( `Login failed: ${page.url()}\n${( await page.locator( 'body' ).innerText() ).slice( 0, 1000 )}` );
	}
}

async function logout( page ) {
	await page.goto( '/logout_page.php' );
}

async function waitForMessages( predicate, timeout = 15_000 ) {
	const deadline = Date.now() + timeout;
	while( Date.now() < deadline ) {
		const response = await fetch( `${MAILPIT_URL}/api/v1/messages?limit=500` );
		if( response.ok ) {
			const data = await response.json();
			const matches = data.messages.filter( predicate );
			if( matches.length > 0 ) {
				return matches;
			}
		}
		await sleep( 250 );
	}
	throw new Error( 'Timed out waiting for Mailpit message' );
}

async function messageDetail( message ) {
	const response = await fetch( `${MAILPIT_URL}/api/v1/message/${message.ID}` );
	if( !response.ok ) {
		throw new Error( `Mailpit message lookup failed: ${response.status}` );
	}
	return response.json();
}

function extractUrl( text ) {
	const match = text.match( /https?:\/\/\S+/ );
	if( !match ) {
		throw new Error( `No URL found in message:\n${text}` );
	}
	return match[0].replace( /[\r\n]+$/, '' );
}

async function clearMailpit() {
	const response = await fetch( `${MAILPIT_URL}/api/v1/messages`, { method: 'DELETE' } );
	if( !response.ok ) {
		throw new Error( `Unable to clear Mailpit: ${response.status}` );
	}
}

async function createAccount( adminPage, account, accessLevel ) {
	await adminPage.goto( '/manage_user_create_page.php' );
	const form = adminPage.locator( '#manage-user-create-form' );
	await form.locator( '#user-username' ).fill( account.username );
	await form.locator( '#user-realname' ).fill( account.realname || account.username );
	await form.locator( '#email-field' ).fill( account.email );
	await form.locator( '#user-access-level' ).selectOption( String( accessLevel ) );
	await form.locator( 'input[type="submit"]' ).click( { force: true } );
	await adminPage.waitForLoadState( 'domcontentloaded' );
	await expectText( adminPage, new RegExp( `Created user ${account.username}` ) );

	const messages = await waitForMessages( message =>
		message.To.some( recipient => recipient.Address.toLowerCase() === account.email.toLowerCase() )
		&& /Account registration/i.test( message.Subject )
	);
	const detail = await messageDetail( messages[0] );
	const activationUrl = extractUrl( detail.Text );
	// verify.php deliberately logs out an already-authenticated session. Keep
	// the administrator session in a separate browser context while activating.
	const activationContext = await adminPage.context().browser().newContext();
	const activationPage = await activationContext.newPage();
	await activationPage.goto( activationUrl );
	await expectText( activationPage, /must set a password/i );
	await activationPage.locator( '#password' ).fill( account.password );
	await activationPage.locator( '#password-confirm' ).fill( account.password );
	await activationPage.locator( '#account-update-form button[type="submit"]' ).click();
	await activationPage.waitForLoadState( 'domcontentloaded' );
	await expectText( activationPage, /login/i );
	await activationContext.close();

	return {
		...account,
		id: Number( new URL( activationUrl ).searchParams.get( 'id' ) ),
	};
}

async function expectText( page, text ) {
	await expect( page.locator( 'body' ) ).toContainText( text );
}

async function reportBug( page, options ) {
	await page.goto( '/bug_report_page.php' );
	const form = page.locator( '#report_bug_form' );
	await form.locator( '#category_id' ).selectOption( { index: 1 } );
	const productVersion = form.locator( '#product_version option[value="1.0.0"]' );
	if( await productVersion.count() ) {
		await form.locator( '#product_version' ).selectOption( '1.0.0' );
	}
	await form.locator( '#summary' ).fill( options.summary );
	await form.locator( '#description' ).fill( options.description || options.summary );
	await form.locator( '#steps_to_reproduce' ).fill( '1. Open the issue.\n2. Observe the result.' );
	if( options.private ) {
		await form.locator( 'input[name="view_state"][value="50"]' ).check( { force: true } );
	} else {
		await form.locator( 'input[name="view_state"][value="10"]' ).check( { force: true } );
	}
	if( options.filePath ) {
		// MantisBT's Dropzone input is injected directly under <body>, outside
		// the issue form. The queued file is submitted with the form's hidden
		// fields when the issue is created.
		await page.locator( 'input[type="file"]' ).setInputFiles( options.filePath );
	}
	const viewResponsePromise = page.waitForResponse( response =>
		/(?:bug_view_page|view)\.php\?id=\d+/.test( response.url() ) && response.status() === 200
	);
	await form.locator( 'input[type="submit"][value="Submit Issue"]' ).click();
	const viewResponse = await viewResponsePromise;
	const viewUrl = new URL( viewResponse.url() );
	await page.goto( `${ viewUrl.pathname }${ viewUrl.search }` );
	const match = page.url().match( /[?&]id=(\d+)/ );
	if( !match ) {
		throw new Error( `Issue was not created: ${page.url()}\n${( await page.locator( 'body' ).innerText() ).slice( 0, 3000 )}` );
	}
	return Number( match[1] );
}

async function issueUrl( page, bugId ) {
	await page.goto( `/view.php?id=${bugId}` );
}

async function changeStatus( page, bugId, status, changeType = 'change_status' ) {
	await page.goto( `/bug_change_status_page.php?id=${bugId}&new_status=${status}&change_type=${changeType}` );
	return page;
}

async function addNote( page, bugId, text, isPrivate ) {
	await issueUrl( page, bugId );
	const form = page.locator( '#bugnoteadd' );
	await form.locator( '#bugnote_text' ).fill( text );
	const privateCheckbox = form.locator( '#bugnote_add_view_status' );
	await privateCheckbox.evaluate( ( checkbox, checked ) => {
		checkbox.checked = checked;
		checkbox.dispatchEvent( new Event( 'change', { bubbles: true } ) );
	}, isPrivate );
	const noteResponsePromise = page.waitForResponse( response =>
		/\/bugnote_add\.php$/.test( response.url() ) && response.request().method() === 'POST'
	);
	// The fixed issue-actions header can cover the note button at the native
	// click coordinate. Invoke the same form submit control through the DOM,
	// then reload the resulting issue view after the POST is observed.
	await form.locator( 'input[type="submit"]' ).evaluate( button => button.click() );
	await noteResponsePromise;
	await sleep( 250 );
	await issueUrl( page, bugId );
	await expectText( page, text );
}

function temporaryFile( extension, content ) {
	const directory = fs.mkdtempSync( path.join( os.tmpdir(), 'syncro1-e2e-' ) );
	const filePath = path.join( directory, `fixture.${extension}` );
	fs.writeFileSync( filePath, content );
	return filePath;
}

function mysqlQuery( sql ) {
	const password = env( 'MYSQL_ROOT_PASSWORD', 'change-root-local-password' );
	return execFileSync(
		'docker',
		[ 'compose', '-f', COMPOSE_FILE, 'exec', '-T', 'mysql', 'mysql', '-uroot', `-p${password}`, 'mantis', '-NBe', sql ],
		{ encoding: 'utf8' }
	).trim();
}

async function waitForMailpitCount( expected ) {
	const deadline = Date.now() + 15_000;
	while( Date.now() < deadline ) {
		const response = await fetch( `${MAILPIT_URL}/api/v1/info` );
		const info = await response.json();
		if( info.Messages >= expected ) {
			return info.Messages;
		}
		await sleep( 250 );
	}
	throw new Error( `Timed out waiting for ${expected} Mailpit messages` );
}

module.exports = {
	ADMIN,
	BASE_URL,
	MAILPIT_URL,
	addNote,
	changeStatus,
	clearMailpit,
	createAccount,
	expectText,
	extractUrl,
	issueUrl,
	login,
	logout,
	messageDetail,
	mysqlQuery,
	reportBug,
	temporaryFile,
	waitForMail: waitForMessages,
	waitForMailpitCount,
};
