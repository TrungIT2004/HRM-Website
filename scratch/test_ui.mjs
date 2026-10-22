import { chromium } from 'playwright';

async function testScreenshots() {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 } });
  const page = await context.newPage();

  console.log('Navigating to login...');
  await page.goto('http://localhost:3000/login');
  await page.waitForLoadState('networkidle');
  await page.screenshot({ path: 'scratch/screenshot_login.png' });
  console.log('Screenshot login saved.');

  // Login as superadmin
  console.log('Logging in as superadmin...');
  await page.fill('input[type="email"]', 'superadmin@company.com');
  await page.fill('input[type="password"]', 'test@123');
  await page.click('button[type="submit"]');

  await page.waitForURL('**/home', { timeout: 10000 });
  await page.waitForLoadState('networkidle');
  await page.screenshot({ path: 'scratch/screenshot_home.png' });
  console.log('Screenshot home saved.');

  // Navigate to attendance
  console.log('Navigating to attendance...');
  await page.goto('http://localhost:3000/attendance');
  await page.waitForLoadState('networkidle');
  await page.screenshot({ path: 'scratch/screenshot_attendance.png' });
  console.log('Screenshot attendance saved.');

  // Navigate to organization
  console.log('Navigating to organization...');
  await page.goto('http://localhost:3000/organization');
  await page.waitForLoadState('networkidle');
  await page.screenshot({ path: 'scratch/screenshot_organization.png' });
  console.log('Screenshot organization saved.');

  await browser.close();
  console.log('Done!');
}

testScreenshots().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
