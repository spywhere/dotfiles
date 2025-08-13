import os

config.load_autoconfig(True)

c.aliases = {
  'h': 'help -t',
  'localhost': 'spawn -u localhost',
  'q': 'close',
  'qa': 'quit',
  'w': 'session-save',
  'wq': 'quit --save',
  'wqa': 'quit --save'
}

c.auto_save.session = True
c.content.default_encoding = 'utf-8'
c.content.geolocation = False
c.downloads.location.prompt = False
c.downloads.position = 'bottom'
c.downloads.remove_finished = 10000
c.scrolling.bar = 'always'
c.statusbar.show = 'always'
c.statusbar.padding = {'bottom': 1, 'left': 0, 'right': 0, 'top': 1}

c.statusbar.widgets = ['keypress', 'search_match', 'url', 'scroll', 'history', 'progress', 'clock:%a#%V %d %B %y, %H:%M ']

c.tabs.favicons.scale = 1.2
c.tabs.mousewheel_switching = False
c.tabs.padding = {'bottom': 5, 'left': 5, 'right': 5, 'top': 5}
c.tabs.position = 'left'
c.tabs.show = 'always'
c.tabs.title.elide = 'middle'
c.tabs.title.format_pinned = '#{audio}{index}: {current_title}'
c.url.default_page = 'https://web.tabliss.io/'
c.url.start_pages = 'https://web.tabliss.io/'
c.url.searchengines = {'DEFAULT': 'https://kagi.com/search?q={}'}

c.colors.statusbar.normal.bg = '#333'
c.colors.tabs.bar.bg = '#222'
c.colors.tabs.odd.bg = '#222'
c.colors.tabs.even.bg = '#222'
c.colors.tabs.selected.odd.bg = '#444'
c.colors.tabs.selected.even.bg = '#444'
c.colors.tabs.pinned.odd.bg = '#242'
c.colors.tabs.pinned.even.bg = '#242'
c.colors.tabs.pinned.selected.odd.bg = '#363'
c.colors.tabs.pinned.selected.even.bg = '#363'

c.colors.webpage.preferred_color_scheme = 'dark'
config.set('colors.webpage.darkmode.enabled', True, 'qute://*')

c.fonts.default_family = 'JetBrainsMono Nerd Font'
c.fonts.default_size = '12pt'
c.fonts.statusbar = 'default_size default_family'
c.fonts.tabs.selected = '14pt system'
c.fonts.tabs.unselected = '14pt system'

config.bind('<Meta+Ctrl+f>', 'fullscreen')
config.bind('<Meta+Shift+t>', 'undo')
config.bind('<Meta+d>', 'tab-pin')
config.bind('<Meta+s>', 'config-cycle tabs.show always never')
config.bind('Q', 'macro-record')
config.bind('q', 'tab-prev')
config.bind('w', 'tab-next')

if os.path.isfile('/opt/homebrew/bin/iina'):
  config.bind('M', 'hint links spawn --detach /opt/homebrew/bin/iina {hint-url}')
  config.bind(';M', 'spawn --detach /opt/homebrew/bin/iina {url}')
