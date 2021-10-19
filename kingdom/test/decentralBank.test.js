const helper = require("../helpers/truffletimetravel");


const KGDSC = artifacts.require("KingdomSeedCoin");
const KGDAT = artifacts.require("KingdomAttackCoin");
const KGDDF = artifacts.require("KingdomDefenseCoin");
const KB = artifacts.require("KingdomBank");

require("chai")
.use(require("chai-as-promised"))
.should();

async function tryCatch(promise, message) {
    try {
        await promise;
        throw null;
    }
    catch (error) {
        assert(error, "Expected an error but did not get one");
        assert(error.message.startsWith(PREFIX + message), "Expected an error starting with '" + PREFIX + message + "' but got '" + error.message + "' instead");
    }
};

contract("KingdomBank", (accounts) => {
    let kgdsc, kgdat, kgddf, kb;

    before(async () => {
        kgdsc = await KGDSC.new();
        kgdat = await KGDAT.new();
        kgddf = await KGDDF.new();
        kb = await KB.new(kgdsc.address, kgdat.address, kgddf.address);
        // transfer all tokens to decentralbank
        await kgdsc.transfer(kb.address, "1000000000000000000000000", {from: accounts[0]});
        await kgdat.transfer(kb.address, "1000000000000000000000000", {from: accounts[0]});
        await kgddf.transfer(kb.address, "1000000000000000000000000", {from: accounts[0]});
    });

    // check name of shitty coin
    describe("KingdomSeeds Deployment", async () => {
        it("matches name successfully", async () => {
            const name = await kgdsc.name();
            name.should.equal("KingdomSeeds");
        });
    });
    describe("Kingdom Attack Coins Deployment", async () => {
        it("matches name successfully", async () => {
            const name = await kgdat.name();
            name.should.equal("Kingdom Attack Coins");
        });
    });
    describe("Kingdom Defense Coins Deployment", async () => {
        it("matches name successfully", async () => {
            const name = await kgddf.name();
            name.should.equal("Kingdom Defense Coins");
        });
    });
    // check balance
    describe("decentral bank deployment", async () => {
        it("matches name successfully", async() => {
            const name = await kb.name();
            name.should.equal("Kingdom Bank");
        });
        it("contract has kgdsc", async () => {
            let balance = await kgdsc.balanceOf(kb.address);
            balance = balance.toString();
            balance.should.equal("1000000000000000000000000");
        });
        it("contract has kgdat", async () => {
            let balance = await kgdat.balanceOf(kb.address);
            balance = balance.toString();
            balance.should.equal("1000000000000000000000000");
        });
        it("contract has kgddf", async () => {
            let balance = await kgddf.balanceOf(kb.address);
            balance = balance.toString();
            balance.should.equal("1000000000000000000000000");
        });

    });

    // buy some kgdsc with account[1]
    describe("buy KGDSC for ETH", async () => {
        it("should not have any KGDSC before purchase", async() => {
            let balance = await kgdsc.balanceOf(accounts[1]);
            balance = balance.toString();
            balance.should.equal("0");
        });
        it("should not have any kgdat before purchase", async() => {
            let balance = await kgdat.balanceOf(accounts[1]);
            balance = balance.toString();
            balance.should.equal("0");
        });
        it("should not have any kgddf before purchase", async() => {
            let balance = await kgddf.balanceOf(accounts[1]);
            balance = balance.toString();
            balance.should.equal("0");
        });

        it("should buy kgdsc successfully with eth", async() => {
            let ethbal_prev = await web3.eth.getBalance(accounts[1]);
            ethbal_prev_expected = ethbal_prev - new web3.utils.BN(web3.utils.toWei("1", "ether"));
            ethbal_prev_expected = Number(web3.utils.fromWei(ethbal_prev_expected.toString()));
            // console.log("ethbal current",ethbal_prev ,"ethbal_prev_expected: ", ethbal_prev_expected);
            // await fails somehow
            res = await kb.buyForETH({from: accounts[1], value: new web3.utils.BN(web3.utils.toWei("1", "ether"))});
            let ethbal = await web3.eth.getBalance(accounts[1]);
            ethbal = Number(web3.utils.fromWei(ethbal.toString()));
            // little less bc gas fee
            ethbal.should.lessThan(ethbal_prev_expected);

            // now check balance of kgdsc
            let balance = await kgdsc.balanceOf(accounts[1]);
            balance = balance.toString();
            // 100 bc our multiplier for purchased eth is 100
            balance.should.equal(web3.utils.toWei("100", "ether"));
        });

        it("should be possible to stake these bought coins for attackcoins", async() => {
            let prev_balance = await kgdsc.balanceOf(accounts[1]);
            prev_balance = prev_balance.toString();
            // stake 75% of seecoins
            // first we need to allow the contract to transfer the tokens
            await kgdsc.approve(kb.address, web3.utils.toWei("100", "ether"), {from: accounts[1]});

            let res = await kb.plantForAttackpoints(web3.utils.toWei("75", "ether"), {from: accounts[1]});
            let balance = await kgdsc.balanceOf(accounts[1]);
            balance = balance.toString();
            // 75% of seecoins should be staked
            balance.should.equal(web3.utils.toWei("25", "ether"));
        });

        it("should not be possible to unstake before time if over", async() => {
            let res = await kb.harvestAll({from: accounts[1]});
            res = await kb.getCurrentStakes({from: accounts[1]});
            let attackPoints = res[0].toString();
            let defensePoints = res[1].toString();
            attackPoints.should.equal(web3.utils.toWei("75", "ether"));
            defensePoints.should.equal("0");
            console.log("in staking: attackpoints/defensepoints", attackPoints, defensePoints);
            // and finally check if balance is still correct
            let balance = await kgdsc.balanceOf(accounts[1]);
            balance = balance.toString();
            balance.should.equal(web3.utils.toWei("25", "ether"));
            // also if attackpoints are not prematurely harvested
            balance = await kgdat.balanceOf(accounts[1]);
            balance = balance.toString();
            balance.should.equal("0");
            // same for def points
            balance = await kgddf.balanceOf(accounts[1]);
            balance = balance.toString();
            balance.should.equal("0");
        });

        it("should be possible to unstake after time ", async() => {
            // forward time 60 seconds 
            helper.advanceTimeAndBlock(61);

            let res = await kb.harvestAll({from: accounts[1]});
            res = await kb.getCurrentStakes({from: accounts[1]});
            let attackPoints = res[0].toString();
            let defensePoints = res[1].toString();
            attackPoints.should.equal("0");
            defensePoints.should.equal("0");

            // check how many seedcoins we have returned
            let balance_seed = await kgdsc.balanceOf(accounts[1]);
            let balance_attack = await kgdat.balanceOf(accounts[1]);
            balance_seed = balance_seed.toString();
            balance_attack = balance_attack.toString();
            console.log("balances of coinds seed/attack", web3.utils.fromWei(balance_seed.toString()), web3.utils.fromWei(balance_attack.toString()));
            // should have 75 eth * .9 = 67.5 eth returned, plus the 25 we still have = 92.5 eth
            balance_seed.should.equal(web3.utils.toWei("92.5", "ether"));
            balance_attack.should.equal(web3.utils.toWei("7.5", "ether"));
        });
    });
});