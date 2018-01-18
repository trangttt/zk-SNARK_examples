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
        vk.A = Pairing.G2Point([0x14cd513cbc100dbf34f680c76c463e628377f3fb9d34754df56108b8c6f78a93, 0xd1873a3f0735d850635322f14ca448666c58448b76df1bd1853ac7e330f014f], [0x26a53ba8a555336d7b58a09bcf020e4b0926546f8f591a7709dceec706171abd, 0x257baeaad2192651913e0579e466c28f3fb87e4a051f1bc166e9eb73d344d521]);
        vk.B = Pairing.G1Point(0x13cc59d4a410949f9141b899d7029b600a3dd2a16e785b75daa0aecee081714f, 0x2b54fc554e645adc638163057794184f81192a83706084a80fd977fb934f82);
        vk.C = Pairing.G2Point([0x1757adc0f04ec36837f8179e3ec537fafc7c2424914660da2e8fdfcbd65cc1df, 0x1c4817952bb291719d8065842dec0840c4399835e158e0f1a1055efa78f03b3c], [0x23d076686279b8d6133c3da03dcabeb555bc8c46f4ffef6e0f0072eb3b2dfd3a, 0x197749f9224137d703b00ab2ce01b3806eb5e1dca159566a5fd418d20ac8e2ec]);
        vk.gamma = Pairing.G2Point([0xd7efdeff660312e780bb120fbfe717f588580ef814decabb517fc6c82078d90, 0x133c6d71b6a1dd6e5c6c3a99c37011a441a3f770bd5456accba2a7adaaf01de8], [0x1f86579e98f5da19951603031aa9ee0f03ae50e0eb0fb4fe0f759930855f72c0, 0x209aa3375a18c967eb309ecf0e0a58300ad25ce20b12dd55842556af2fb72aab]);
        vk.gammaBeta1 = Pairing.G1Point(0x2d5653bd574aa45d253309a4ca6a4c6e9c45c2f87fb5ab59b24f151b437d2a21, 0x2bb584f6157fbe38c54aa8e1b7332e00cf50c39f9710e569f513384aa2aadeec);
        vk.gammaBeta2 = Pairing.G2Point([0x7d39fdc66a0dc5695336b04f370ee148e2f6678e5ba7eb50ddb0a91ff6fb6e, 0x30280ff9b9b104e733f7f0cd7ceeac313debe98a5eeb48b49b1d0ccc45c0c31d], [0x4957e2492a98c1235050db903fa6626a87b6487f1b9ef611058280a217ecbab, 0xb4550d0fa331c8fcda2463c3d21bd2200380486ba04e43321ddbcb596b434e6]);
        vk.Z = Pairing.G2Point([0x7cc1436a5c58af1bed267b1b9d9ff22bf78b65fd26d658a0e0c0fed34103fd1, 0x21be285086d55194426d10b812ece8e05ab50437879d583fb0a1abd96b546a79], [0x224a9b81cb69a1b6b4a59ad3d516f46b666e26f5e381aa92c784d5d607257b4, 0xad438d9d33618cb3c8e9484cfa78b1aee6a6688acd91ff7a5137361cc9aa44f]);
        vk.IC = new Pairing.G1Point[](3);
        vk.IC[0] = Pairing.G1Point(0x214bd02299751b5ae62473b60cc12195a76e31f9f690deb7d130619006f4a7fc, 0x1320b1ab6b9075f85487d11379694dbd37e47268cf4c269d29373264795ecd71);
        vk.IC[1] = Pairing.G1Point(0x271edd9c8337ea83a75db3291d44ec139b222cbc3049fbf43b4ae9f71e365aa4, 0x7d7679fe4aabfe15442615164d4df3cc5606fe4a48cd9ac74001cc25ab5c691);
        vk.IC[2] = Pairing.G1Point(0x997b888975324d84e109a27246be153ce7ecbf6febd56ea12d009536c02f3bb, 0x15b848eaa6a2ee4cdaa208627863025d2b6a5bfbea97e1fbf75755cbd3d1baec);
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
            uint[2] input
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
