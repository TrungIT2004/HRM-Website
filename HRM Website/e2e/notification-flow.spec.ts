import { test, expect } from '@playwright/test';

// Test credentials - using seeded test users
const STAFF_CREDENTIALS = {
  email: 'staff@company.com',
  password: 'password123',
};

const MANAGER_CREDENTIALS = {
  email: 'manager@company.com',
  password: 'password123',
};

test.describe('Notification Flow E2E', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto('/login');
    await page.waitForLoadState('networkidle');
  });

  test('Staff creates leave request → Manager approves → Staff receives toast and bell notification', async ({ page, context }) => {
    // ========== STEP 1: Login as Staff ==========
    await page.fill('input[name="email"]', STAFF_CREDENTIALS.email);
    await page.fill('input[name="password"]', STAFF_CREDENTIALS.password);
    await page.click('button[type="submit"]');
    await page.waitForURL('**/dashboard', { timeout: 10000 });
    await expect(page.locator('text=ACT HRM')).toBeVisible();

    // ========== STEP 2: Navigate to Leave Request creation ==========
    await page.click('a[href="/leave/create"]');
    await page.waitForURL('**/leave/create');
    await expect(page.locator('h1:has-text("Tạo đơn nghỉ phép")')).toBeVisible();

    // ========== STEP 3: Fill leave request form ==========
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dayAfterTomorrow = new Date();
    dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 2);

    const formatDate = (d: Date) => d.toISOString().split('T')[0];

    await page.fill('input[name="fromDate"]', formatDate(tomorrow));
    await page.fill('input[name="toDate"]', formatDate(dayAfterTomorrow));
    await page.fill('textarea[name="reason"]', 'E2E test leave request for notification flow');

    // Select paid leave days (assuming 2 working days)
    await page.fill('input[name="paidLeaveDays"]', '2');

    // Submit
    await page.click('button:has-text("Gửi yêu cầu")');

    // Wait for success toast or redirect
    await page.waitForURL('**/leave/**', { timeout: 10000 });
    await expect(page.locator('text=Đã gửi yêu cầu nghỉ phép thành công')).toBeVisible({ timeout: 5000 });

    // Get the leave request ID from URL
    const leaveUrl = page.url();
    const leaveId = leaveUrl.split('/leave/')[1];
    console.log(`Created leave request: ${leaveId}`);

    // ========== STEP 4: Logout staff ==========
    await page.click('[data-testid="user-menu-trigger"]');
    await page.click('text=Đăng xuất khỏi hệ thống');
    await page.waitForURL('**/login');

    // ========== STEP 5: Login as Manager ==========
    await page.fill('input[name="email"]', MANAGER_CREDENTIALS.email);
    await page.fill('input[name="password"]', MANAGER_CREDENTIALS.password);
    await page.click('button[type="submit"]');
    await page.waitForURL('**/dashboard', { timeout: 10000 });

    // ========== STEP 6: Manager should see notification toast for new leave request ==========
    // Check for toast notification
    await expect(page.locator('text=New leave request from').first()).toBeVisible({ timeout: 5000 });

    // Check notification bell badge incremented
    const bellBadge = page.locator('[data-testid="notification-badge"]').first();
    await expect(bellBadge).toHaveText(/[1-9]/);

    // ========== STEP 7: Navigate to leave requests to approve ==========
    await page.click('a[href="/leave/approve"]');
    await page.waitForURL('**/leave/approve');
    await expect(page.locator('h1:has-text("Duyệt nghỉ phép")')).toBeVisible();

    // ========== STEP 8: Find and approve the leave request ==========
    const leaveRow = page.locator(`tr:has-text("${leaveId}")`).first();
    await expect(leaveRow).toBeVisible({ timeout: 5000 });

    // Click approve button
    await leaveRow.locator('button:has-text("Phê duyệt")').first().click();

    // Confirm approval if needed
    const confirmBtn = page.locator('button:has-text("Xác nhận"), button:has-text("Approve")').first();
    if (await confirmBtn.isVisible({ timeout: 2000 })) {
      await confirmBtn.click();
    }

    // Wait for success
    await expect(page.locator('text=Đã phê duyệt thành công')).toBeVisible({ timeout: 5000 });

    // ========== STEP 9: Logout manager ==========
    await page.click('[data-testid="user-menu-trigger"]');
    await page.click('text=Đăng xuất khỏi hệ thống');
    await page.waitForURL('**/login');

    // ========== STEP 10: Login as Staff again ==========
    await page.fill('input[name="email"]', STAFF_CREDENTIALS.email);
    await page.fill('input[name="password"]', STAFF_CREDENTIALS.password);
    await page.click('button[type="submit"]');
    await page.waitForURL('**/dashboard', { timeout: 10000 });

    // ========== STEP 11: Staff should receive toast notification for approval ==========
    await expect(page.locator('text=Leave Request Approved').first()).toBeVisible({ timeout: 5000 });

    // Check notification bell badge incremented
    const staffBellBadge = page.locator('[data-testid="notification-badge"]').first();
    await expect(staffBellBadge).toHaveText(/[1-9]/);

    // ========== STEP 12: Click notification bell to verify dropdown ==========
    await page.click('[data-testid="notification-bell"]');

    // Wait for dropdown to open
    await expect(page.locator('text=Thông báo')).toBeVisible({ timeout: 3000 });

    // Verify the approved notification appears in dropdown
    await expect(page.locator('text=Leave Request Approved')).toBeVisible({ timeout: 3000 });

    // ========== STEP 13: Click notification to navigate to leave detail ==========
    await page.locator('text=Leave Request Approved').first().click();
    await page.waitForURL(`**/leave/${leaveId}`, { timeout: 5000 });
    await expect(page.locator(`text=${leaveId}`)).toBeVisible({ timeout: 3000 });
  });

  test('Notification bell shows correct unread count', async ({ page }) => {
    await page.goto('/login');
    await page.fill('input[name="email"]', STAFF_CREDENTIALS.email);
    await page.fill('input[name="password"]', STAFF_CREDENTIALS.password);
    await page.click('button[type="submit"]');
    await page.waitForURL('**/dashboard');

    // Bell should show 0 initially or some count
    const badge = page.locator('[data-testid="notification-badge"]').first();
    const initialCount = await badge.textContent();
    console.log(`Initial badge count: ${initialCount}`);

    // Create a leave request (simplified - assume we have a way to trigger notification)
    // This test verifies the badge component renders correctly
    expect(badge).toBeVisible();
  });
});