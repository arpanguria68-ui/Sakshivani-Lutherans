const { test, expect } = require('@playwright/test');

const pagesToTest = [
  { name: 'PWA Home', path: '/pwa/' },
  { name: 'Catechism Home', path: '/pwa/catechism' },
  { name: 'Catechism Detail', path: '/pwa/catechism/1-commandments' },
];

test.describe('Day/Night Mode Verification', () => {
  for (const pageInfo of pagesToTest) {
    test(`should toggle day/night mode on ${pageInfo.name}`, async ({ page }) => {
      // Listen for console logs
      page.on('console', msg => console.log(`BROWSER LOG: ${msg.text()}`));

      await page.goto(`http://localhost:3000${pageInfo.path}`);

      // 1. Verify initial (light) mode and take screenshot
      await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
      await page.screenshot({ path: `verification/${pageInfo.name.replace(/ /g, '_')}_light_mode.png` });

      // 2. Click the toggle to switch to dark mode
      await page.click('#theme-toggle');

      // 3. Verify dark mode is applied and take screenshot
      await expect(page.locator('html')).toHaveAttribute('data-theme', 'dark');
      await page.screenshot({ path: `verification/${pageInfo.name.replace(/ /g, '_')}_dark_mode.png` });

      // 4. Click the toggle again to switch back to light mode
      await page.click('#theme-toggle');

      // 5. Verify light mode is restored
      await expect(page.locator('html')).toHaveAttribute('data-theme', 'light');
    });
  }
});
