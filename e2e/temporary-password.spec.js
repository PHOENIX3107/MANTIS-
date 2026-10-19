const { test, expect } = require( '@playwright/test' );
const {
	ADMIN,
	clearMailpit,
	expectText,
	login,
	mysqlQuery,
} = require( './helpers' );

test.describe.configure( { mode: 'serial', timeout: 90_000 } );

test( 'administrator can create a user with a temporary password', async ( { browser } ) => {
	const runId = Date.now().toString();
	const account = {
		username: `temporary_${runId}`,
		email: `temporary-${runId}@syncro1.com`,
		password: `Temporary-${runId}-Pass!`,
		newPassword: `Changed-${runId}-Pass!`,
	};
	await clearMailpit();

	const adminContext = await browser.newContext();
	const adminPage = await adminContext.newPage();
	await login( adminPage, ADMIN );
	await adminPage.goto( '/manage_user_create_page.php' );
	const form = adminPage.locator( '#manage-user-create-form' );
	await form.locator( '#user-username' ).fill( account.username );
	await form.locator( '#user-realname' ).fill( 'Temporary Password User' );
	await form.locator( '#email-field' ).fill( account.email );
	await form.locator( '#user-access-level' ).selectOption( '25' );
	await form.locator( '#user-use-temporary-password' ).check( { force: true } );
	await form.locator( '#user-temporary-password' ).fill( 'too-short' );
	await form.locator( '#user-temporary-password-verify' ).fill( 'too-short' );
	await form.locator( '#user-temporary-password, #user-temporary-password-verify' ).evaluateAll( inputs => inputs.forEach( input => input.removeAttribute( 'minlength' ) ) );
	await form.locator( 'input[type="submit"]' ).click( { force: true } );
	await expectText( adminPage, /Invalid value|temporary_password/i );
	expect( mysqlQuery( `SELECT COUNT(*) FROM mantis_user_table WHERE username='${account.username}'` ) ).toBe( '0' );

	await adminPage.goto( '/manage_user_create_page.php' );
	const retryForm = adminPage.locator( '#manage-user-create-form' );
	await retryForm.locator( '#user-username' ).fill( account.username );
	await retryForm.locator( '#user-realname' ).fill( 'Temporary Password User' );
	await retryForm.locator( '#email-field' ).fill( account.email );
	await retryForm.locator( '#user-access-level' ).selectOption( '25' );
	await retryForm.locator( '#user-use-temporary-password' ).check( { force: true } );
	await retryForm.locator( '#user-temporary-password' ).fill( account.password );
	await retryForm.locator( '#user-temporary-password-verify' ).fill( account.password );
	await retryForm.locator( 'input[type="submit"]' ).click( { force: true } );
	await adminPage.waitForLoadState( 'domcontentloaded' );
	await expectText( adminPage, /Temporary password set/i );

	const userId = Number( mysqlQuery( `SELECT id FROM mantis_user_table WHERE username='${account.username}'` ) );
	const storedPassword = mysqlQuery( `SELECT password FROM mantis_user_table WHERE id=${userId}` );
	expect( storedPassword ).not.toBe( account.password );
	expect( storedPassword ).not.toContain( account.password );
	const mailpitMessages = await ( await fetch( 'http://localhost:8025/api/v1/messages?limit=500' ) ).json();
	expect( mailpitMessages.messages.some( message => message.To.some( recipient => recipient.Address.toLowerCase() === account.email ) ) ).toBeFalsy();

	const userContext = await browser.newContext();
	const userPage = await userContext.newPage();
	await login( userPage, account );
	await expectText( userPage, new RegExp( account.username ) );

	await userPage.goto( '/account_page.php' );
	await userPage.locator( '#password-current' ).fill( account.password );
	await userPage.locator( '#password' ).fill( account.newPassword );
	await userPage.locator( '#password-confirm' ).fill( account.newPassword );
	await userPage.locator( '#account-update-form input[type="submit"]' ).click();
	await userPage.waitForLoadState( 'domcontentloaded' );

	const changedContext = await browser.newContext();
	const changedPage = await changedContext.newPage();
	await login( changedPage, { ...account, password: account.newPassword } );
	await expectText( changedPage, new RegExp( account.username ) );

	await changedContext.close();
	await userContext.close();
	await adminContext.close();
	mysqlQuery( `DELETE FROM mantis_user_table WHERE id=${userId}` );
} );

