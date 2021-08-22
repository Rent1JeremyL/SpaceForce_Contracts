const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("CSPFORCE");
  const URI = "ipfs://QmRBVSd79z4TxDcq1J7qHcfvP9cfrjkFWDMhb5ZciXaPj4";
  const WALLET_ADDRESS = "0xBC5dAf8bCD482EF62d3977DC93c35740d51Dd533";
  const CONTRACT_ADDRESS = "0x585aea01dd354Ad7cD3a58dc3d93657ed08052A4";
  const contract = NFT.attach(CONTRACT_ADDRESS);
  await contract.mint(WALLET_ADDRESS, URI);
  console.log("NFT minted:", contract);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});