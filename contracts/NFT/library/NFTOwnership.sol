pragma solidity ^0.5.0;

import "./NFTHelper.sol";

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC721/ERC721.sol";

contract NFTOwnership is NFTHelper,ERC721{

    mapping (uint => address) nftApprovals;

    function balanceOf(address _owner) public view returns (uint256 _balance){
        return ownerNFTCount[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner){
        return NFTToOwner[_tokenId];
    }

    function totalSupply() public view returns (uint256 _totalSupply){
        return uint256(NFTs.length);
    }

    function _transfer(address _from,address _to,uint256 _tokenId) internal{
        ownerNFTCount[_to] = ownerNFTCount[_to].add(1);
        ownerNFTCount[_from] = ownerNFTCount[_from].sub(1);
        NFTToOwner[_tokenId] = _to;
        emit Transfer(_from,_to,_tokenId);
    }

    function transfer(address _to,uint256 _tokenId) public onlyOwnerOf(_tokenId){
        _transfer(msg.sender,_to,_tokenId);
    }

    function _exists(uint256 _tokenId) internal view returns (bool) {
        address owner = NFTToOwner[_tokenId];
        return owner != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender);
    }

    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return nftApprovals[tokenId];
    }

    function transferFrom(address _from,address _to,uint256 _tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), _tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(_from,_to,_tokenId);
    }

    function approve (address _to,uint256 _tokenId) public {
        address owner = ownerOf(_tokenId);
        require(_to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner,"ERC721: approve caller is not owner");
        nftApprovals[_tokenId] = _to;
        emit Approval(msg.sender,_to,_tokenId);
    }


    function mint(address _to,uint32 _quality,uint32 _power) public onlyGovernance returns(uint256 _tokenId)  {
        uint256 tokenId =  _createNFT(_to,_quality,_power);
        return tokenId;
    }

    function _burn(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner, "ERC721: burn of token that is not own");
        nftApprovals[_tokenId] = address(0);
        ownerNFTCount[_owner] = ownerNFTCount[_owner].sub(1);
        NFTToOwner[_tokenId] = address(0);
        emit Transfer(_owner, address(0), _tokenId);
    }


    function getPowerById(uint256 _tokenId) public view returns (uint256 _power){
        return NFTs[_tokenId].power;
    }
}