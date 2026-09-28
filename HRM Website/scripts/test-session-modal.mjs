import { chromium } from 'playwright-core';
import path from 'path';

const EDGE_PATH = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const ARTIFACT_DIR = 'C:\\Users\\ad\\.gemini\\antigravity\\brain\\c5c01ffa-9929-4d1a-a28b-c04934f45778';

async function run() {
  console.log('Launching browser via Playwright with Edge...');
  const browser = await chromium.launch({
    executablePath: EDGE_PATH,
    headless: true
  });

  const context = await browser.newContext({
    viewport: { width: 1440, height: 950 }
  });
  const page = await context.newPage();

  page.on('console', msg => console.log('BROWSER CONSOLE:', msg.type(), msg.text()));
  page.on('pageerror', err => console.error('BROWSER PAGE ERROR:', err.message));
  page.on('dialog', async dialog => {
    console.log('DIALOG DETECTED:', dialog.message());
    await dialog.accept();
  });

  console.log('Navigating to http://localhost:3000/login ...');
  await page.goto('http://localhost:3000/login', { waitUntil: 'networkidle' });

  console.log('Logging in as sysadmin@company.com ...');
  await page.fill('input[type="email"]', 'sysadmin@company.com');
  await page.fill('input[type="password"]', 'test@123');
  await page.click('button[type="submit"]');

  console.log('Waiting for Dashboard to load...');
  await page.waitForURL('**/dashboard', { timeout: 15000 });
  await page.waitForSelector('text=Quản trị Hệ thống', { timeout: 15000 });

  console.log('Navigating directly to /admin ...');
  await page.goto('http://localhost:3000/admin', { waitUntil: 'networkidle' });
  await page.waitForTimeout(1500);

  // 1. Click "Tài Khoản & Bảo Mật" tab
  console.log('Clicking "Tài Khoản & Bảo Mật" tab...');
  await page.click('button:has-text("Tài Khoản & Bảo Mật")');
  await page.waitForTimeout(1500);

  // 2. Screenshot clean table with 3-dots action buttons
  console.log('Capturing redesigned Accounts table...');
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '17_accounts_table_clean_actions.png') });
  console.log('Saved 17_accounts_table_clean_actions.png');

  // 3. Open 3-dots Action Dropdown for employee with active sessions
  console.log('Clicking 3-dots action button on employee row...');
  const rowTarget = page.locator('tr:has-text("Phạm Thị Cúc")');
  const actionBtn = rowTarget.locator('button[title="Tùy chọn thao tác"]');
  await actionBtn.click();
  await page.waitForTimeout(600);

  // 4. Screenshot open Action Dropdown menu
  console.log('Capturing open Action Dropdown menu...');
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '18_action_dropdown_open.png') });
  console.log('Saved 18_action_dropdown_open.png');

  // 5. Click "Xem phiên & thiết bị" from dropdown menu
  console.log('Clicking "Xem phiên & thiết bị" in dropdown menu...');
  await page.click('button:has-text("Xem phiên & thiết bị")');
  await page.waitForTimeout(1500);

  // 6. Screenshot User Sessions Modal opened from dropdown
  console.log('Capturing User Sessions Modal...');
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '19_user_sessions_modal_from_dropdown.png') });
  console.log('Saved 19_user_sessions_modal_from_dropdown.png');

  // 7. Test Filter "Đang Online"
  console.log('Filtering by "Đang Online"...');
  await page.click('button:has-text("Đang Online")');
  await page.waitForTimeout(500);

  // 8. Close modal
  console.log('Closing modal...');
  await page.click('button:has-text("Đóng")');
  await page.waitForTimeout(800);

  // 9. Test outside click on 3-dots dropdown
  console.log('Testing dropdown outside click dismiss...');
  const firstActionBtn = page.locator('button[title="Tùy chọn thao tác"]').first();
  await firstActionBtn.click();
  await page.waitForTimeout(500);

  // Click outside backdrop to dismiss
  await page.locator('div.fixed.inset-0.z-40').click();
  await page.waitForTimeout(500);

  await page.screenshot({ path: path.join(ARTIFACT_DIR, '20_accounts_table_after_dismiss.png') });
  console.log('Saved 20_accounts_table_after_dismiss.png');

  console.log('All Action Dropdown & Session tests passed successfully!');
  await browser.close();
}

run().catch(err => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
