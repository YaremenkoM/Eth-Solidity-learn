const MashToken = artifacts.require("MashToken");
const { assert } = require('chai');
const truffleAssert = require('truffle-assertions');

contract("MashToken", async accounts => {
    it("Cannot stake more than owning", async () => {
        mashToken = await MashToken.deployed();

        try {
            await mashToken.stake(1000000000, { from: accounts[2] });
        } catch (error) {
            assert.equal(error.reason, "Cannot stake more than you own");
        }
    });
});