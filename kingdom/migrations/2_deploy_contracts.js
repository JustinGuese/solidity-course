const KGDSC = artifacts.require("KingdomSeedCoin");
const KGDAT = artifacts.require("KingdomAttackCoin");
const KGDDF = artifacts.require("KingdomDefenseCoin");
const KGDTI = artifacts.require("KingdomTitles");
// const KGDGM = artifacts.require("KingdomGameMechanic");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(KGDSC);
  const kgdsc = await KGDSC.deployed();
  await deployer.deploy(KGDAT);
  const kgdat = await KGDAT.deployed();
  await deployer.deploy(KGDDF);
  const kgddf = await KGDDF.deployed();

  await deployer.deploy(KGDTI, kgdsc.address, kgdat.address, kgddf.address);
  const kgdti = await KGDTI.deployed();

  // game mechanic as own deployment
  // await deployer.deploy(KGDGM, kgdti.address);
  // const kgdgm = await KGDGM.deployed();
  
  await kgdsc.transfer(kgdti.address, "1000000000000000000000000");
  await kgdat.transfer(kgdti.address, "1000000000000000000000000");
  await kgddf.transfer(kgdti.address, "1000000000000000000000000");
}
