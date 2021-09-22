const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MashToken contract", function () {
    let MashToken;
    let mashToken;
    let owner;
    let addr1;
    let addr2;
    let addrs;

    beforeEach(async function () {
        MashToken = await ethers.getContractFactory("MashToken");
        [owner, addr1, addr2, ...addrs] = await ethers.getSigners();

        mashToken = await MashToken.deploy(13131313);
        await mashToken.deployed();
    });


    it("Deployment should assign the total supply of tokens to the owner", async function () {
        const ownerBalance = await mashToken.balanceOf(owner.address);
        expect(await mashToken.totalSupply()).to.equal(ownerBalance);
    });

    it("Cannot stake more than account owns", async function () {
        try {
            await mashToken.stake(99999999999);
            expect(false);
        } catch(err){
            expect(err.message).to.contains("Cannot stake more than you owns");
        }
    });

    it("Cannot stake zero amount", async function () {
        try {
            await mashToken.stake(0);
            expect(false);
        } catch(err){
            expect(err.message).to.contains("Need to stake smth, cant stake nothing");
        }
    });


    it("Burns amount of staked tokens from sender address", async function () {
        const initialBalance = await mashToken.balanceOf(owner.address);
        const tokensToStake = 13;

        await mashToken.stake(tokensToStake);
        const resultBalance = await mashToken.balanceOf(owner.address);

        expect(initialBalance - resultBalance).to.equal(tokensToStake);
    });

});