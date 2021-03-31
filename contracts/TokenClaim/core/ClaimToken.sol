pragma solidity ^0.5.0;

import "../library/Governance.sol";
import "../interface/IERC20.sol";

contract ClaimToken is Governance {

    mapping(address => uint256) public unclaimedToken;

    IERC20 public token = IERC20(0x4A2d7984A2c35780E431675053Ba93Af674e9520);



    function setUnclaimedToken(address[] memory accounts, uint256[] memory amounts) public onlyGovernance returns (bool success) {
        require(accounts.length == amounts.length, "bad input");

        for (uint256 i = 0; i < accounts.length; i++) {

            unclaimedToken[accounts[i]] = unclaimedToken[accounts[i]] + amounts[i];
        }

        return true;
    }




    function claim() public returns (bool success) {


        uint256 tokenValue = unclaimedToken[msg.sender];
        require(tokenValue > 0, "no unclaimable token");
        require(tokenValue * 1e18 <= token.balanceOf(address(this)), "no enough tokens");
        unclaimedToken[msg.sender] = 0;
        token.transfer(msg.sender, tokenValue * 1e18);

        return true;
    }
}