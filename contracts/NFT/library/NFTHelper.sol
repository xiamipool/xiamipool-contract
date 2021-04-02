pragma solidity ^0.5.0;

import './NFTFactory.sol';
import './NameFilter.sol';
import "../interface/IERC20.sol";

contract NFTHelper is NFTFactory {

    uint16 public maxLevel = 31;

    uint256 public levelUpFee = 100;
    uint256 randNonce = 0;

    IERC20 public XMPT = IERC20(0xE8eAE78Da408A22d72Be3592498aC4F61105bb1D);
    address public teamWallet = 0xB121eb9A2481281ab8a9F533fD45686f786A52AF;

    modifier abovelLevel(uint32 _nftId,uint _level){

        require(NFTs[_nftId].level >= _level,'Level is not suffcient');
        _;
    }
    modifier onlyOwnerOf(uint _nftId){
        require(msg.sender == NFTToOwner[_nftId],'NFT is not yours');
        _;
    }


    function getNFTByOwner(address _owner) external view returns (uint [] memory){
        uint[] memory result = new uint [] (ownerNFTCount[_owner]);
        uint counter = 0;
        for(uint i = 0;i< NFTs.length; i++){
            if(NFTToOwner[i] == _owner){
                result[counter] = i;
                counter = counter.add(1) ;
            }
        }
        return result;
    }

}