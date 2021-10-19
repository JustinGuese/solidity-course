let kgdsc = await KingdomSeedCoin.new();
let kgdat = await KingdomAttackCoin.new();
let kgddf = await KingdomDefenseCoin.new();

let kgdb = await KingdomBank.new(kgdsc.address, kgdat.address, kgddf.address);

// transfer all coins to bankaccount
await kgdsc.transfer(kgdb.address, "1000000000000000000000000", {from: accounts[0]});
await kgdat.transfer(kgdb.address, "1000000000000000000000000", {from: accounts[0]});
await kgddf.transfer(kgdb.address, "1000000000000000000000000", {from: accounts[0]});

let kgdscBalance = await kgdsc.balanceOf(kgdb.address);
let kgdatBalance = await kgdat.balanceOf(kgdb.address);
let kgddfBalance = await kgddf.balanceOf(kgdb.address);

console.log("kgdscBalance: " + kgdscBalance);
console.log("kgdatBalance: " + kgdatBalance);
console.log("kgddfBalance: " + kgddfBalance);

// buy some seed with eth in account 1
let prebuyaccount1eth = await web3.eth.getBalance(accounts[1]);
console.log("prebuyaccount1eth: " + prebuyaccount1eth);
let res = await kgdb.buyForETH({from: accounts[1], value: 100000});
let postbuyaccount1eth = await web3.eth.getBalance(accounts[1]);
console.log("postbuyaccount1eth: " + postbuyaccount1eth);