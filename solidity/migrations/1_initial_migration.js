var Migrations = artifacts.require("./Migrations.sol");
var Verifier = artifacts.require("./verifier.sol");
var SudokuChecker = artifacts.require("./SudokuChecker.sol");

module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(Verifier);
  deployer.deploy(SudokuChecker);
};
