const fs = require( 'fs' );
const { test, expect } = require( '@playwright/test' );
const {
	ADMIN,
	MAILPIT_URL,
	addNote,
	changeStatus,
	clearMailpit,
	createAccount,
	expectText,
	issueUrl,
	login,
	mysqlQuery,
	reportBug,
	temporaryFile,
	waitForMail,
	messageDetail,
} = require( './helpers' );

test.describe.configure( { mode: 'serial', timeout: 180_000 } );

const runId = Date.now().toString();
const data = {
	user: {
		username: `e2e_user_${runId}`,
		email: `e2e-user-${runId}@syncro1.com`,
		password: `E2E-user-${runId}-password`,
	},
	developerA: {
		username: `e2e_dev_a_${runId}`,
		email: `e2e-dev-a-${runId}@syncro1.com`,
		password: `E2E-dev-a-${runId}-password`,
	},
	developerB: {
		username: `e2e_dev_b_${runId}`,
		email: `e2e-dev-b-${runId}@syncro1.com`,
		password: `E2E-dev-b-${runId}-password`,
	},
};

test( 'AC-3: administrator creates user and developers; Mailpit activation sets passwords', async ( { browser } ) => {
	await clearMailpit();
	const context = await browser.newContext();
	const page = await context.newPage();
	await login( page, ADMIN );
	data.user = await createAccount( page, data.user, 25 );
	data.developerA = await createAccount( page, data.developerA, 55 );
	data.developerB = await createAccount( page, data.developerB, 55 );

	for( const account of [ data.user, data.developerA, data.developerB ] ) {
		const checkContext = await browser.newContext();
		const check = await checkContext.newPage();
		await login( check, account );
		await expectText( check, new RegExp( account.username ) );
		await checkContext.close();
	}
	await context.close();
} );

test( 'AC-4: invalid domains are rejected on create, administrator edit, and self edit', async ( { browser } ) => {
	const adminContext = await browser.newContext();
	const adminPage = await adminContext.newPage();
	await login( adminPage, ADMIN );

	await adminPage.goto( '/manage_user_create_page.php' );
	await adminPage.locator( '#user-username' ).fill( `rejected_${runId}` );
	await adminPage.locator( '#user-realname' ).fill( 'Rejected Domain' );
	await adminPage.locator( '#email-field' ).fill( `rejected-${runId}@example.net` );
	await adminPage.locator( '#user-access-level' ).selectOption( '25' );
	await adminPage.locator( '#manage-user-create-form input[type="submit"]' ).click();
	await expectText( adminPage, /Invalid e-mail address|Use a company email address ending in/i );

	await adminPage.goto( `/manage_user_edit_page.php?user_id=${data.user.id}` );
	await adminPage.locator( '#email-field' ).fill( `edited-${runId}@example.net` );
	await adminPage.locator( '#edit-user-form button:not([formaction])' ).click();
	await expectText( adminPage, /Invalid e-mail address|Use a company email address ending in/i );
	expect( mysqlQuery( `SELECT email FROM mantis_user_table WHERE id=${data.user.id}` ) ).toBe( data.user.email );

	const userContext = await browser.newContext();
	const userPage = await userContext.newPage();
	await login( userPage, data.user );
	await userPage.goto( '/account_page.php' );
	await userPage.locator( '#email-field' ).fill( `self-edit-${runId}@example.net` );
	await userPage.locator( '#account-update-form input[type="submit"]' ).click();
	await expectText( userPage, /Invalid e-mail address|Use a company email address ending in/i );
	expect( mysqlQuery( `SELECT email FROM mantis_user_table WHERE id=${data.user.id}` ) ).toBe( data.user.email );
	await userContext.close();
	await adminContext.close();
} );

test( 'AC-6: private report attachment is visible to its reporter/developer but not a second user', async ( { browser } ) => {
	const developerContext = await browser.newContext();
	const developer = await developerContext.newPage();
	await login( developer, data.developerA );
	const attachment = temporaryFile( 'txt', 'SYNCRO1 attachment visibility proof\n' );
	data.visibilityBugId = await reportBug( developer, {
		summary: `AC-6 private attachment ${runId}`,
		description: 'Private issue used by the browser acceptance test.',
		private: true,
		filePath: attachment,
	} );
	await expectText( developer, /AC-6 private attachment/ );
	await expect( developer.getByRole( 'link', { name: 'fixture.txt' } ) ).toBeVisible();

	const secondUserContext = await browser.newContext();
	const secondUser = await secondUserContext.newPage();
	await login( secondUser, data.user );
	await secondUser.goto( `/view.php?id=${data.visibilityBugId}` );
	await expectText( secondUser, /Access Denied|not authorized|permission/i );
	await expect( secondUser.getByText( 'AC-6 private attachment' ) ).toHaveCount( 0 );
	await secondUserContext.close();
	await developerContext.close();
} );

test( 'AC-7: forbidden and oversized uploads are refused; a valid download is not executable', async ( { browser } ) => {
	const context = await browser.newContext();
	const developer = await context.newPage();
	await login( developer, data.developerA );
	const safeFile = temporaryFile( 'txt', 'plain text attachment; never executable\n' );
	data.safeBugId = await reportBug( developer, {
		summary: `AC-7 safe attachment ${runId}`,
		description: 'Safe attachment download test.',
		filePath: safeFile,
	} );
	const attachmentLink = developer.locator( 'a[href*="file_download.php"]' ).first();
	await expect( attachmentLink ).toHaveCount( 1 );
	const href = await attachmentLink.getAttribute( 'href' );
	const cookies = await developer.context().cookies();
	const cookieHeader = cookies.map( cookie => `${cookie.name}=${cookie.value}` ).join( '; ' );
	const response = await fetch( new URL( href, developer.url() ), { headers: { cookie: cookieHeader } } );
	const body = await response.text();
	expect( response.status ).toBe( 200 );
	expect( response.headers.get( 'content-disposition' ) ).toMatch( /attachment/i );
	expect( response.headers.get( 'x-content-type-options' ) ).toMatch( /^nosniff(?:,\s*nosniff)*$/i );
	expect( body ).toContain( 'plain text attachment' );
	expect( body ).not.toMatch( /<\?php|<script/i );

	for( const extension of [ 'php', 'html', 'svg' ] ) {
		await developer.goto( '/bug_report_page.php' );
		const form = developer.locator( '#report_bug_form' );
		await form.locator( '#category_id' ).selectOption( { index: 1 } );
		await form.locator( '#summary' ).fill( `AC-7 rejected ${extension} ${runId}` );
		await form.locator( '#description' ).fill( 'Rejected upload.' );
		await developer.locator( 'input[type="file"]' ).setInputFiles( temporaryFile( extension, '<script>alert(1)</script>\n' ) );
		const rejectedPreview = developer.locator( '.dz-preview.dz-error' ).filter( { hasText: `fixture.${extension}` } );
		await expect( rejectedPreview ).toContainText( /cannot upload files of this type|not allowed|invalid/i );
	}

	await developer.goto( '/bug_report_page.php' );
	const oversized = temporaryFile( 'txt', Buffer.alloc( 21 * 1024 * 1024, 'x' ) );
	const oversizedForm = developer.locator( '#report_bug_form' );
	await oversizedForm.locator( '#category_id' ).selectOption( { index: 1 } );
	await oversizedForm.locator( '#summary' ).fill( `AC-7 oversized ${runId}` );
	await oversizedForm.locator( '#description' ).fill( 'Oversized upload.' );
	await developer.locator( 'input[type="file"]' ).setInputFiles( oversized );
	await expect( developer.locator( '.dz-preview' ).filter( { hasText: 'fixture.txt' } ) ).toHaveCount( 0 );
	await expectText( developer, /Maximum size: 20,480 KiB/i );
	await context.close();
} );

test( 'AC-8: Raise ticket and Start work actions complete through the UI', async ( { browser } ) => {
	const userContext = await browser.newContext();
	const developerContext = await browser.newContext();
	const user = await userContext.newPage();
	const developer = await developerContext.newPage();
	await login( user, data.user );
	await login( developer, data.developerA );
	const bugId = await reportBug( user, { summary: `AC-8 action flow ${runId}` } );
	await issueUrl( developer, bugId );
	await expect( developer.locator( 'form.syncro1-action-form' ).filter( { hasText: 'Raise ticket' } ) ).toBeVisible();
	await developer.locator( 'form.syncro1-action-form' ).filter( { hasText: 'Raise ticket' } ).getByRole( 'button' ).click();
	await developer.waitForLoadState( 'domcontentloaded' );
	await expectText( developer, /ticket raised/i );
	await expect( developer.locator( 'form.syncro1-action-form' ).filter( { hasText: 'Start work' } ) ).toBeVisible();
	await developer.locator( 'form.syncro1-action-form' ).filter( { hasText: 'Start work' } ).getByRole( 'button' ).click();
	await developer.waitForLoadState( 'domcontentloaded' );
	await expectText( developer, /in progress/i );
	await developerContext.close();
	await userContext.close();
} );

test( 'AC-9: reporter can reopen a resolved issue but cannot close it', async ( { browser } ) => {
	const userContext = await browser.newContext();
	const developerContext = await browser.newContext();
	const user = await userContext.newPage();
	const developer = await developerContext.newPage();
	await login( user, data.user );
	await login( developer, data.developerA );
	const bugId = await reportBug( user, { summary: `AC-9 reopen permissions ${runId}` } );
	await issueUrl( developer, bugId );
	await developer.locator( 'form.syncro1-action-form' ).filter( { hasText: 'Raise ticket' } ).getByRole( 'button' ).click();
	await developer.waitForLoadState( 'domcontentloaded' );
	await developer.locator( 'form.syncro1-action-form' ).filter( { hasText: 'Start work' } ).getByRole( 'button' ).click();
	await developer.waitForLoadState( 'domcontentloaded' );
	await changeStatus( developer, bugId, 80 );
	await developer.locator( '#bug-change-status-form input[type="submit"]' ).click();
	await developer.waitForLoadState( 'domcontentloaded' );
	await expectText( developer, /resolved/i );

	await changeStatus( user, bugId, 10, 'reopen' );
	await user.locator( '#bug-change-status-form input[type="submit"]' ).click();
	await user.waitForLoadState( 'domcontentloaded' );
	await expectText( user, /new/i );

	await changeStatus( user, bugId, 90, 'close' );
	await expectText( user, /Access Denied|permission/i );
	await expect( mysqlQuery( `SELECT status FROM mantis_bug_table WHERE id=${bugId}` ) ).toBe( '10' );
	await developerContext.close();
	await userContext.close();
} );

test( 'AC-10: public/private notes have matching UI visibility and Mailpit recipients', async ( { browser } ) => {
	const userContext = await browser.newContext();
	const developerContext = await browser.newContext();
	const user = await userContext.newPage();
	const developer = await developerContext.newPage();
	await login( user, data.user );
	await login( developer, data.developerA );
	const bugId = await reportBug( user, { summary: `AC-10 note visibility ${runId}` } );

	await clearMailpit();
	const publicText = `AC-10 public note ${runId}`;
	await addNote( developer, bugId, publicText, false );
	const publicMessages = await waitForMail( message => message.Subject.includes( `AC-10 note visibility ${runId}` ) );
	const publicRecipients = ( await Promise.all( publicMessages.map( messageDetail ) ) )
		.flatMap( message => message.To.map( recipient => recipient.Address.toLowerCase() ) );
	expect( publicRecipients ).toContain( data.user.email.toLowerCase() );
	await issueUrl( user, bugId );
	await expectText( user, publicText );

	await clearMailpit();
	const privateText = `AC-10 private note ${runId}`;
	await addNote( developer, bugId, privateText, true );
	await new Promise( resolve => setTimeout( resolve, 1_000 ) );
	const privateMailResponse = await fetch( `${ MAILPIT_URL }/api/v1/messages?limit=500` );
	const privateMail = await privateMailResponse.json();
	const privateMessages = privateMail.messages.filter( message => message.Subject.includes( `AC-10 note visibility ${runId}` ) );
	expect( privateMessages ).toHaveLength( 0 );
	await issueUrl( user, bugId );
	await expect( user.getByText( privateText ) ).toHaveCount( 0 );
	await issueUrl( developer, bugId );
	await expectText( developer, privateText );
	await developerContext.close();
	await userContext.close();
} );

test( 'AC-13: lost-password request arrives in Mailpit and the new password logs in', async ( { browser } ) => {
	await clearMailpit();
	const context = await browser.newContext();
	const page = await context.newPage();
	await page.goto( '/lost_pwd_page.php' );
	await page.locator( '#username' ).fill( data.user.username );
	await page.locator( '#email-field' ).fill( data.user.email );
	await page.locator( '#lost-password-form input[type="submit"]' ).click();
	await page.waitForLoadState( 'domcontentloaded' );
	await expect( page ).toHaveURL( /login_page\.php/ );

	const messages = await waitForMail( message =>
		message.To.some( recipient => recipient.Address.toLowerCase() === data.user.email.toLowerCase() )
		&& /password/i.test( message.Subject )
	);
	const detail = await messageDetail( messages[0] );
	const resetUrl = require( './helpers' ).extractUrl( detail.Text );
	const resetPage = await context.newPage();
	await resetPage.goto( resetUrl );
	const newPassword = `E2E-reset-${runId}-password`;
	await resetPage.locator( '#password' ).fill( newPassword );
	await resetPage.locator( '#password-confirm' ).fill( newPassword );
	await resetPage.locator( '#account-update-form button[type="submit"]' ).click();
	await resetPage.waitForLoadState( 'domcontentloaded' );
	await resetPage.close();
	data.user.password = newPassword;

	const loggedIn = await context.newPage();
	await login( loggedIn, { ...data.user, password: newPassword } );
	await expectText( loggedIn, new RegExp( data.user.username ) );
	await context.close();
} );

test( 'AC-11/AC-12: external exposure, headers, and failure responses are safe', async ( { request } ) => {
	for( const target of [
		'/admin/', '/config/', '/.git/', '/vendor/', '/doc/', '/tests/', '/api/soap/', '/rss.php',
		'/uploads/fixture.txt', '/var/lib/syncro1/uploads/fixture.txt', '/syncro1/uploads/fixture.txt',
	] ) {
		const response = await request.get( target );
		expect( [ 403, 404 ] ).toContain( response.status() );
	}

	const loginResponse = await request.get( '/login_page.php' );
	expect( loginResponse.headers()['x-content-type-options'] ).toMatch( /^nosniff(?:,\s*nosniff)*$/i );
	expect( loginResponse.headers()['x-frame-options'] ).toMatch( /DENY|SAMEORIGIN/i );
	expect( loginResponse.headers()['referrer-policy'] ).toBe( 'strict-origin-when-cross-origin' );

	const forcedFailure = await request.get( '/file_download.php?file_id=999999999' );
	const failureBody = await forcedFailure.text();
	expect( failureBody ).not.toMatch( /PHP (Warning|Notice|Fatal error)|Stack trace|Undefined variable/i );
} );

test( 'AC-8 concurrency: two authenticated developers race Start work 20 times', async ( { browser } ) => {
	const userContext = await browser.newContext();
	const devAContext = await browser.newContext();
	const devBContext = await browser.newContext();
	const user = await userContext.newPage();
	const devA = await devAContext.newPage();
	const devB = await devBContext.newPage();
	await login( user, data.user );
	await login( devA, data.developerA );
	await login( devB, data.developerB );

	const results = [];
	for( let round = 1; round <= 20; round++ ) {
		const bugId = await reportBug( user, { summary: `AC-8 concurrency ${runId}-${round}` } );
		await issueUrl( devA, bugId );
		await devA.locator( 'form.syncro1-action-form' ).filter( { hasText: 'Raise ticket' } ).getByRole( 'button' ).click();
		await devA.waitForLoadState( 'domcontentloaded' );
		await issueUrl( devA, bugId );
		await issueUrl( devB, bugId );
		const startA = devA.locator( 'form.syncro1-action-form' ).filter( { hasText: 'Start work' } ).getByRole( 'button' );
		const startB = devB.locator( 'form.syncro1-action-form' ).filter( { hasText: 'Start work' } ).getByRole( 'button' );
		const outcomes = await Promise.all( [
			startA.click().then( () => 'ok' ).catch( () => 'error' ),
			startB.click().then( () => 'ok' ).catch( () => 'error' ),
		] );
		await Promise.all( [ devA.waitForLoadState( 'domcontentloaded' ).catch( () => {} ), devB.waitForLoadState( 'domcontentloaded' ).catch( () => {} ) ] );
		const bodies = await Promise.all( [ devA.locator( 'body' ).innerText(), devB.locator( 'body' ).innerText() ] );
		const winnerCount = Number( mysqlQuery( `SELECT COUNT(*) FROM mantis_bug_history_table WHERE bug_id=${bugId} AND field_name='status' AND new_value='60'` ) );
		const handlerCount = Number( mysqlQuery( `SELECT COUNT(*) FROM mantis_bug_history_table WHERE bug_id=${bugId} AND field_name='handler_id' AND new_value IN ('${data.developerA.id}','${data.developerB.id}')` ) );
		const actionCount = Number( mysqlQuery( `SELECT COUNT(*) FROM mantis_bug_history_table WHERE bug_id=${bugId} AND LOWER(field_name) LIKE '%_action' AND new_value='work started'` ) );
		const status = mysqlQuery( `SELECT status FROM mantis_bug_table WHERE id=${bugId}` );
		const refusal = bodies.some( body => /already taken|no longer available|conflict|updated by another user/i.test( body ) );
		expect( winnerCount, `round ${round}: status history` ).toBe( 1 );
		expect( handlerCount, `round ${round}: handler history` ).toBe( 1 );
		expect( actionCount, `round ${round}: plugin history` ).toBe( 1 );
		expect( status, `round ${round}: final status` ).toBe( '60' );
		expect( refusal, `round ${round}: loser refusal; outcomes ${outcomes}` ).toBeTruthy();
		results.push( { round, bugId, outcomes, status, winnerCount, handlerCount, actionCount } );
	}
	console.log( `AC-8 concurrency results: ${JSON.stringify( results )}` );
	await devBContext.close();
	await devAContext.close();
	await userContext.close();
} );
