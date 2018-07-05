import React, { Component } from 'react';
import logo from './logo.svg';
import './App.css';

class App extends Component {
  render() {
    return (
      <div className="App">
        <script rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/js/bootstrap.min.js" ></script>
        <link src="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/css/bootstrap.min.css"></link>
        <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/js/bootstrap.min.js"></script>
        <link rel="stylesheet" href="./css/main.css"></link>
        <h1 id="test">Hello world</h1>
        <form>
          <div className="form-group">
            <select className="selectpicker form-control">
              <option value={null}>Graph Type...</option>
              <option value="bar_graph">Bar Graph</option>
              <option value="line_graph">Line Graph</option>
            </select>
            <select className="form-group">
              <option value={null}>Metric</option>
              <option value="kills">Kills</option>
              <option value="serves">Serves</option>
              <option value="blocks">Blocks</option>
            </select>
          </div>
        </form>
      </div>
    );
  }
}

export default App;
