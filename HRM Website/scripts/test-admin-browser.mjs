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
    viewport: { width: 1440, height: 900 }
  });
  const page = await context.newPage();

  page.on('console', msg => console.log('BROWSER CONSOLE:', msg.type(), msg.text()));
  page.on('pageerror', err => console.error('BROWSER PAGE ERROR:', err.message));

  console.log('Navigating to http://localhost:3000/login ...');
  await page.goto('http://localhost:3000/login', { waitUntil: 'networkidle' });
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '01_login_page.png') });

  // Fill login credentials directly for Admin
  console.log('Filling login form with sysadmin@company.com ...');
  await page.fill('input[type="email"]', 'sysadmin@company.com');
  await page.fill('input[type="password"]', 'test@123');
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '02_login_filled.png') });

  // Submit login
  console.log('Submitting login form...');
  await page.click('button[type="submit"]');

  // Wait for Dashboard to fully load and auth check to complete
  console.log('Waiting for Dashboard to load...');
  await page.waitForURL('**/dashboard', { timeout: 15000 });
  await page.waitForSelector('text=Quản trị Hệ thống', { timeout: 15000 });
  console.log('Logged in successfully! Sidebar has "Quản trị Hệ thống" link.');
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '03_dashboard_after_login.png') });

  // Navigate to Admin by clicking the sidebar link
  console.log('Clicking "Quản trị Hệ thống" from sidebar...');
  await page.click('text=Quản trị Hệ thống');
  await page.waitForURL('**/admin', { timeout: 15000 });
  await page.waitForTimeout(1500);
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '04_admin_page_pending_tab.png') });

  // Click on "Tài Khoản & Bảo Mật" tab
  console.log('Clicking "Tài Khoản & Bảo Mật" tab...');
  await page.click('text=Tài Khoản & Bảo Mật');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '05_admin_accounts_tab.png') });

  // Click on "Cơ Cấu Tổ Chức & Master Data" tab
  console.log('Clicking "Cơ Cấu Tổ Chức & Master Data" tab...');
  await page.click('text=Cơ Cấu Tổ Chức & Master Data');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '06_admin_organization_tab.png') });

  // Click sub-tab "Chức Danh"
  console.log('Clicking sub-tab "Chức Danh"...');
  await page.click('button:has-text("Chức Danh")');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '07_admin_jobs_subtab.png') });

  // Click sub-tab "Ca Làm Việc"
  console.log('Clicking sub-tab "Ca Làm Việc"...');
  await page.click('button:has-text("Ca Làm Việc")');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '08_admin_shifts_subtab.png') });

  // Click on "Vận Hành & Giám Sát Dịch Vụ" tab
  console.log('Clicking "Vận Hành & Giám Sát Dịch Vụ" tab...');
  await page.click('text=Vận Hành & Giám Sát Dịch Vụ');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '09_admin_system_operations_tab.png') });

  // Navigate to /payroll
  console.log('Navigating to /payroll ...');
  await page.goto('http://localhost:3000/payroll', { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '10_payroll_page.png') });

  // Test selecting Month 7 (PAID status)
  console.log('Selecting Month 7 on payroll page...');
  const monthSelect = await page.$('select');
  if (monthSelect) {
    await monthSelect.selectOption('7');
    await page.waitForTimeout(1000);
    await page.screenshot({ path: path.join(ARTIFACT_DIR, '10b_payroll_month7_paid.png') });
  }

  // Navigate to /attendance
  console.log('Navigating to /attendance ...');
  await page.goto('http://localhost:3000/attendance', { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '11_attendance_page.png') });

  // Click on "Tổng hợp công" tab
  console.log('Clicking "Tổng hợp công" tab in attendance...');
  const summaryBtn = await page.$('button:has-text("Tổng hợp công")');
  if (summaryBtn) {
    await summaryBtn.click();
    await page.waitForTimeout(1500);
    await page.screenshot({ path: path.join(ARTIFACT_DIR, '11b_attendance_monthly_summary.png') });
  }

  console.log('All tests completed successfully!');
  await browser.close();
}

run().catch(err => {
  console.error('Test error:', err);
  process.exit(1);
});
