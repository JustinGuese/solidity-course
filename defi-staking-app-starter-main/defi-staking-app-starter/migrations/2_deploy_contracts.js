const Tether = artifacts.require("Tether");
const REW = artifacts.require("REW");
const DB = artifacts.require("DecentralBank");

module.exports = async function (deployer) {
  await deployer.deploy(Tether);
  await deployer.deploy(REW);
  await deployer.deploy(DB);
};
