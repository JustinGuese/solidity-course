import logo from './logo.svg';
import './App.css';
import React, { Component } from 'react';
import Web3 from 'web3';

class App extends Component {

  async LoadBlockchainData() {
    const web3 = window.web3;
    const accounts = await web3.eth.getAccounts();
    const account = accounts[0];
    const balance = await web3.eth.getBalance(account);
    this.setState({ account, balance });
  }

  async Web3Mount() {
    if (window.ethereum) {
      window.web3 = new Web3(window.ethereum);
      try {
        await window.ethereum.sendAsync('eth_requestAccounts');
        console.log('Web3 injected browser');
      } catch (error) {
        console.log('User denied account access');
      }
    }
  }

  constructor(props) {
    super(props);
    this.state = {
      account: '',
      balance: 0,
    }
    this.Web3Mount();
    this.LoadBlockchainData();
  }

  render() {
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          Plz shit in my mouth
        </p>
        <table>
          <tbody>
            <tr>
              <td>Account:</td>
              <td>{this.state.account}</td>
            </tr>
            <tr>
              <td>Balance:</td>
              <td>{this.state.balance}</td>
            </tr>
          </tbody>
        </table>
      </header>
    </div>
  )
}
}

export default App;
