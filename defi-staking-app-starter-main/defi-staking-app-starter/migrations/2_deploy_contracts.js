const Tether = artifacts.require("Tether");
const REW = artifacts.require("REW");
const DB = artifacts.require("DecentralBank");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(Tether);
  const tether = await Tether.deployed();
  await deployer.deploy(REW);
  const rwd = await REW.deployed();

  await deployer.deploy(DB, rwd.address, tether.address);
  const db = await DB.deployed();
  
  await rwd.transfer(db.address, "1000000000000000000000000");

  // distribute 100 tether to investor
  await tether.transfer(accounts[1], "1000000000000000000");
};
