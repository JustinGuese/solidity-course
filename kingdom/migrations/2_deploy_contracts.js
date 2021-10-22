const KGDSC = artifacts.require("KingdomSeedCoin");
const KGDAT = artifacts.require("KingdomAttackCoin");
const KGDDF = artifacts.require("KingdomDefenseCoin");
const KB = artifacts.require("KingdomTitles");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(KGDSC);
  const kgdsc = await KGDSC.deployed();
  await deployer.deploy(KGDAT);
  const kgdat = await KGDAT.deployed();
  await deployer.deploy(KGDDF);
  const kgddf = await KGDDF.deployed();

  await deployer.deploy(KB, kgdsc.address, kgdat.address, kgddf.address);
  const kb = await KB.deployed();
  
  await kgdsc.transfer(kb.address, "1000000000000000000000000");
  await kgdat.transfer(kb.address, "1000000000000000000000000");
  await kgddf.transfer(kb.address, "1000000000000000000000000");
}
