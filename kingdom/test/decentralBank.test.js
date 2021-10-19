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

        it("matches balance after purchase", async() => {
            let res
            res = await kb.buyForETH({from: accounts[1], value: web3.utils.toWei("1", "ether")});
            let balance = await kgdsc.balanceOf(accounts[1]);
            balance = balance.toString();
            balance.should.equal("100000000000000000000");
        });
    });

    describe("staking for KGDAT", async () => {
        it("should be possible to stake kgdsc for kgdat", async() => {
            let res
            // stake half the kgdsc for attack points
            res = await kb.plantForAttackpoints("50000000000000000000", {from: accounts[1]});
            let balance = await kgdsc.balanceOf(accounts[1]);
            balance = balance.toString();
            balance.should.equal("50000000000000000000");
        });
    });

});