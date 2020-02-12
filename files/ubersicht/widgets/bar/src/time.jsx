import strftime from '../lib/strftime.js';
import { element } from '../lib/style.js';

const render = ({ config, error, side }) => {
  let time = strftime(config.format, new Date());
  var style = {
    ...element,
    ...config.style,
    padding: '4px 8px 0px 8px',
    float: side
  }

  return error ? (
    <span style={style}>!</span>
  ) : (
    <span style={style}>
      <i className="far fa-clock" style={{padding: '0 8px 0 0'}}></i>
      {time}
    </span>
  )
}

export default render
