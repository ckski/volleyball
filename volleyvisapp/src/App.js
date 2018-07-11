// TODO: - Think about removing sourceSelectedURL from app state, might be useless


import React, { Component } from 'react';
import logo from './logo.svg';
import './App.css';
import axios from 'axios';
// import chartjs from 'react-chartjs';

// Import statements for all supported graph types
import {Bar, Line, Radar, Doughnut, Polar} from 'react-chartjs-2';

// Set up the chart Data and Configuration
let chartData = {
  labels : ["TestOne", "TestTwo", "TestThree", "TestFour", "TestFive", "TestSix"],
  datasets: [{
    label: '# of kills',
    data: [4,2,3,5,6,3],
    backgroundColor: [
      '#989FCE',
      '#347FC4',
      '#272838',
      '#F2FDFF',
      '#9AD4D6',
      '#DBCBD8',
      '#989FCE',
      '#347FC4',
      '#272838',
      '#F2FDFF',
      '#9AD4D6'
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




class App extends Component {

  constructor(){
    super();

    this.getChosenChart = this.getChosenChart.bind(this);
    this.renderSelects = this.renderSelects.bind(this);
    this.getGraphWindow = this.getGraphWindow.bind(this);
    this.dataSourceFromURL = this.dataSourceFromURL.bind(this);
    this.updateSourceSelection = this.updateSourceSelection.bind(this);
    this.getRawFromURL = this.getRawFromURL.bind(this);
    this.getFinalData = this.getFinalData.bind(this);
    this.generateQueryURL = this.generateQueryURL.bind(this);
    this.generateColorCode = this.generateColorCode.bind(this);


    // Set default graph to empty div
    this.state = {
      graph_to_render: <div></div>,
      showing_graph: false,
      _source_object: {},
      measures: {Measure: [["kills", "kills"],["service_ace", "service_ace"],["attempts", "attempts"]]},
      dimensions: {Dimension: [["team", "team"], ["player", "player"], ["match", "match"]]},
      baseURL: "http://localhost:80/api/data/sources/",
      sourceSelectedURL: "",
      pickedSource: false,
      pickedDimension: false,
      pickedMeasure: false,
      pickedChartType: false
    }
  }

  updateSourceSelection(key){
    let sourceSelect = document.getElementById(key);
    let selectValue = sourceSelect.options[sourceSelect.selectedIndex].value;
    if(key !== 'unselected' && key !== "Measure" && key !== "Dimension"){


      let sourceSelectedURL = this.state.baseURL + selectValue;
      this.setState({
        sourceSelectedURL: sourceSelectedURL
      });


    }
    if(key === 'Source'){
      let sourceSelectedURL = this.state.baseURL + selectValue;
      this.setState({
        sourceSelectedURL: sourceSelectedURL
      });
      document.getElementById('dimensions').classList.remove('hidden');
      console.log("Source changed, repopulate dimensions");
      // Populate the dimensions state
      this.getRawFromURL(sourceSelectedURL,
       (returnData) => {

         let returnable = [];
         for(let dimension in returnData.dimensions){
           returnable.push([returnData.dimensions[dimension], returnData.dimensions[dimension]]);
         }
         this.setState({
           dimensions: {Dimension: returnable}
         });
       });

    }
    if(key === 'Dimension'){

      // Once Dimensions have been decided use the url that contains the rollup parameters!

      let sourceSelectedURL = this.generateQueryURL() ;

      document.getElementById('measures').classList.remove('hidden');
      console.log("Dimension changed, repopulate measures");
      // Populate the measures state
      this.getRawFromURL(sourceSelectedURL,
       (returnData) => {

         let returnable = [];
         for(let measure in returnData.measures){
           returnable.push([returnData.measures[measure], returnData.measures[measure]]);

         }
         this.setState({
           measures: {Measure: returnable}
         });

       });

    }
    if(key === 'Measure'){
      document.getElementById('graphs').classList.remove('hidden');
      console.log("Measure changed");
    }
  }

  getRawFromURL(url, _callback){
    axios.get(url)
      .then(res => {
        let returnData = [];
        returnData = res.data;
        return _callback(returnData);
      }).catch((err) => {
        console.log(err);
      });
  }

  // Render select elements from object

  renderSelects(optObject, multipleSelect){
    let selects = [];
    for(let key in optObject){
      let keyLength = optObject[key].length;
      let opts = [];
      opts.push(<option key="dummy" value='unselected'>Select...</option>)
      for(let i = 0; i < keyLength; i++){
        opts.push(<option key={optObject[key][i][0]} value={optObject[key][i][0]}>{optObject[key][i][1]}</option>);
      }
      if(!multipleSelect){
        selects.push(<div key={key} className="col-xs-12"><label>{key}</label><select size={keyLength} id={key} onChange={() => this.updateSourceSelection(key)} className='selectpicker sourcePicker form-control'>{opts}</select></div>);
      }
      else {
        selects.push(<div key={key} className="col-xs-12"><label>{key}</label><select size={keyLength + 1} id={key} onChange={() => this.updateSourceSelection(key)} className='selectpicker sourcePicker form-control' multiple>{opts}</select></div>);
      }
    }
    return selects;
  }

  dataSourceFromURL(url, _callback){
    axios.get(url)
      .then(res => {
        let returnData = [];
        for(let val in res.data){
          let keys = Object.keys(res.data[val]);
          returnData.push([res.data[val].id, res.data[val].title]);
        }
        _callback(returnData);
      });

  }

  getGraphWindow(showing){
    if(showing){
      return <div className="">
        <div className="col-xs-10">
          {this.state.graph_to_render}
        </div>
        <div className="col-xs-2">
          <div className="graph-option">
            <input className="form-check-input" id="start_at_0" type="checkbox"></input>
            <label htmlFor="start_at_0">Start at 0</label>
          </div>
          <div className="graph-option">
            <input className="form-check-input" id="hide_scale" type="checkbox" ></input>
            <label htmlFor="show_scale">Show scale</label>
          </div>
        </div>
      </div>;
    }
    else{
      return ;
    }
  }


  generateQueryURL(){
    // Start with dimensions
    let dimensionsSelector = document.getElementById('Dimension');
    let dimensionArray = [];
    for(let i = 0; i < dimensionsSelector.length; i++){
      let opt = dimensionsSelector.options[i];
      if(opt.selected){
        dimensionArray.push(opt.value);
      }
    }

    // Create a url from the dimensions

    let finalQueryURL = this.state.sourceSelectedURL + "/rollup?dims=";

    for(let dimension in dimensionArray){
      console.log(dimensionArray[dimension]);
      finalQueryURL += dimensionArray[dimension];
      if(dimension == 0 && dimensionArray.length > 1){
        finalQueryURL += ",";
      }
    }
    return finalQueryURL;
  }

  getFinalData(_callback){

    // Get data from params and roll up
    let finalQueryURL = this.generateQueryURL();

    // Now get the measures
    let measuresSelector = document.getElementById('Measure');
    let measureArray = [];
    for(let i = 0; i < measuresSelector.length; i++){
      let opt = measuresSelector.options[i];
      if(opt.selected){
        measureArray.push(opt.value);
      }
    }

    let newChartData = this.getRawFromURL(finalQueryURL,
      (returnData) => {
        let newChartData = {
          labels : [],
          datasets: []
        };
        let allMeasures = returnData.measures;
        let allData = returnData.data;
        for(let i = 0; i < allMeasures.length; i++){
          for(let x = 0; x < measureArray.length; x++){
            if(allMeasures[i] === measureArray[x]){
              let dataLength = allData.length;
              let currentDataSet= {
                 label: allMeasures[i],
                 data: [],
                 backgroundColor: []
               };
              for(let z = 0; z < dataLength; z++){

                newChartData.labels.push(allData[z][0]);
                currentDataSet.data.push(allData[z][i+1]);
                currentDataSet.backgroundColor.push(this.generateColorCode());
              }

              newChartData.datasets.push(currentDataSet);

            }
          }
        }



        _callback(newChartData);
    });
  }

  generateColorCode(){
    let letters = '0123456789ABCDEF';
    let color = '#';
    for(let i = 0; i < 6; i++){
      color += letters[Math.floor(Math.random() * 16)];
    }
    return color;
  }


  // Conditionally render the chart segment based on selectpicker

  getChosenChart() {
    this.getFinalData((newChartData) => {
      let chosenGraphPicker = document.getElementById('graph_picker');
      let chosenGraph = chosenGraphPicker.options[chosenGraphPicker.selectedIndex].value;
      console.log(chartData);
      console.log(newChartData);

      this.setState({
        pickedChartType: true
      });
      if(chosenGraph === "bar"){
        console.log(newChartData);
        let bar = <Bar options={chartOptions} data={newChartData}></Bar>;
          this.setState({
            graph_to_render: bar,
            showing_graph: true
          });

        }
        else if(chosenGraph === "line"){
          let line = <Line options={chartOptions} data={newChartData}></Line>;
            this.setState({
              graph_to_render: line,
              showing_graph:true
            });
          }
        else if(chosenGraph === "radar"){
          let line = <Radar options={chartOptions} data={newChartData}></Radar>;
            this.setState({
              graph_to_render: line,
              showing_graph: true
            });
          }
        else if(chosenGraph === "doughnut"){
          let line = <Doughnut options={chartOptions} data={newChartData}></Doughnut>;
            this.setState({
              graph_to_render: line,
              showing_graph: true
            });
          }
        else if(chosenGraph === "polar"){
          let line = <Polar options={chartOptions} data={newChartData}></Polar>;
            this.setState({
              graph_to_render: line,
              showing_graph: true
            });
          }
        else{
          this.setState({
            graph_to_render: <div></div>,
            showing_graph: false
          });
        }

      });
    }



  componentDidMount(){
    this.dataSourceFromURL(this.state.baseURL, (source_object_data) => {
      let _source = {Source: source_object_data};
      this.setState({
        _source_object: _source
      });
    });
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
                {this.renderSelects(this.state._source_object, false)}
              </div>
            </div>
            <div className="panel panel-default">
              <div className="panel-header">
                <h3 className="card-title">Data Representation</h3>
              </div>
              <div className="panel-body">
                <div id="dimensions" className="row hidden">
                  {this.renderSelects(this.state.dimensions, true)}
                </div>
                <hr></hr>
                <div id="measures" className="row hidden">
                  {this.renderSelects(this.state.measures, true)}
                </div>
                <hr></hr>
                <div id="graphs" className="row hidden">
                  <div className="col-xs-12">
                    <label htmlFor="graph_picker">Graph Type</label>
                    <select id="graph_picker" onChange={this.getChosenChart} className="selectpicker form-control">
                      <option id="unselected" value="unselected">Select...</option>
                      <option id="bar" value="bar">Bar</option>
                      <option id="line" value="line">Line</option>
                      <option id="radar" value="radar">Radar</option>
                      <option id="doughnut" value="doughnut">Doughnut</option>
                      <option id="polar" value="polar">Polar</option>
                    </select>
                  </div>
                </div>
              </div>
            </div>

          </form>
          {this.getGraphWindow(this.state.showing_graph)}
        </div>
      </div>
    );
  }
}

export default App;
