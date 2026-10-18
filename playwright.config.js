const { defineConfig } = require( '@playwright/test' );

module.exports = defineConfig( {
	testDir: './e2e',
	testMatch: '**/*.spec.js',
	fullyParallel: false,
	workers: 1,
	retries: 0,
	timeout: 45_000,
	expect: {
		timeout: 10_000,
	},
	use: {
		baseURL: process.env.SYNCRO1_BASE_URL || 'http://localhost:8080',
		browserName: 'chromium',
		headless: process.env.HEADED !== '1',
		trace: 'off',
		screenshot: 'only-on-failure',
		video: 'off',
	},
	reporter: [ [ 'list' ], [ 'json', { outputFile: 'test-results/playwright.json' } ] ],
} );
