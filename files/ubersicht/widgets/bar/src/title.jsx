import { element } from '../lib/style.js';

const render = ({ config, error, windows, displays, screen }) => {
  const style = {
    ...element,
    ...config.style,
    width: '100%',
    textAlign: 'center',
    position: 'fixed',
    top: '0',
    left: '0'
  }

  const currentDisplay = displays.find(
    (display) => display.id === screen
  ) || {
    index: -1
  }

  const currentWindow = windows.find(
    (window) => window.display === currentDisplay.index
  )

  const titleText = currentWindow ? `[${
    currentWindow.app
  }] ${
    currentWindow.title
  }` : ``

  return error ? (
    <span style={style}>!</span>
  ) : (
    <span style={style}>
      {titleText}
    </span>
  )
}

export default render
