const {deployProxy } = require('@openzeppelin/truffle-upgrades');
const Octoplace = artifacts.require("OctoplaceMarketUpgradeable");

module.exports = async function(deployer) {
  const instance = await deployProxy(Octoplace , ["0xee69E72B0A1524329e6dD66D8c7e974D939e7690"], {deployer, initializer: "init"});
  console.log("Deployed Octoplace", instance.address);

  

  console.log("Deployed Contracts \n");
  console.log("OctoplaceUpgradeable.sol:", instance.address);
  

};