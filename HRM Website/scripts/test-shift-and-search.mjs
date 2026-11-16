import { chromium } from 'playwright-core';
import path from 'path';

const EDGE_PATH = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
const ARTIFACT_DIR = 'C:\\Users\\ad\\.gemini\\antigravity\\brain\\c5c01ffa-9929-4d1a-a28b-c04934f45778';

async function run() {
  console.log('Launching browser with Edge...');
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

  console.log('Logging in as sysadmin@company.com ...');
  await page.goto('http://localhost:3000/login', { waitUntil: 'networkidle' });
  await page.fill('input[type="email"]', 'sysadmin@company.com');
  await page.fill('input[type="password"]', 'test@123');
  await page.click('button[type="submit"]');

  await page.waitForURL('**/dashboard', { timeout: 15000 });
  await page.goto('http://localhost:3000/admin', { waitUntil: 'networkidle' });
  await page.waitForTimeout(1500);

  // 1. Go to "Cơ Cấu Tổ Chức & Master Data" tab
  console.log('Navigating to Organization tab...');
  await page.click('button:has-text("Cơ Cấu Tổ Chức & Master Data")');
  await page.waitForTimeout(1500);

  // 2. Test Departments Search
  console.log('Testing Departments search...');
  const deptSearch = page.locator('input[placeholder="Tìm theo tên phòng ban, mã..."]');
  await deptSearch.fill('Human');
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '21_admin_departments_search.png') });
  console.log('Saved 21_admin_departments_search.png');
  await deptSearch.fill('');
  await page.waitForTimeout(400);

  // 3. Test Jobs Sub-tab & Search
  console.log('Navigating to Jobs sub-tab...');
  await page.click('button:has-text("Chức Danh")');
  await page.waitForTimeout(1000);

  const jobSearch = page.locator('input[placeholder="Tìm theo tên chức danh, phòng ban..."]');
  await jobSearch.fill('Head');
  await page.waitForTimeout(600);
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '22_admin_jobs_search_filter.png') });
  console.log('Saved 22_admin_jobs_search_filter.png');
  await jobSearch.fill('');
  await page.waitForTimeout(400);

  // 4. Test Shifts Sub-tab
  console.log('Navigating to Shifts sub-tab...');
  await page.click('button:has-text("Ca Làm Việc")');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '23_admin_shifts_list.png') });
  console.log('Saved 23_admin_shifts_list.png');

  // 5. Open "Tạo Ca Làm Việc Mới" modal
  console.log('Opening Create Shift Modal...');
  await page.click('button:has-text("Tạo Ca Làm Việc Mới")');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '24_admin_create_shift_modal_open.png') });
  console.log('Saved 24_admin_create_shift_modal_open.png');

  // 6. Fill Shift Name & Apply Preset T2-T7
  console.log('Configuring custom 7-day schedule...');
  const shiftNameInput = page.locator('input[placeholder*="Ca Hành Chính Chuẩn"]');
  await shiftNameInput.fill('Ca Kỹ Thuật & Vận Hành (T2-T7)');

  // Click preset T2-T7
  await page.click('button:has-text("Thứ 2 - Thứ 7 (Nghỉ CN)")');
  await page.waitForTimeout(500);

  // Screenshot configured modal
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '25_admin_create_shift_modal_configured.png') });
  console.log('Saved 25_admin_create_shift_modal_configured.png');

  // 7. Submit Shift
  console.log('Submitting create shift...');
  await page.locator('.fixed.inset-0.z-50 button:has-text("Tạo Ca Làm Việc")').last().click();
  await page.waitForTimeout(2500);

  // 8. Screenshot shifts list after creation
  await page.screenshot({ path: path.join(ARTIFACT_DIR, '26_admin_shifts_after_create.png') });
  console.log('Saved 26_admin_shifts_after_create.png');

  console.log('All tests finished successfully!');
  await browser.close();
}

run().catch(err => {
  console.error('Test execution failed:', err);
  process.exit(1);
});
