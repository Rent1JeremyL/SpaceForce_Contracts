const hre = require("hardhat");

async function main() {
  const NFT = await hre.ethers.getContractFactory("CryptoSpaceForceCard");
  //const URI1 = "QmRBVSd79z4TxDcq1J7qHcfvP9cfrjkFWDMhb5ZciXaPj4";
  //const CARDID1 = "R1_SH_F1_1_T1";  
  
  const URI2 = "QmNmssw5hQeHjaNPuWLELebFsDD9wv7VVXPMv2yzS3Tdg7";
  const CARDID2 = "R1_SH_F2_1_T1";
  
  const WALLET_ADDRESS = "0xBC5dAf8bCD482EF62d3977DC93c35740d51Dd533";
  //const WALLET_ADDRESS = "0x11F7Ff9BE8195CbB144d368B3742Fc714c9570B8";
  const CONTRACT_ADDRESS = "0x39949b5Cb777746501742bd4D0C3eBaDe85dFA81";
  const contract = NFT.attach(CONTRACT_ADDRESS);
  
  //await contract.mintCard(WALLET_ADDRESS, CARDID1, URI1);
  await contract.mintCard(WALLET_ADDRESS, CARDID2, URI2);
  
  console.log("NFT minted:", contract);
}

main().then(() => process.exit(0)).catch(error => {
  console.error(error);
  process.exit(1);
});