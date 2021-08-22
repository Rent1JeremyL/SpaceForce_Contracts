const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("CSPFORCE");
  const CONTRACT_ADDRESS = "0x585aea01dd354Ad7cD3a58dc3d93657ed08052A4";
  const contract = NFT.attach(CONTRACT_ADDRESS);
  const owner = await contract.ownerOf(1);
  console.log("Owner:", owner);
  const uri = await contract.tokenURI(1);
  console.log("URI: ", uri);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});