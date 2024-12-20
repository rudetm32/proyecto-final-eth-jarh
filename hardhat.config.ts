import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";


const ALCHEMY_API_KEY = "HEkBF6B8pRZFn_RDxiwpMsc8HQe0cHkf";

// Reemplaza esta clave privada por la clave privada de tu cuenta Sepolia
// Para exportar tu clave privada desde Metamask, abre Metamask y
// ve a Detalles de la Cuenta > Exportar Clave Privada
// Advertencia: NUNCA coloques Ether real en cuentas de prueba
const SEPOLIA_PRIVATE_KEY = "2991dc4a0b41ab8233d9299e570a1eae57b79412934677c50b71e36800e68dba";

const config: HardhatUserConfig = {
  solidity: "0.8.28",
  networks: {
    sepolia: {
      url: `https://eth-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY]
    }
  },
  etherscan: {
    apiKey: "D3F8CM2KFS8X443YVR7T9SXUEA4A6ZM4CT",
  },
};

export default config;
