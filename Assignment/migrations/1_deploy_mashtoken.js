// Make sure the MashToken contract is included by requireing it.
const MashToken = artifacts.require("MashToken");

// THis is an async function, it will accept the Deployer account, the network, and eventual accounts.
module.exports = async function (deployer, network, accounts) {
  // await while we deploy the MashToken
  await deployer.deploy(MashToken, "13131331313");
  const mashToken = await MashToken.deployed();

};
