/**
 * Theme Manager - Dark/Light Mode Toggle
 * Manages theme across all Sakshi Vani components
 */

class ThemeManager {
    constructor() {
        // Get saved theme or default to light
        this.theme = localStorage.getItem('sakshivani-theme') || 'light';
        this.init();
    }

    init() {
        // Apply theme immediately to prevent flash
        this.apply();

        // Listen for theme toggle events
        document.addEventListener('DOMContentLoaded', () => {
            this.setupToggleButton();
        });
    }

    toggle() {
        // Toggle between light and dark
        this.theme = this.theme === 'light' ? 'dark' : 'light';

        // Save to localStorage
        localStorage.setItem('sakshivani-theme', this.theme);

        // Apply the new theme
        this.apply();

        // Animate the toggle button
        this.animateToggle();
    }

    apply() {
        // Apply theme to document
        document.documentElement.setAttribute('data-theme', this.theme);

        // Update meta theme-color for mobile browsers
        const metaThemeColor = document.querySelector('meta[name="theme-color"]');
        if (metaThemeColor) {
            metaThemeColor.setAttribute('content',
                this.theme === 'dark' ? '#0f172a' : '#FACC15'
            );
        }
    }

    setupToggleButton() {
        const toggleBtn = document.getElementById('theme-toggle');
        if (toggleBtn) {
            toggleBtn.addEventListener('click', () => this.toggle());
        }
    }

    animateToggle() {
        const toggleBtn = document.getElementById('theme-toggle');
        if (toggleBtn) {
            toggleBtn.style.transform = 'rotate(360deg)';
            setTimeout(() => {
                toggleBtn.style.transform = 'rotate(0deg)';
            }, 300);
        }
    }

    // Get current theme
    getCurrentTheme() {
        return this.theme;
    }

    // Check if dark mode
    isDark() {
        return this.theme === 'dark';
    }
}

// Initialize theme manager globally
// Initialize theme manager globally
const themeManager = new ThemeManager();

// Register Service Worker for Offline Support
if ('serviceWorker' in navigator) {
    // Register the root service worker
    // using /sw.js path relative to the domain root
    navigator.serviceWorker.register('/sw.js')
        .then((reg) => {
            console.log('Service Worker Registered with scope:', reg.scope);
        })
        .catch((error) => {
            console.log('Service Worker registration failed:', error);
        });
}
