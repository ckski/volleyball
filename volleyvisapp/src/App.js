import React, { Component } from 'react';
import logo from './logo.svg';
import './App.css';
// import chartjs from 'react-chartjs';

// Import statements for all supported graph types
import {Bar, Line} from 'react-chartjs-2';

let chartData = {
  labels : ["TestOne", "TestTwo", "TestThree"],
  datasets: [{
    label: '# of kills',
    data: [12,19,3,5,6,3],
    backgroundColor: [
      'rgba(255, 40, 40, 0.8)',
      'rgba(40, 255, 40, 0.8)',
      'rgba(40, 40, 255, 0.8)'
    ],
    borderColor: [
      'rgba(0, 0, 0, 1)',
      'rgba(0, 0, 0, 1)',
      'rgba(0, 0, 0, 1)'
    ],
    borderWidth: 1
  }]
};
let chartOptions = {
  scales: {
    yAxes: [{
      ticks: {
        beginAtZero: true
      }
    }]
  }
};

class App extends Component {

  constructor(){
    super();

    this.getChosenChart = this.getChosenChart.bind(this);

    // Set default graph to empty div
    this.state = {
      graph_to_render: <div></div>
    }
  }

  // Conditionally render the chart segment based on selectpicker

  getChosenChart() {
    let chosenGraphPicker = document.getElementById('graph_picker');
    let chosenGraph = chosenGraphPicker.options[chosenGraphPicker.selectedIndex].value;
    console.log(chosenGraph);
    if(chosenGraph === "bar"){
      console.log('bar detected');
      let bar = <Bar options={chartOptions} data={chartData}></Bar>;
      this.setState({
        graph_to_render: bar
      });

      console.log(this.state.graph_to_render);
    }
    else if(chosenGraph === "line"){
      let line = <Line options={chartOptions} data={chartData}></Line>;
      this.setState({
        graph_to_render: line
      });
    }
    else{
      this.setState({
        graph_to_render: <div></div>
      });
    }
  }

  render() {
    return (
      <div className="App">
        <div className="container">


        <script rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/js/bootstrap.min.js" ></script>
        <link src="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/css/bootstrap.min.css"></link>
        <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/js/bootstrap.min.js"></script>
        <link rel="stylesheet" href="./css/main.css"></link>
        <h1 id="test">Hello world</h1>
        <form>
          <div className="form-group">
            <select onChange={this.getChosenChart} id="graph_picker" className="selectpicker form-control">
              <option value={null}>Graph Type...</option>
              <option value="bar">Bar Graph</option>
              <option value="line">Line Graph</option>
            </select>
            <select className="form-group">
              <option value={null}>Metric</option>
              <option value="kills">Kills</option>
              <option value="serves">Serves</option>
              <option value="blocks">Blocks</option>
            </select>
          </div>
        </form>
        <div>
          {this.state.graph_to_render}

        </div>

      </div>
      </div>
    );
  }
}

export default App;
