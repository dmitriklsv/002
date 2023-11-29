const {deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');
const SwapData = artifacts.require("SwapDataUpgradeable");
const SwapNFT = artifacts.require("SwapNFTUpgradeable");

module.exports = async function(deployer) {
  // // const instance = await deployProxy(SwapData , ["0xee69E72B0A1524329e6dD66D8c7e974D939e7690", "0xee69E72B0A1524329e6dD66D8c7e974D939e7690"], {deployer, initializer: "init"});
  // // console.log("Deployed Swap Data", instance.address);

  // const swapnft = await upgradeProxy("0x14459D6C7b398e64E4eC2Edf41d858B83505781b", SwapNFT);
  // console.log("Deployed Swap NFT", swapnft.address)

  // //await instance.contract.methods.grantWriterRole(swapnft.address);

  // // console.log("Deployed Contracts \n");
  // // console.log("Swap Data:", instance.address);
  // console.log("Swap Nft:", swapnft.address);

};
