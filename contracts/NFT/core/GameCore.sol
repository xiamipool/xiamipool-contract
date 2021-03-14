pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import "./NFTGame.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC721/ERC721Metadata.sol";

contract GameCore is NFTGame{
    string public constant name = "XiaMiPool Test NFT";
    string public constant symbol = "XTFT";
    string public baseUri = "";

    function() external payable {
    }


    function checkBalance() external view onlyGovernance returns(uint) {
        return address(this).balance;
    }


    function setPlayFee(uint _fee) external onlyGovernance{
        playFee = _fee;
    }

    function setWinnerXMPTRewards(uint _rewards)external onlyGovernance{
        winnerXMPTRewards = _rewards;
    }

    function setBuyNFTFee(uint _fee) external onlyGovernance{
        buyNFTFee = _fee;
    }

    function setUpLevelFee(uint _fee) external onlyGovernance{
        levelUpFee = _fee;
    }

    function setBaseURI(string memory _baseUri) public onlyGovernance{
        baseUri = _baseUri;
    }

    function withdraw() external onlyGovernance {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawXMPT() external onlyGovernance {
        XMPT.transfer(msg.sender,XMPT.balanceOf(address(this)));
    }

    function withdrawXMPT(uint _amount) external onlyGovernance {
        XMPT.transfer(msg.sender,_amount);
    }
}