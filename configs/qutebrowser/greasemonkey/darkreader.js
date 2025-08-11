// ==UserScript==
// @name          Dark Reader (Unofficial)
// @icon          https://darkreader.org/images/darkreader-icon-256x256.png
// @namespace     DarkReader
// @description	  Inverts the brightness of pages to reduce eye strain
// @version       4.7.15
// @author        https://github.com/darkreader/darkreader#contributors
// @homepageURL   https://darkreader.org/ | https://github.com/darkreader/darkreader
// @run-at        document-end
// @grant         none
// @include       http*
// @require       https://cdn.jsdelivr.net/npm/darkreader/darkreader.min.js
// @noframes
// ==/UserScript==

document.addEventListener('keyup', function (e) {
  if ('aAÅ'.indexOf(e.key) >= 0 && e.altKey && e.shiftKey) {
    e.preventDefault();
    if (DarkReader.isEnabled()) {
      DarkReader.disable();
      console.log('Dark Reader disabled');
    } else {
      DarkReader.enable({
        brightness: 100,
        contrast: 100,
        sepia: 0
      });
      console.log('Dark Reader enabled');
    }
  }
});
