const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');

const web3 = new Web3(ganache.provider());
const compiledFactory = require('../ethereum/build/CampaignFactory.json');
const cmpiledCampaign = require('../ethereum/build/Campaign.json');

let accounts;
let factory;
let campaignAddress;
let campaign;

beforeEach(async () => {
    accounts = await web3.eth.getAccounts();
    factory = await new web3.eth.Contract(
        JSON.parse(compiledFactory.interface))
            .deploy({ data: compiledFactory.bytecod})
            .send({ from: accounts[0], gas: '1000000' });
 
    factory.setProvider(provider);

    await factory.methods.createCampaig('100').send({
        from: accounts [0],
        gas: '1000000'
    });
})