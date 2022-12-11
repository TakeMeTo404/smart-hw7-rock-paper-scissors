import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    goerli: {
      url: 'https://goerli.infura.io/v3/78206d458f054785a3288d0ecf4880e2',
      accounts: ['1307520d08d2b058ae69b88eee67c825216fd224baf04e6ab61dd666d77b008d']
    }
  }
};

export default config;
