import { element } from '../lib/style.js';

const render = ({ side, config, spaces, displays, screen }) => {
  const style = {
    ...element,
    ...config.style,
    float: side
  }

  const spaceStyle = (space) => ({
    display: "inline-block",
    padding: "0 8px",
    ...(
      (space.focused) ? {
        borderBottom: "2px solid #c678dd"
      } : {}
    )
  })

  const currentDisplay = displays.find(
    (display) => display.id === screen
  ) || {
    index: -1
  }

  const currentSpaces = spaces.filter(
    (space) => space.display === currentDisplay.index
  )

  const spaceIcon = (index) => {
    return config.icons[index] || "far fa-window-maximize"
  }

  return (
    <span style={style}>
      {
        currentSpaces.map(
          (space) => (
            <span style={spaceStyle(space)}>
              <i className={spaceIcon(space.index)}></i>
            </span>
          )
        )
      }
    </span>
  )
}

export default render
