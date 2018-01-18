pragma solidity ^0.4.14;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal returns (G1Point) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal returns (G2Point) {
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
    }
    /// @return the negation of p, i.e. p.add(p.negate()) should be zero.
    function negate(G1Point p) internal returns (G1Point) {
        // The prime q in the base field F_q for G1
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return the sum of two points of G1
    function add(G1Point p1, G1Point p2) internal returns (G1Point r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 6, 0, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid }
        }
        require(success);
    }
    /// @return the product of a point on G1 and a scalar, i.e.
    /// p == p.mul(1) and p.add(p) == p.mul(2) for all points p.
    function mul(G1Point p, uint s) internal returns (G1Point r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 7, 0, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid }
        }
        require (success);
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] p1, G2Point[] p2) internal returns (bool) {
        require(p1.length == p2.length);
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        assembly {
            success := call(sub(gas, 2000), 8, 0, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid }
        }
        require(success);
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point a1, G2Point a2, G1Point b1, G2Point b2) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](2);
        G2Point[] memory p2 = new G2Point[](2);
        p1[0] = a1;
        p1[1] = b1;
        p2[0] = a2;
        p2[1] = b2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for three pairs.
    function pairingProd3(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](3);
        G2Point[] memory p2 = new G2Point[](3);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        return pairing(p1, p2);
    }
    /// Convenience method for a pairing check for four pairs.
    function pairingProd4(
            G1Point a1, G2Point a2,
            G1Point b1, G2Point b2,
            G1Point c1, G2Point c2,
            G1Point d1, G2Point d2
    ) internal returns (bool) {
        G1Point[] memory p1 = new G1Point[](4);
        G2Point[] memory p2 = new G2Point[](4);
        p1[0] = a1;
        p1[1] = b1;
        p1[2] = c1;
        p1[3] = d1;
        p2[0] = a2;
        p2[1] = b2;
        p2[2] = c2;
        p2[3] = d2;
        return pairing(p1, p2);
    }
}
contract Verifier {
    using Pairing for *;
    struct VerifyingKey {
        Pairing.G2Point A;
        Pairing.G1Point B;
        Pairing.G2Point C;
        Pairing.G2Point gamma;
        Pairing.G1Point gammaBeta1;
        Pairing.G2Point gammaBeta2;
        Pairing.G2Point Z;
        Pairing.G1Point[] IC;
    }
    struct Proof {
        Pairing.G1Point A;
        Pairing.G1Point A_p;
        Pairing.G2Point B;
        Pairing.G1Point B_p;
        Pairing.G1Point C;
        Pairing.G1Point C_p;
        Pairing.G1Point K;
        Pairing.G1Point H;
    }
    function verifyingKey() internal returns (VerifyingKey vk) {
        vk.A = Pairing.G2Point([0xc983b2a3b94493cac89ef1e817b879278246ed7e03ac97c37b5982f0e0444e8, 0xb616897403404b88a7fe14aa50b592cea0db6cc7051a6ae77e87547aa50c874], [0x16ac179e79d6db3d34b6b0dee466ef7028422689cda3c77836d3a18a86875e1a, 0xfe6c2823f85cbf5c93c997bab01e0661ea4c3c6be54ab34b26d4623207b72b3]);
        vk.B = Pairing.G1Point(0x3fd574c8816d488616570635cd67c62ed2ff08047e5e883d4a998745db44811, 0x2826964ba4cd841cdb15968cf55125f0bf9e1ccfb346574cd1454ffeba70768a);
        vk.C = Pairing.G2Point([0x1d863a34418dbfd8ca7a109f2818b0bc5aaf9c32bef57ff7b9e35446ba627c85, 0x2b0f19a8caa91161c446d4231c5caecb42edbabf841848f0f363ee947ca0cae2], [0x305cad1b95def9da3cd4b6bee461c7fdb5b59ab8343edf21cf1da6197947c8e1, 0xb04719a52f0ad919777ee299c033d3e83c2bea36f15f7ce378a18ce9549bbe4]);
        vk.gamma = Pairing.G2Point([0x193ea2b2de16ac3ff5d20d624f660cc92024482fb9f3fc75335e20cf94ab11cf, 0x32f31607cd71fdc2f8f6e04ead9c959396a2f41d52042a6b81dddb2859ba9f1], [0x127c15efc9b50d56368c664fbac7865d760cc9a212485adc36eb240040a2ecc, 0x244e91162701f6a2cd6999d6364d78b1edff9f01af4ca2c594cf5fcba4c24f24]);
        vk.gammaBeta1 = Pairing.G1Point(0x130daaa5ebfb2eef5a6fb247c312cbfb21edee5a450fa4ecde8f9c01d8e11d1d, 0xead03c3519e7385ae360b0ffe28ae84c1f1b50c966ee327b90014f98b0e431d);
        vk.gammaBeta2 = Pairing.G2Point([0x1f13bb735b1dacc7eab0d26d35da7d7cbb4ffd1987bc7202025329f99bea4e9d, 0x2a58cc8afb61d5476fc252a26e94c00714b8bffa94df565c50b68e0795980756], [0xbc9995c7d79a4223b27f1bb54094d3e5371cf8ecc7cd6cd2e2f60a833a70b51, 0x289c0f07d7126ee895aeec1182d207af31cb7c7d68f75cd3cb76824dfc5ceb7]);
        vk.Z = Pairing.G2Point([0x3266b9e85287af4f460547aa3a160bbb5fda83d5d01518fe666b2129bf60386, 0x111ead1676433c22b2f1bdcd913c7360be42d6033f2645d84d4521a96114e44c], [0xfba9def2c4446824b4e13840598653fc1e32875e0ed6ef2db80b6acf8a2e50d, 0x285913afc2c3eb739569ed3d00ad07a8545a4b6dd0536316b9130107c60f78ef]);
        vk.IC = new Pairing.G1Point[](8);
        vk.IC[0] = Pairing.G1Point(0x2831361de0db3c1b2164018e8aadc85d8e7b88f8f316252db9c870a96377ca37, 0x99b7d86c13aa2a8f93480c52d4e930762e2848c51865ae75b737f033ea96f95);
        vk.IC[1] = Pairing.G1Point(0x2fe25b30eb3390996cc8b81d6612ec0dd451d9bd72323667205a8e70be5c98a0, 0x3c7964f675a79253526f5458f96656087a44aca5ac94655f3487993f0edc405);
        vk.IC[2] = Pairing.G1Point(0x394e11770a2bd788d26c50d12c33267ee1be8722dcd4a5768baa2559592acb0, 0x8bb97ce9e5e74e0acc150d69dab79b70c4651f84ac38f77a1928d5ede27086a);
        vk.IC[3] = Pairing.G1Point(0xb8c0075776504af7f1a4663ff81f0c6e8160f0ae4a8650a3e716e433ccf8be9, 0x6a121676a89f720a90da19dcfde5acf9148d0d6046f9c8f3c53fb2bfd675c75);
        vk.IC[4] = Pairing.G1Point(0x13d9c2591bd14e8c2085baf61f5fd7395755b3376917d9f5d0ef8184a490bb63, 0x926ebf795178846218baed830b1704ba8e3961fcf560a2bf89c67e606afb02b);
        vk.IC[5] = Pairing.G1Point(0x1c084325e09d3a5a4362acae3cb33940d191e36359bbf16311fbdd82f62d540, 0x30458985c1a7d5cf8fd88b5a88647436958f5254bd493330bde58bfffc362bdf);
        vk.IC[6] = Pairing.G1Point(0x122a9066b58867f62757d466df0c364720d5187caee84007ec7f34c51f224a92, 0x188df5659627bda85479651de619cc8fc54fdeef790bc06ec70c740e96249d7b);
        vk.IC[7] = Pairing.G1Point(0xa70eb59c57750a20778659213c6ca862d3676e74f60d0e8b542725f9617044d, 0x1aa3480cf6a1dd432fd268c30ae75bf4585ed7e8813b997845d6ebd17fe1cc9d);
    }
    function verify(uint[] input, Proof proof) internal returns (uint) {
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length);
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++)
            vk_x = Pairing.add(vk_x, Pairing.mul(vk.IC[i + 1], input[i]));
        vk_x = Pairing.add(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd2(proof.A, vk.A, Pairing.negate(proof.A_p), Pairing.P2())) return 1;
        if (!Pairing.pairingProd2(vk.B, proof.B, Pairing.negate(proof.B_p), Pairing.P2())) return 2;
        if (!Pairing.pairingProd2(proof.C, vk.C, Pairing.negate(proof.C_p), Pairing.P2())) return 3;
        if (!Pairing.pairingProd3(
            proof.K, vk.gamma,
            Pairing.negate(Pairing.add(vk_x, Pairing.add(proof.A, proof.C))), vk.gammaBeta2,
            Pairing.negate(vk.gammaBeta1), proof.B
        )) return 4;
        if (!Pairing.pairingProd3(
                Pairing.add(vk_x, proof.A), proof.B,
                Pairing.negate(proof.H), vk.Z,
                Pairing.negate(proof.C), Pairing.P2()
        )) return 5;
        return 0;
    }
    event Verified(string);
    function verifyTx(
            uint[2] a,
            uint[2] a_p,
            uint[2][2] b,
            uint[2] b_p,
            uint[2] c,
            uint[2] c_p,
            uint[2] h,
            uint[2] k,
            uint[7] input
        ) returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.A_p = Pairing.G1Point(a_p[0], a_p[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.B_p = Pairing.G1Point(b_p[0], b_p[1]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        proof.C_p = Pairing.G1Point(c_p[0], c_p[1]);
        proof.H = Pairing.G1Point(h[0], h[1]);
        proof.K = Pairing.G1Point(k[0], k[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            Verified("Transaction successfully verified.");
            return true;
        } else {
            return false;
        }
    }
}
