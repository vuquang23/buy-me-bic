// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // const Greeter = await hre.ethers.getContractFactory("Greeter");
  // const greeter = await Greeter.deploy("Hello, Hardhat!");
  // await greeter.deployed();
  // console.log("Greeter deployed to:", greeter.address);

  const avax = "0xa9747f59a3403a48491b598b50fbcea22aa46c17"
  const busd = "0x3A7Ae23aABEc06D4046B07B328BA9dc2AA6DE1c6"

  // whitelist
  const Whitelist = await hre.ethers.getContractFactory("Whitelist")
  const whitelist = await Whitelist.deploy()
  await whitelist.deployed()
  console.log("Whitelist address: ", whitelist.address)


  const BeinGiveTake = await hre.ethers.getContractFactory("BeinGiveTake")
  const beinGiveTake = await BeinGiveTake.deploy()
  await beinGiveTake.deployed()
  console.log("BeinGiveTake address: ", beinGiveTake.address)

  const BICRight = await hre.ethers.getContractFactory("BICRight")
  const bicRight = await BICRight.deploy(beinGiveTake.address)
  await bicRight.deployed()
  console.log("BICRight address: ", bicRight.address)

  const Private = await hre.ethers.getContractFactory("Private")
  const private = await Private.deploy(avax, bicRight.address, beinGiveTake.address, busd, whitelist.address)
  await private.deployed()
  console.log("Private address: ", private.address)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
