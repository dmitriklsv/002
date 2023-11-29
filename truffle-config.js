const HDWalletProvider = require('@truffle/hdwallet-provider');
 
module.exports = {
  networks: {
    theta_privatenet: {
      provider: () => {
        // private key for test wallet #1: 0x19E7E376E7C213B7E7e7e46cc70A5dD086DAff2A 
        var privateKeyTest1 = process.env.ETH_KEY;
 
        // private key for test wallet #2: 0x1563915e194D8CfBA1943570603F7606A3115508
        var privateKeyTest2 = '2222222222222222222222222222222222222222222222222222222222222222';
 
        return new HDWalletProvider({
          privateKeys: [privateKeyTest1, privateKeyTest2],
          providerOrUrl: 'http://localhost:18888/rpc',
        });
      },
      network_id: 366,
      gasPrice: 4000000000000,
    },
 
    theta_testnet: {
      provider: () => {
 
        // Replace the private key below with the private key of the deployer wallet. 
        // Make sure the deployer wallet has a sufficient amount of TFuel, e.g. 100 TFuel
        var deployerPrivateKey = process.env.ETH_KEY;
 
        return new HDWalletProvider({
          privateKeys: [deployerPrivateKey],
          providerOrUrl: 'https://eth-rpc-api-testnet.thetatoken.org/rpc',
        });
      },
      network_id: 365,
      gasPrice: 4000000000000,
    },

    theta_mainnet: {
      provider: () => {
 
        // Replace the private key below with the private key of the deployer wallet. 
        // Make sure the deployer wallet has a sufficient amount of TFuel, e.g. 100 TFuel
        var deployerPrivateKey = process.env.ETH_KEY;
 
        return new HDWalletProvider({
          privateKeys: [deployerPrivateKey],
          providerOrUrl: 'http://172.190.238.225:18888/rpc',
        });
      },
      network_id: 361,
      gasPrice: 4000000000000,
    },
    eth: {
      provider: () => {
 
        // Replace the private key below with the private key of the deployer wallet. 
        // Make sure the deployer wallet has a sufficient amount of TFuel, e.g. 100 TFuel
        var deployerPrivateKey = process.env.ETH_KEY;
 
        return new HDWalletProvider({
          privateKeys: [deployerPrivateKey],
          providerOrUrl: 'https://goerli.infura.io/v3/df332722ac3f48d0acbcb557938aa5bc',
        });
      },
      network_id: 5,
      gasPrice: 4000000000000,
    }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.17", 
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  },
};
