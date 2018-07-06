import React, { Component } from 'react';
import logo from './logo.svg';
import './App.css';
// import chartjs from 'react-chartjs';

// Import statements for all supported graph types
import {Bar, Line} from 'react-chartjs-2';

// Set up the chart Data and Configuration
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

// This is just a placeholder, will be generated with get requests in the future
let dataSourceObjExample = {
  Season: [
    ["2017-2018", "2017-2018"],
    ["2016-2017", "2016-2017"],
    ["2015-2016", "2015-2016"]
  ],
  Team: [
    ["tru", "Thompson Rivers University"],
    ["ubc", "Universit of British Columbia"],
    ["uofa", "University of Alberta"]
  ],
  Matchup: [
    ["tru", "Thompson Rivers University"],
    ["ubc", "Universit of British Columbia"],
    ["uofa", "University of Alberta"]
  ],
  Match: [
    ["2017-02-05", "2017-02-05"],
    ["2017-02-06", "2017-02-06"]
  ]
};



class App extends Component {

  constructor(){
    super();

    this.getChosenChart = this.getChosenChart.bind(this);
    this.renderSelects = this.renderSelects.bind(this);

    this.renderSelects(dataSourceObjExample);



    // Set default graph to empty div
    this.state = {
      graph_to_render: <div></div>
    }
  }

  // Render select elements from object

  renderSelects(optObject){
    let selects = [];
    for(let key in optObject){
      let keyLength = optObject[key].length;
      let opts = [];
      opts.push(<option key="dummy" value={null}>Select...</option>)
      for(let i = 0; i < keyLength; i++){
        console.log(optObject[key][i]);
        opts.push(<option key={optObject[key][i][0]} value={optObject[key][i][0]}>{optObject[key][i][1]}</option>);
      }

      selects.push(<div key={key} className="col-xs-6"><label>{key}</label><select className='selectpicker form-control'>{opts}</select></div>);
    }
    return selects;
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
        <script rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/js/bootstrap.min.js" ></script>
        <link src="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/css/bootstrap.min.css"></link>
        <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/js/bootstrap.min.js"></script>
        <link rel="stylesheet" href="./css/main.css"></link>
        <div className="container">
          <div className="jumbotron">
            <h2 id="test">Volleyball Visualization<br></br><small>Welcome to our volleyball visualization application. Select some options to get started</small></h2>
          </div>
          <form>
            <div className="panel panel-default">
              <div className="panel-header">
                <h3 className="card-title">Data Source</h3>
              </div>
              <div className="panel-body">
                {this.renderSelects(dataSourceObjExample)}
              </div>
            </div>
            <div className="panel panel-default">
              <div className="panel-header">
                <h3 className="card-title">Data Representation</h3>
              </div>
              <div className="panel-body">
                <div className="row">
                  <div className="col-xs-6">
                    <div className="form-group">
                      <select onChange={this.getChosenChart} id="graph_picker" className="selectpicker form-control">
                        <option value={null}>Graph Type...</option>
                        <option value="bar">Bar Graph</option>
                        <option value="line">Line Graph</option>
                      </select>
                    </div>
                  </div>
                  <div className="col-xs-6">
                    <select className="selectpicker form-control">
                      <option value={null}>Metric</option>
                      <option value="kills">Kills</option>
                      <option value="serves">Serves</option>
                      <option value="blocks">Blocks</option>
                    </select>
                  </div>

                </div>
                <div className="row">
                  <div className="col-xs-6">

                    <select className="selectpicker form-control">
                      <option value={null}>Dimension</option>
                      <option value="match">Match</option>
                      <option value="set">Set</option>
                      <option value="team">Team</option>
                      <option value="player">Player</option>
                    </select>
                  </div>
                </div>
              </div>
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
