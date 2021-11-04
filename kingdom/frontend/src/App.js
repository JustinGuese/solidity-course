import logo from './logo.svg';
import './App.css';
import React, { Component } from 'react';
import Web3 from 'web3';
import KingdomAttackCoin from './contracts/KingdomAttackCoin.json';
import KingdomSeedCoin from './contracts/KingdomSeedCoin.json';
import KingdomDefenseCoin from './contracts/KingdomDefenseCoin.json';
import KingdomGameMechanic from './contracts/KingdomGameMechanic.json';

class App extends Component {

  async LoadBlockchainData() {
    const web3 = window.web3;
    const accounts = await web3.eth.getAccounts();
    const account = accounts[0];
    let balance = await web3.eth.getBalance(account);
    let loadCount = 0;
    const networkId = await web3.eth.net.getId();
    this.setState({ account, balance, networkId });
    // network related stuff
    console.log(networkId, "networkid");
    console.log(account, "account");
    const kgdatDataAT = await KingdomAttackCoin.networks[networkId];
    console.log(kgdatDataAT.address, "kgdatDataAT");
    const kgdatDataDF = await KingdomDefenseCoin.networks[networkId];
    const kgdatDataSC = await KingdomSeedCoin.networks[networkId];
    const kgdatDataBC = await KingdomGameMechanic.networks[networkId];

    if (kgdatDataAT) {
      const kgdat = new web3.eth.Contract(KingdomAttackCoin.abi, kgdatDataAT.address);
      let balance1 = await kgdat.methods.balanceOf(account).call();
      this.setState({ kgdat : kgdat, kgdat_balance : balance1.toString() });
      loadCount++;
    }
    else {
      console.log("KingdomAttackCoin not deployed to this network");
    }
    if (kgdatDataDF) {
      // next defense
      const kgddf = new web3.eth.Contract(KingdomDefenseCoin.abi, kgdatDataDF.address);
      let balance2 = await kgddf.methods.balanceOf(account).call();
      this.setState({ kgddf : kgddf, kgddf_balance : balance2.toString() });
      loadCount++;
    }
    else {
      console.log("Defensecoin not deployed to this network");
    }
    if (kgdatDataSC) {
      // next seed
      const kgdsc = new web3.eth.Contract(KingdomSeedCoin.abi, kgdatDataSC.address);
      let balance3 = await kgdsc.methods.balanceOf(account).call();
      this.setState({ kgdsc : kgdsc, kgdsc_balance : balance3.toString() });
      loadCount++;
    }
    else {
      console.log("Seedcoin not deployed to this network");
    }
    if (kgdatDataBC) {
      // next bcoin
      const kgdbc = new web3.eth.Contract(KingdomGameMechanic.abi, kgdatDataBC.address);
      let balance4 = await kgdbc.methods.balanceOf(account).call();
      console.log("yo got dat balance for seedycoin, is: ", balance4.toString());
      this.setState({ kgdbc : kgdbc, kgdbc_balance : balance4.toString() });
      loadCount++;
    }
    else {
      console.log("Bankcoin not deployed to this network");
    }
    if (loadCount === 4) {
      // all done so set false
      this.state.loading = false;
    }
    else {
      console.log("Error! Contract not deployed, no detected network! loadcount: ", loadCount)
    }
  }

  async Web3Mount() {
    if (window.ethereum) {
      window.web3 = new Web3(Web3.givenProvider || "http://172.24.208.1:7545");
      try {
        await window.ethereum.enable()
        // await window.ethereum.sendAsync('eth_requestAccounts');
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
      networkId: 0,
      balance: 0,
      kgdat: {},
      kgdat_balance: 0,
      kgddf: {},
      kgddf_balance: 0,
      kgdsc: {},
      kgdsc_balance: 0,
      kgdbc: {},
      kgdbc_balance: 0,
      loading: true
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
        <p>
          Current network id is: {this.state.networkId}
        </p>
        <p>
          Still loading? {this.state.loading ? "Yes" : "No"}
        </p>
        <table>
          <tbody>
            <tr>
              <td>Account:</td>
              <td>{this.state.account}</td>
            </tr>
            <tr>
              <td>Balance of native coin:</td>
              <td>{ this.state.balance }</td>
            </tr>
            <tr>
              <td>Balance of KingdomAttackCoin:</td>
              <td>{this.state.kgdat_balance}</td>
            </tr>
            <tr>
              <td>Balance of KingdomDefenseCoin:</td>
              <td>{this.state.kgddf_balance}</td>
            </tr>
            <tr>
              <td>Balance of KingdomSeedCoin:</td>
              <td>{this.state.kgdsc_balance}</td>
            </tr>
            <tr>
              <td>Balance of KingdomGameMechanic:</td>
              <td>{this.state.kgdbc_balance}</td>
            </tr>
          </tbody>
        </table>
      </header>
    </div>
  )
}
}

export default App;
