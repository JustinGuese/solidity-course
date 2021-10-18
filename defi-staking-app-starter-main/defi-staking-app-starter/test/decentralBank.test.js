const Tether = artifacts.require("Tether");
const REW = artifacts.require("REW");
const DB = artifacts.require("DecentralBank");

require("chai")
.use(require("chai-as-promised"))
.should();

contract("DecentralBank", (accounts) => {
    let tether, rew, db;

    before(async () => {
        tether = await Tether.new();
        rew = await REW.new();
        db = await DB.new(rew.address, tether.address);
        // transfer all tokens to decentralbank
        await tether.transfer(db.address, "1000000000000000000000000", {from: accounts[0]});
        await rew.transfer(db.address, "1000000000000000000", {from: accounts[0]});
    });

    describe("Mock Tether Deployment", async () => {
        it("matches name successfully", async () => {
            const name = await tether.name();
            name.should.equal("Tether");
        });
    });

    describe("REW Deployment", async () => {
        it("matches name successfully", async () => {
            const name = await rew.name();
            name.should.equal("Reward Token");
        });
    });

    // check if transfer successfull
    describe("decentral bank deployment", async () => {
        if("matches name successfully", async() => {
            const name = await db.name();
            name.should.equal("Decentral Bank");
        });

        if("contract has rew", async () => {
            let balance = await rew.balanceOf(db.address);
            balance.should.be.equal("1000000000000000000000000");
        });

        if("contract has tether", async () => {
            let balance = await tether.balanceOf(db.address);
            balance.should.be.equal("1000000000000000000");
        });
    });
});