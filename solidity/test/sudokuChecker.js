var SudokuChecker = artifacts.require("SudokuChecker");


contract('SudokuChecker', function(accounts){
    var acc1 = accounts[0];
    var ctr;
    var A = ["0xca90662937bec54e8d181d1ee3c0c1bee8c8e6ddb8cca51e0f3e4aed579ec16",
            "0x2568828f7f8fcb39829c75f05292ebebb4d77dda94e8ad1c60fcb9687e6a0efd"]
    var A_p = ["0x96a43c48cc43ceb9541129dd76a223e90ed43b2d7743fa925d7a4c6def226f1",
                "0xc7e581373a4855c02699926f30459d6817e1bfbded59ad09c959eb90fd38b16"]
    var B = [["0x2ed561711dd98e792ad99042448be2dd6847347b9a6deb3b5eeed7baa753e35f",
             "0x8b17f11a8ba6cca46016a9f099727d04cf9489e711accc2074124e1831ef4b7"], 
             ["0xf7ecae219af18cb9bf5e8c4db842b018626158cb988819e8b4a0aff7ea4ec9e", 
             "0x235df3c4c9d8ee370ceb4ce1e41db6288cdf531f1ca7d5b8ccb64b4b0cd5651b"]]
    var B_p = [ "0x79bc6814bcf97725cf08f2d3a13e6ba1b173da67ce3e2739e71394442facd5d", 
             "0x8263591cd49aad0938ccdc038afd355e8886230cfb31c2e921450f83d14ff80" ]
    var C = [ "0x2d33f4734c2b1ed7a30170161a4333588e830a82fae72cf004e8c61a5d1311e", 
             "0x22698acff3a8c6627724678e59641519ec22e5a10913d1ba54872a0384b62a3b" ]
    var C_p = ["0x2607ff2aaf341a2b68c974fdcd143c4a89c219afce50c3b884f724d73023f62b", 
             "0x2b204e499c9044f35ade5bfc129e66ce8f84e07d15dd6e7bc08b6b4f8fae94f5"]
    var H = [ "0x1c9e5f6810515297023f844e1844ede7050171dd51f9fb6a1b04c907c0a4fdb9", 
             "0x87554fae6df3663328cd2c7111591281bd4ba3152ac160e9c9c7e7d0f9fd78b" ]
    var K = ["0x1f30c87f60a75797cf3e4d7ddfa6bb9dbfa631a27cef639522c295a385df480", 
             "0x1343f86229f55346d2220f984585fb12edb53db2fb983f4bf1a0a284f4a3958f"]


    var t = [A, A_p, B_p, C, C_p, H, K];
    for (item in t){
        item[0] = web3.toDecimal(item[0]);
        item[1] = web3.toDecimal(item[1]);
    }

    for (item in B_p){
        item[0] = web3.toDecimal(item[0]);
        item[1] = web3.toDecimal(item[1]);
    }
    // Sudoku input 2- 2- 1 - 4 - 3 -4
    // Solution 3-1-4-4-3-2-1-1-3-2
    // 3 | 2  || 1 | 4
    // 4 | 1  || 2 | 3
    // ========
    // 2 | 3  || 4 | 1
    // 1 | 4  || 3 | 2
    it("Test", function(){
        return SudokuChecker.deployed().then(function(ca){
            ctr = ca;
            return ctr.verifyTx(A, A_p, B, B_p, C, C_p, H, K, [3, 1, 4, 4, 3, 2, 1, 1, 3, 2, 1]);
        }).then(function(tx){
           console.log(tx);
        })
   })
})
