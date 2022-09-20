const { run } = require("hardhat");
const { deployer } = await getNamedAccounts();

async function main() {
  //Getting a previously deployed contract
  const Staker = await ethers.getContract("Staker", deployer);
  if (chainId !== "31337") {
    try {
      console.log(" 🎫 Verifing Contract on Etherscan... ");
      await sleep(3000); // wait 3 seconds for deployment to propagate bytecode
      await run("verify:verify", {
        address: Staker.address,
        contract: "contracts/Staker.sol:Staker",
        contractArguments: [],
      });
    } catch (e) {
      console.log(" ⚠️ Failed to verify contract on Etherscan ");
    }
  }
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
