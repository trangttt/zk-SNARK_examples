var Verifier = artifacts.require("Verifier");


contract('Verifier', function(accounts){
    var acc1 = accounts[0];
    var ctr;

    var A = ["0x26ca862286478112e84c59aaed20febf6a8ae1b098af4a92419ba95e57f281c", 
             "0x1f7c8097b637108f6bb887d24198e180bc3f1719413bced3c4fd209a04b19331"];
    var A_p = ["0x22deeb594b1fc729878804da9eaade1d8f58dcc0c07b32c087edace7644d96a0",
               "0x18ad685a463519c769fa7d90f88005d0fe66eeac93726bc06e89d6bf54f46ebc"]
    var B = [["0x95ba9736598d363746668d874ce2b13b10ca2caafb4592c6b7416b3fa48e82d",
               "0x499f19515bafbd9e35573b612c313e74f68a9bbe6c3eb5053b031b9663b234f"], 
             ["0x2c88cde05336e40c38d1366013da361fc0f1005c0d9c8bd3d6c7cbb96c348bd6", 
              "0x284cd442ee628df11a62f06156563782ba9169af5f8424c52e018057d700191b"]]
    var B_p = ["0xdf93f4806a79abdb879f562211bc4d64d1a1238b9c545573b485cff37853c02", 
               "0x2651de97d07261a0834863e037540a5f44952b7e2cbb0cca0e46eda93a8baea0"]
    var C = ["0xca198371e5de360163ef2ca44de4431530dd9d42b7006273cb5b6edf363d102", 
             "0x21cceee132525c03c2d467733cf89b01d789ad91f2e84c8a729c4346152a26c0"]
    var C_p = ["0x9c52bc2433e5d91ec7d735deb749dd831c8d87dd69f5283e575a92550d45864", 
               "0x2e67de28d9c0365715a36e23e76e3d5fee2f95f6a061c23928322fbd77b68962"]
    var H = ["0x2bf149566dd1251fe3dedf8adf39fb2d886634b6d49b7d7fbed48a1574a0045f", 
             "0x17332f48bb290d3e23173524316c4d9b6d2fe3f54299fae353f3c69ad75295b8"]
    var K = ["0x1fea34d111dfb2c92ba00b4237c8f23d35d568debd8403381f5660fe56e3a60f", 
             "0x3909f0e9eef4b7f19fb33fb3e62676c8c0617c84c2c561dd3cb7cce6e9b73a2"]


    var t = [A, A_p, B_p, C, C_p, H, K];
    for (item in t){
        item[0] = web3.toDecimal(item[0]);
        item[1] = web3.toDecimal(item[1]);
    }

    for (item in B_p){
        item[0] = web3.toDecimal(item[0]);
        item[1] = web3.toDecimal(item[1]);
    }

    it("Test", function(){
        return Verifier.deployed().then(function(ca){
            ctr = ca;
            return ctr.verifyTx(A, A_p, B, B_p, C, C_p, H, K, [5, 1]);
        }).then(function(tx){
           console.log(tx);
        })
   })
})
