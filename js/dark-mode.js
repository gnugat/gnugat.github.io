/**
 * Dark Mode Toggle Functionality
 * Manages theme switching with localStorage persistence
 */

(function() {
    'use strict';

    // Theme configuration
    const THEME_KEY = 'theme';
    const DARK_THEME = 'dark';
    const LIGHT_THEME = 'light';

    // Icons for toggle button
    const DARK_ICON = '🌙';
    const LIGHT_ICON = '☀️';

    // Get current theme from localStorage or default to light
    function getCurrentTheme() {
        const savedTheme = localStorage.getItem(THEME_KEY);
        if (savedTheme) {
            return savedTheme;
        }
        
        // Check system preference
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            return DARK_THEME;
        }
        
        return LIGHT_THEME;
    }

    // Apply theme to document
    function applyTheme(theme) {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem(THEME_KEY, theme);
        
        // Update toggle button icon
        const toggleButton = document.querySelector('.dark-mode-toggle');
        if (toggleButton) {
            toggleButton.textContent = theme === DARK_THEME ? LIGHT_ICON : DARK_ICON;
            toggleButton.setAttribute('aria-label', 
                theme === DARK_THEME ? 'Switch to light mode' : 'Switch to dark mode'
            );
        }
    }

    // Toggle between themes
    function toggleTheme() {
        const currentTheme = getCurrentTheme();
        const newTheme = currentTheme === DARK_THEME ? LIGHT_THEME : DARK_THEME;
        applyTheme(newTheme);
    }

    // Create toggle button
    function createToggleButton() {
        const button = document.createElement('button');
        button.className = 'dark-mode-toggle';
        button.type = 'button';
        
        // Set initial text content based on current theme
        const currentTheme = getCurrentTheme();
        button.textContent = currentTheme === DARK_THEME ? LIGHT_ICON : DARK_ICON;
        button.setAttribute('aria-label', 
            currentTheme === DARK_THEME ? 'Switch to light mode' : 'Switch to dark mode'
        );
        
        button.addEventListener('click', toggleTheme);
        
        // Add keyboard support
        button.addEventListener('keydown', function(e) {
            if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                toggleTheme();
            }
        });
        
        return button;
    }

    // Initialize dark mode
    function initializeDarkMode() {
        // Apply initial theme
        const currentTheme = getCurrentTheme();
        applyTheme(currentTheme);
        
        // Create and insert toggle button
        const toggleButton = createToggleButton();
        document.body.appendChild(toggleButton);
        
        // Listen for system theme changes
        if (window.matchMedia) {
            const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
            mediaQuery.addEventListener('change', function(e) {
                // Only auto-switch if user hasn't manually set a preference
                if (!localStorage.getItem(THEME_KEY)) {
                    applyTheme(e.matches ? DARK_THEME : LIGHT_THEME);
                }
            });
        }
    }

    // Initialize when DOM is ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initializeDarkMode);
    } else {
        initializeDarkMode();
    }
})();