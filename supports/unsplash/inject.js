var script = document.createElement('script');
script.setAttribute('src', 'https://cdn.jsdelivr.net/npm/darkreader@4.9.34/darkreader.min.js');
script.setAttribute('type', 'text/javascript');
script.setAttribute('onLoad', 'DarkReader.enable();');
document.getElementsByTagName('head')[0].appendChild(script);
