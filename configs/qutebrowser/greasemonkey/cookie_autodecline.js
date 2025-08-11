// ==UserScript==
// @name         Cookie Auto Decline
// @namespace    http://tampermonkey.net/
// @version      1.0
// @description  Automatically decline cookie consent banners
// @author       Omid Mashregh-Zamini
// @website      https://omidmash.de
// @match        *://*/*
// @exclude      *://*.youtube.com/*
// @exclude      *://*.tilvids.com/*
// @exclude      *://tilvids.com/*
// @grant        none
// ==/UserScript==

(function() {
    'use strict';

    function declineCookies() {
        // Always show that script is running
        const runningNotif = document.createElement('div');
        runningNotif.textContent = 'Cookie script running...';
        runningNotif.style.cssText = 'position:fixed;top:10px;right:10px;background:orange;color:white;padding:5px;z-index:99999;font-size:12px;';
        document.body.appendChild(runningNotif);
        setTimeout(() => runningNotif.remove(), 1000);
        // Common decline/reject button selectors (attribute-based)
        const declineSelectors = [
            // Generic decline/reject buttons by attributes
            '[data-testid*="reject"], [data-testid*="decline"], [data-testid*="deny"]',
            '[id*="reject"], [id*="decline"], [id*="deny"]',
            '[class*="reject"], [class*="decline"], [class*="deny"]',
            'button[aria-label*="reject" i], button[aria-label*="decline" i], button[aria-label*="deny" i]',

            // Common cookie banner frameworks
            '[data-cc-action="deny"]', // CookieConsent
            '[data-role="rejectAll"], [data-role="reject-all"]', // Various frameworks
            '.cc-deny, .cc-dismiss', // CookieConsent classic
            '#onetrust-reject-all-handler', // OneTrust
            '[data-gdpr-action="reject"]',
            '.optanon-alert-box-wrapper .ot-sdk-btn-secondary', // OneTrust secondary button (usually reject)

            // Dotdash Meredith (Lifewire) specific
            '[data-tracking-container="true"] button[class*="primary-button"]',
            '.privacy-manager button[data-value="false"]',
            '.mntl-privacy-banner button[data-value="false"]',
            '[class*="privacy"] button[class*="decline"]',
            '[class*="privacy"] button[class*="reject"]'

            // Specific common implementations
            'button[class*="reject"]',
            'button[class*="decline"]',
            'button[class*="deny"]',
            'button[id*="reject"]',
            'button[id*="decline"]',
            'button[id*="cookieReject"]',
            'button[data-action="reject"]',

            // Close buttons for simple banners
            '.cookie-banner [aria-label="close"], .cookie-banner .close',
            '.cookie-notice [aria-label="close"], .cookie-notice .close',
            '.gdpr-banner .close',
            '.consent-banner .close'
        ];

        // Text-based keywords to look for
        const rejectKeywords = [
            'reject all', 'reject', 'decline all', 'decline', 'deny all', 'deny',
            'refuse all', 'refuse', 'dismiss', 'no thanks', 'no', 'necessary only',
            'essential only', 'required only', 'basic', 'minimal', 'do not sell',
            'manage preferences', 'cookie settings', 'privacy settings',
            // Multi-language
            'ablehnen', 'verweigern', // German
            'rechazar', 'denegar', // Spanish
            'rifiuta', 'nega', // Italian
            'refuser', // French
            'afwijzen', 'weigeren', // Dutch
            'odrzuć', 'odmów', // Polish
            'rejeitar', 'negar', // Portuguese
            'avvisa', 'отклонить' // Russian
        ];

        let foundButton = false;

        // First try attribute-based selectors
        for (const selector of declineSelectors) {
            const elements = document.querySelectorAll(selector);

            for (const element of elements) {
                if (element && element.offsetParent !== null && !element.disabled) {
                    console.log('Cookie Auto Decline: Found attribute-based button', element);
                    element.click();
                    foundButton = true;
                    break;
                }
            }
            if (foundButton) break;
        }

        // If no attribute-based button found, search by text content
        if (!foundButton) {
            const allButtons = document.querySelectorAll('button, a[role="button"], input[type="button"], input[type="submit"], span[role="button"], div[role="button"]');

            for (const button of allButtons) {
                if (!button.offsetParent || button.disabled) continue;

                const text = button.textContent.toLowerCase().trim();
                const ariaLabel = (button.getAttribute('aria-label') || '').toLowerCase();
                const title = (button.getAttribute('title') || '').toLowerCase();
                const allText = (text + ' ' + ariaLabel + ' ' + title).toLowerCase();

                // Debug: visual notification for troubleshooting
                if (text.length > 0 && (text.includes('reject') || text.includes('decline') || text.includes('necessary') || text.includes('deny'))) {
                    // Create visual debug element
                    const debug = document.createElement('div');
                    debug.textContent = `Found button: ${text}`;
                    debug.style.cssText = 'position:fixed;top:10px;right:10px;background:red;color:white;padding:5px;z-index:99999;font-size:12px;';
                    document.body.appendChild(debug);
                    setTimeout(() => debug.remove(), 3000);
                }

                // Check if button text matches reject keywords
                const isRejectButton = rejectKeywords.some(keyword => {
                    return allText.includes(keyword) ||
                           text === keyword ||
                           ariaLabel.includes(keyword) ||
                           title.includes(keyword);
                });

                if (isRejectButton) {
                    // Additional validation - avoid accept/allow buttons
                    const isAcceptButton = allText.includes('accept') ||
                                         allText.includes('allow') ||
                                         allText.includes('agree') ||
                                         allText.includes('ok') ||
                                         allText.includes('continue') ||
                                         allText.includes('proceed');

                    if (!isAcceptButton) {
                        // Create visual notification
                        const notification = document.createElement('div');
                        notification.textContent = `Clicked: ${text}`;
                        notification.style.cssText = 'position:fixed;top:10px;left:10px;background:green;color:white;padding:10px;z-index:99999;font-size:14px;border-radius:5px;';
                        document.body.appendChild(notification);
                        setTimeout(() => notification.remove(), 2000);

                        try {
                            button.click();
                            foundButton = true;
                            break;
                        } catch (e) {
                            notification.style.background = 'red';
                            notification.textContent = `Click failed: ${text}`;
                        }
                    }
                }
            }
        }

        // If still no button found, try to close/hide cookie banners
        if (!foundButton) {
            const bannerSelectors = [
                '.cookie-banner, .cookie-notice, .gdpr-banner, .consent-banner',
                '[class*="cookie"][class*="banner"]',
                '[id*="cookie"][id*="banner"]',
                '[class*="gdpr"]',
                '[class*="consent"]',
                '.cc-window, .cc-banner', // CookieConsent
                '#onetrust-banner-sdk' // OneTrust
            ];

            bannerSelectors.forEach(selector => {
                const banners = document.querySelectorAll(selector);
                banners.forEach(banner => {
                    if (banner.offsetParent) {
                        banner.style.display = 'none';
                        // Visual notification for hidden banner
                        const bannerNotif = document.createElement('div');
                        bannerNotif.textContent = 'Hidden cookie banner';
                        bannerNotif.style.cssText = 'position:fixed;top:50px;left:10px;background:blue;color:white;padding:5px;z-index:99999;font-size:12px;border-radius:3px;';
                        document.body.appendChild(bannerNotif);
                        setTimeout(() => bannerNotif.remove(), 2000);
                    }
                });
            });
        }
    }

    // Run after a short delay to let page load
    setTimeout(declineCookies, 1000);
    setTimeout(declineCookies, 3000); // Try again after 3s
    setTimeout(declineCookies, 5000); // And after 5s

    // Run when DOM changes (for dynamically loaded banners)
    const observer = new MutationObserver(() => {
        setTimeout(declineCookies, 500);
    });

    observer.observe(document.body, {
        childList: true,
        subtree: true
    });

    // Run periodically to catch any missed banners
    setInterval(declineCookies, 5000);

})();
