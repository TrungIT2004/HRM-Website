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

  try {
    console.log('Navigating to login...');
    await page.goto('http://localhost:3000/login', { waitUntil: 'networkidle' });

    console.log('Logging in as sysadmin@company.com...');
    await page.fill('input[type="email"]', 'sysadmin@company.com');
    await page.fill('input[type="password"]', 'test@123');
    await page.click('button[type="submit"]');

    // Wait for redirect to dashboard or admin
    await page.waitForNavigation({ waitUntil: 'networkidle' }).catch(() => {});
    await page.waitForTimeout(2000);

    console.log('Navigating to Hồ sơ Cá nhân (Sidebar link)...');
    const profileLink = page.locator('a:has-text("Hồ sơ Cá nhân")');
    if (await profileLink.isVisible()) {
      await profileLink.click();
    } else {
      await page.goto('http://localhost:3000/employees/a1b2c3d4-e5f6-4a5b-8c9d-0e1f2a3b4c5d', { waitUntil: 'networkidle' });
    }

    await page.waitForTimeout(2500);

    // Save profile top header
    await page.screenshot({ path: path.join(ARTIFACT_DIR, '28_admin_profile_overview.png') });
    console.log('Saved 28_admin_profile_overview.png');

    // Now click Tab 5: Lịch Trình & Ca Làm Việc
    console.log('Clicking Tab 5: Lịch Trình & Ca Làm Việc...');
    const tab5 = page.locator('button:has-text("Lịch Trình & Ca Làm Việc")');
    await tab5.click();
    await page.waitForTimeout(1500);

    // Take screenshot of Tab 5
    await page.screenshot({ path: path.join(ARTIFACT_DIR, '29_student_timetable_tab5.png'), fullPage: false });
    console.log('Saved 29_student_timetable_tab5.png');

    // Take focused screenshot of the timetable section
    const timetableContainer = page.locator('text=Thời Khóa Biểu Làm Việc Chi Tiết Theo Ngày').locator('xpath=ancestor::div[contains(@class, "rounded-3xl border")][1]');
    if (await timetableContainer.isVisible()) {
      await timetableContainer.screenshot({ path: path.join(ARTIFACT_DIR, '30_timetable_matrix_focused.png') });
      console.log('Saved 30_timetable_matrix_focused.png');
    }

    console.log('All tests completed successfully!');
  } catch (err) {
    console.error('Error during test:', err);
    await page.screenshot({ path: path.join(ARTIFACT_DIR, 'test_error.png') });
  } finally {
    await browser.close();
  }
}

run();
