export const refreshFrequency = 1000

import { theme } from './lib/style.js'
import {
  Spaces,
  Time,
  Title
} from './src/index.jsx'

const config = {
  time: {
    format: "%a#%V %d %B %y, %H:%M",
    style: {
      padding: '0 15px',
      backgroundColor: theme.backgroundLight,
    }
  },
  title: {
    style: {}
  },
  spaces: {
    icons: {
      1: "fab fa-slack-hash",
      2: "far fa-envelope",
      3: "fa fa-terminal",
      4: "fab fa-chrome",
      5: "fas fa-database",
      6: "far fa-folder"
    },
    style: {}
  }
}

const barStyle = {
  top: 0,
  right: 0,
  left: 0,
  position: 'fixed',
  background: theme.background,
  overflow: 'hidden',
  color: theme.text,
  height: '24px',
  fontFamily: '"JetBrainsMono Nerd Font Mono"',
  fontSize: '12px'
}


const result = (data, key) => {
  try {
    return JSON.parse(data)[key]
  } catch (e) {
    console.log(data, e);
    return ''
  }
}

const test = (command, onTrue, onFalse) => {
  const commandPath = `/usr/local/bin/${ command }`
  return `if command -v ${
    commandPath
  } >/dev/null; then ${
    onTrue(commandPath)
  }; else ${
    onFalse(commandPath)
  }; fi`
}
export const command = `
DISPLAYS=$(${
  test(
    "yabai",
    (cmd) => `echo $(${ cmd } -m query --displays | /usr/local/bin/jq '[.[] | { id, index  }]')`,
    () => `echo "[]"`
  )
})
WINDOWS=$(${
  test(
    "yabai",
    (cmd) => `echo $(${ cmd } -m query --windows | /usr/local/bin/jq '[.[] | select(.visible == 1) | { app, title, display }]')`,
    () => `echo ""`
  )
})
SPACES=$(${
  test(
    "yabai",
    (cmd) => `echo $(${ cmd } -m query --spaces | /usr/local/bin/jq '[.[] | { display, focused, index }] | sort_by(.index)')`,
    () => `echo "[]"`
  )
})

echo $(cat <<-EOF
  {
    "displays": $DISPLAYS,
    "spaces": $SPACES,
    "windows": $WINDOWS
  }
EOF
);
`

export const render = ({ output, error }) => {
  if(error) {
    console.log(new Date())
    console.log(error)
    console.log(String(error))
  }
  let screenID = Number(window.location.pathname.replace(/\//g, ""))
  let errorContent = (
    <div style={barStyle}></div>
  )
  const displays = result(output, "displays")
  let content = (
    <div style={barStyle}>
      <link rel="stylesheet" type="text/css" href="bar/assets/font-awesome/css/all.min.css" />
      <Spaces config={config.spaces} spaces={result(output, "spaces")} displays={displays} screen={screenID} side="left" />
      
      <Title config={config.title} windows={result(output, "windows")} displays={displays} screen={screenID} />

      <Time config={config.time} side="right"></Time>
    </div>
  )
  return error ? errorContent : content
}
