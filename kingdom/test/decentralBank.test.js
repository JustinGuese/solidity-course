const KGDSC = artifacts.require("KingdomSeedCoin");
const KGDAT = artifacts.require("KingdomAttackCoin");
const KGDDF = artifacts.require("KingdomDefenseCoin");
const KB = artifacts.require("KingdomBank");

require("chai")
.use(require("chai-as-promised"))
.should();

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

        it("customer kgdsc: matches balance after purchase", async() => {
            let res
            console.log("piss in my mouth1");
            let prev_balance = await kgdsc.balanceOf(accounts[1]);
            // prev_balance = new web3.utils.BN(prev_balance);
            let prev_balance_bank = await kgdsc.balanceOf(kb.address);
            // prev_balance_bank = new web3.utils.BN(prev_balance_bank);
            // 100 is the current multiplicator, therefore 100 instead of 1 ether
            console.log("piss in my mouth2", prev_balance, prev_balance_bank);
            let expected_balance = prev_balance + new web3.utils.BN(web3.utils.toWei("100", "ether"));
            let expected_balance_bank = prev_balance_bank - new web3.utils.BN(web3.utils.toWei("100", "ether"));
            console.log("piss in my mouth3", expected_balance, expected_balance_bank);
            res = await kb.buyForETH({from: accounts[1], value: web3.utils.toWei("1", "ether")});
            console.log("piss in my mouth4", res);
            balance = await kgdsc.balanceOf(accounts[1]);
            balance = balance.toString();
            balance.should.equal(expected_balance.toString());
        });
        it("bank kgdsc: matches balance after purchase", async () => {
            let balance = await kgdsc.balanceOf(kb.address);
            balance = balance.toString();
            balance.should.equal(expected_balance_bank.toString());
        });
    });

    describe("staking for KGDAT", async () => {
        it("should be possible to stake kgdsc for kgdat", async() => {
            let res
            // stake half the kgdsc for attack points
            // approve the contract to spend the amount
            res = await kgdsc.approve(kb.address, "500000000000000000000", {from: accounts[1]});
            res = await kb.plantForAttackpoints("50000000000000000000", {from: accounts[1]});
            let balance = await kgdsc.balanceOf(accounts[1]);
            balance = balance.toString();
            balance.should.equal("50000000000000000000");
        });
    });

    describe("check if staking function works", async () => {
        it("should return the valid amount of coins staked", async() => {
            res = await kb.getCurrentStakes({from: accounts[1]});
            res[0].toString().should.equal("50000000000000000000");
            res[1].toString().should.equal("0");
        });

        // immediate harvesting should not be possible
        it("should not return anything if trying to harvest before stake time over", async() => {
            res = await kb.harvestAll({from: accounts[1]});
            let balance_seed = await kgdsc.balanceOf(accounts[1]);
            let balance_attack = await kgdat.balanceOf(accounts[1]);
            let balance_defense = await kgddf.balanceOf(accounts[1]);
            balance_seed = balance_seed.toString();
            balance_attack = balance_attack.toString();
            balance_defense = balance_defense.toString();
            balance_seed.should.equal("50000000000000000000");
            balance_attack.should.equal("0");
            balance_defense.should.equal("0");
        });

    });

});