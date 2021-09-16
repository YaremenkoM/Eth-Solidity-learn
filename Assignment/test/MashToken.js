const { assert } = require("chai");

const MashToken = artifacts.require("MashToken");
const Ownable = artifacts.require("MashToken");

//To add beforeEach
// Cant take out ownable testing to another file or even test 2 contracts simultaniosly because of 
//" 'before all' hook: prepare suite for 'can transfer ownership' " error
contract("MashToken", async accounts => {
    it("initial supply", async () => {
        mashToken = await MashToken.deployed();
        let supply = await mashToken.totalSupply();
        assert.equal(supply.toNumber(), 13131331313, "Wrong supply number");
    })

    it("minting", async() => {
        mashToken = await MashToken.deployed();

        let initial_balance = await mashToken.balanceOf(accounts[1]);

        assert.equal(initial_balance.toNumber(), 0, "initial balance for account 1 should be 0");
        let totalSupply = await mashToken.totalSupply();
        await mashToken.mint(accounts[1], 100);

        let after_balance = await mashToken.balanceOf(accounts[1]);
        let after_supply = await mashToken.totalSupply();

        assert.equal(after_balance.toNumber(), 100, "The balance after minting 100 should be 100");
        assert.equal(after_supply.toNumber(), totalSupply.toNumber()+100, "The total supply should have been increased");

        try {
            await mashToken.mint('0x0000000000000000000000000000000000000000', 100);
        } catch (error) {
            
            assert.equal(error.reason, "Cannot mint to zero address", "Failed to stop minting on zero address")
        }
    });

    it("burning", async() => {
        mashToken = await MashToken.deployed();

        let initial_balance = await mashToken.balanceOf(accounts[1]);

        try {
            await mashToken.burn('0x0000000000000000000000000000000000000000', 100)
        } catch (error) {
            assert.equal(error.reason, "Cannot burn from zero address", "Failed to notice burning on 0 address");
        }

        try {
            await mashToken.burn(accounts[1], initial_balance+initial_balance);
        } catch (error) {
            assert.equal(error.reason, "Cannot burn more than the account owns", "Failed to capture too big burns on an account")
        }

        totalSupply = await mashToken.totalSupply();
        try {
            await mashToken.burn(accounts[1], initial_balance - 50);
        }catch(error){
            assert.fail(error);
        }

        let balance = await mashToken.balanceOf(accounts[1]);


        // Make sure balance was reduced and that totalSupply reduced
        assert.equal(balance.toNumber(), initial_balance-50, "Burning 50 should reduce users balance")

        let newSupply = await mashToken.totalSupply();

        assert.equal(newSupply.toNumber(), totalSupply.toNumber()-50, "Total supply not properly reduced")
    })

    it("can transfer tokens", async() => {
        mashToken = await MashToken.deployed();

        let tokets_to_transfer = 100

        let init_sender_balance = await mashToken.balanceOf(accounts[0]);
        let init_recipient_balance = await mashToken.balanceOf(accounts[1]);

        await mashToken.transfer(accounts[1], tokets_to_transfer);

        let result_sender_balance = await mashToken.balanceOf(accounts[0]);
        let result_recipient_balance = await mashToken.balanceOf(accounts[1]);

        assert.equal(result_recipient_balance.toNumber(), init_recipient_balance.toNumber() + tokets_to_transfer, "Amount of money which have to be after transferring on recipient account is not correct");
        assert.equal(result_sender_balance.toNumber(), init_sender_balance.toNumber() - tokets_to_transfer, "Amount of money which have to be after transferring on sender account is not correct");

        try {
            mashToken.transfer(accounts[1], tokets_to_transfer*123, {from: accounts[1]});
        } catch (error) {
            assert.equal(error.reason, "The account not having enought tokens");
        }

        try {
            mashToken.transfer('0x0000000000000000000000000000000000000000', tokets_to_transfer, {from: accounts[1]});
        } catch (error) {
            assert.equal(error.reason, "Cannot transfer from account");
        }

        try {
            mashToken.transfer({from: accounts[1]}, tokets_to_transfer, '0x0000000000000000000000000000000000000000');
        } catch (error) {
            assert.equal(error.reason, "Cannot transfer to account");
        }

    })

    it ("allow account some allowance", async() => {
        mashToken = awaitMashToken.deployed();

        
        try{
            await mashToken.approve('0x0000000000000000000000000000000000000000', 100);    
        }catch(error){
            assert.equal(error.reason, 'Approve cannot be to zero address', "Should be able to approve zero address");
        }

        try{
            await mashToken.approve(accounts[1], 100);    
        }catch(error){
            assert.fail(error); // shold not fail
        }

        let allowance = await mashToken.allowance(accounts[0], accounts[1]);

        assert.equal(allowance.toNumber(), 100, "Allowance was not correctly inserted");
    })

    it("transfering with allowance", async() => {
        mashToken = await MashToken.deployed();

        try{
            await mashToken.transferFrom(accounts[0], accounts[2], 200, { from: accounts[1] } );
        }catch(error){

            assert.equal(error.reason, "You cannot spend that much on this account", "Failed to detect overspending")
        }
        let init_allowance = await mashToken.allowance(accounts[0], accounts[1]);
        console.log("init balalnce: ", init_allowance.toNumber())
        try{
            // Account 1 should have 100 tokens by now to use on account 0 
            // lets try using more 
            let worked = await mashToken.transferFrom(accounts[0], accounts[2], 50, {from:accounts[1]});
        }catch(error){
            assert.fail(error);
        }

        // Make sure allowance was changed
        let allowance = await mashToken.allowance(accounts[0], accounts[1]);
        assert.equal(allowance.toNumber(), 50, "The allowance should have been decreased by 50")

        
    })
})

// contract("Ownable", async accounts => {

//     it("can transfer ownership", async () => {
//         ownable = await Ownable.deployed();

//         let owner = await ownable.owner();

//         assert.equal(owner, accounts[0], "The owner was not properly assigned");
//         await ownable.transferOwnership(accounts[1]);
//         let new_owner = await ownable.owner();

//         assert.equal(new_owner, accounts[1], "The ownership was not transferred correctly");
//     });

//     it("onlyOwner modifier", async () => {
//         ownable = await Ownable.deployed();
        
//         try {
//             await ownable.transferOwnership(accounts[2], { from: accounts[2]});
//         }catch(error){
//             assert.equal(error.reason, "Ownable: only owner can call this function", "Failed to stop non-owner from calling onlyOwner protected function");
//         }
        

//     });

//     it("renounce ownership", async () => {
//         ownable = await Ownable.deployed();

//         await ownable.renounceOwnership({ from: accounts[1]});
//         let owner = await ownable.owner();
//         assert.equal(owner, '0x0000000000000000000000000000000000000000', 'Renouncing owner was not correctly done')
        
//     })

// });