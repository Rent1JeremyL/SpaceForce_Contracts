const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("CSPFORCE");
  //const URI = "ipfs://QmRBVSd79z4TxDcq1J7qHcfvP9cfrjkFWDMhb5ZciXaPj4";
  const URI = "ipfs://QmNmssw5hQeHjaNPuWLELebFsDD9wv7VVXPMv2yzS3Tdg7";
  const WALLET_ADDRESS = "0xBC5dAf8bCD482EF62d3977DC93c35740d51Dd533";
  //const WALLET_ADDRESS = "0x11F7Ff9BE8195CbB144d368B3742Fc714c9570B8";
  const CONTRACT_ADDRESS = "0x39949b5Cb777746501742bd4D0C3eBaDe85dFA81";
  const contract = NFT.attach(CONTRACT_ADDRESS);
  await contract.mint(WALLET_ADDRESS, URI);
  console.log("NFT minted:", contract);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});