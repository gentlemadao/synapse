const puppeteer = require('puppeteer-core');
const { spawn } = require('child_process');
const http = require('http');

const PORT = 8080;
const URL = `http://localhost:${PORT}`;
const CHROME_PATH = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';

function waitForServer(timeout = 10000) {
    return new Promise((resolve, reject) => {
        const start = Date.now();
        const interval = setInterval(() => {
            if (Date.now() - start > timeout) {
                clearInterval(interval);
                reject(new Error("Timeout waiting for server to start"));
                return;
            }
            http.get(URL, (res) => {
                if (res.statusCode === 200) {
                    clearInterval(interval);
                    resolve();
                }
            }).on('error', () => {
                // Keep trying
            });
        }, 500);
    });
}

async function run() {
    console.log("Starting local COOP/COEP Python server...");
    const server = spawn('python3', ['serve_web.py'], { stdio: 'inherit' });

    try {
        console.log("Waiting for server to become responsive...");
        await waitForServer();
        console.log("Server is ready!");

        console.log(`Launching Chrome from: ${CHROME_PATH}`);
        const browser = await puppeteer.launch({
            executablePath: CHROME_PATH,
            headless: true,
            args: [
                '--no-sandbox',
                '--disable-setuid-sandbox',
                '--enable-features=SharedArrayBuffer',
            ]
        });

        // Create a completely clean incognito context to bypass any registered service workers
        const context = await browser.createBrowserContext();
        const page = await context.newPage();
        const logs = [];
        const errors = [];

        page.on('console', msg => {
            const text = msg.text();
            console.log(`[Browser Console] ${msg.type().toUpperCase()}: ${text}`);
            logs.push(text);
        });

        page.on('pageerror', err => {
            console.error(`[Browser PageError] Message:`, err.message);
            console.error(`[Browser PageError] Stack:`, err.stack || err);
            errors.push(err.stack || err.toString());
        });

        page.on('error', err => {
            console.error('[Browser Crash Error]:', err);
            errors.push(err.toString());
        });

        page.on('requestfailed', request => {
            console.warn(`[Network Request Failed] ${request.url()} - ${request.failure() ? request.failure().errorText : 'Unknown'}`);
        });

        console.log(`Navigating to ${URL}...`);
        await page.goto(URL, { waitUntil: 'networkidle0', timeout: 15000 });

        const isolated = await page.evaluate(() => window.crossOriginIsolated);
        console.log(`[Browser Info] window.crossOriginIsolated: ${isolated}`);

        console.log("Waiting 5 seconds for WebAssembly, workers, and Bevy to initialize...");
        await new Promise(r => setTimeout(r, 5000));

        const html = await page.content();
        console.log("-----------------------------------------");
        console.log("HTML CONTENT OF THE PAGE:");
        console.log(html);
        console.log("-----------------------------------------");

        // Evaluate if any error was thrown
        const panicOrCloneError = logs.concat(errors).some(log => 
            log.includes('panicked') || 
            log.includes('DataCloneError') || 
            log.includes('Uncaught') ||
            log.includes('could not be cloned')
        );

        await browser.close();

        if (panicOrCloneError) {
            console.error("\n❌ FAILED: Found critical errors or Rust panic in the browser console!");
            process.exitCode = 1;
        } else {
            console.log("\n✅ SUCCESS: App loaded, initialized, and ran without any Rust panics or Memory clone errors!");
            process.exitCode = 0;
        }

    } catch (err) {
        console.error("Test execution failed:", err);
        process.exitCode = 1;
    } finally {
        console.log("Stopping local server...");
        server.kill();
    }
}

run();
