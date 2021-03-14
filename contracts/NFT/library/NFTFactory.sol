pragma solidity ^0.5.0;

import "./Governance.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";



contract NFTFactory is Governance{

    uint16 quality1 = 35;
    uint16 quality2 = 70;
    uint16 quality3 = 90;
    uint16 quality4 = 95;
    uint16 quality5 = 99;
    uint256 dnaModulus = 1e16;
    uint256 nonce = 0;


    using SafeMath for uint;
    using SafeMath for uint32;
    using SafeMath for uint256;

    struct NFT {
        bytes32 name;
        uint32 quality;
        uint32 level;
        uint32 medal;
        uint dna;
        uint power;
    }

    NFT [] public NFTs;

    mapping (uint => address) public NFTToOwner;
    mapping (address => uint) public ownerNFTCount;

    event newNFT(uint nftId,uint dna);

    function _generateRandomDNA(address _address) private view returns(uint){
        return uint(keccak256(abi.encodePacked(now,_address,nonce))).mod(dnaModulus);
    }

    function _randomByModulus(uint _modulus) internal view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,nonce))).mod(_modulus);
    }

    function getRandomQuality() private view returns(uint32){
        uint rand = _randomByModulus(100);
        uint32 quality = 0;
        if(rand >= quality5){
            quality = 6;
        }else if(rand>= quality4 && rand < quality5){
            quality = 5;
        }else if(rand>= quality3 && rand < quality4){
            quality = 4;
        }else if(rand>= quality2 && rand < quality3){
            quality = 3;
        }else if(rand>= quality1 && rand < quality2){
            quality = 2;
        }else if(rand < quality1){
            quality = 1;
        }else{
            quality = 1;
        }
        return quality;
    }

    function getInitPower(uint32 quality) private pure returns(uint32){
        uint32 power = 0 ;
        if(quality == 1){
            power = 500;
        }else if(quality == 2){
            power = 1000;
        }else if(quality == 3){
            power = 1500;
        }else if(quality == 4){
            power = 5000;
        }else if(quality == 5){
            power = 8000;
        }else if(quality == 6){
            power = 15000;
        }else{
            power = 500;
        }
        return power;
    }

    function _createNFT(address _address) internal returns(uint){
        uint dna = _generateRandomDNA(_address);
        uint32 quality = getRandomQuality();
        uint32 initPower = getInitPower(quality);
        NFT memory nft = NFT('no name',quality,1,1,dna,initPower);
        NFTs.push(nft) ;
        NFTToOwner[NFTs.length -1] = _address;
        ownerNFTCount[_address] = ownerNFTCount[_address].add(1);
        emit newNFT(NFTs.length.sub(1),dna);
        return NFTs.length.sub(1);
    }


    function _createNFT(address _address,uint32 quality,uint32 power) internal returns(uint){
        uint dna = _generateRandomDNA(_address);
        NFT memory nft = NFT('no name',quality,1,1,dna,power);
        NFTs.push(nft) ;
        NFTToOwner[NFTs.length -1] = _address;
        ownerNFTCount[_address] = ownerNFTCount[_address].add(1);
        emit newNFT(NFTs.length.sub(1),dna);
        return NFTs.length.sub(1);
    }

}