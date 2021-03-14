pragma solidity ^0.5.0;
import "../library/NFTOwnership.sol";


contract NFTGame is NFTOwnership {

    uint8 num = 5;
    uint8 public count = 0;
    uint16 public maxLevel = 30;
    uint256 public nonce = 0;
    uint256 public playFee = 0.05 ether;
    uint256 public winnerXMPTRewards = 2 * 1e18;
    //uint256 public burnNFTRewards = 2 * 1e18;
    uint256 public levelUpFee = 1 * 1e18;
    uint256 public buyNFTFee = 0.02 ether;
    uint256 public levelUpPower = 500;

    address[5] plays;
    mapping(uint => address) public nonceToWinner;
    mapping(address => uint) public winnerToCounter;
    mapping(address => uint) public HTRewards;
    mapping(address => uint) public XMPTRewards;



    using SafeMath for uint;

    function buyLottery() public payable returns (bool) {
        require(msg.value >= playFee);
        require(count < num);
        require(joinRequire(msg.sender) == false);
        plays[count] = msg.sender;
        count++;
        if (count == num) {
            distributeRewards();
        }
        return true;
    }

    function joinRequire(address _cormorant) public view returns(bool) {
        bool contains = false;
        for(uint i = 0; i < num; i++) {
            if (plays[i] == _cormorant) {
                contains = true;
            }
        }
        return contains;
    }

    function distributeRewards() private returns(address) {
        //require(count == num);
        if(count == num){
            address winner = plays[winnerNumber()];
            distributeLoser(winner);
            distributeWinner(winner);
            nonceToWinner[nonce] = winner;
            winnerToCounter[winner] = winnerToCounter[winner].add(1);
            delete plays;
            count = 0;
            return winner;
        }

    }

    function distributeLoser(address _winner) private returns(bool){
        for(uint i = 0;i<num; i++){
            if(plays[i] != _winner){
                address(uint160(plays[i])).transfer(playFee*6/5);
            }
        }
    }


    function distributeWinner(address _winner)private returns(bool){
        address(uint160(teamWallet)).transfer(playFee/10);
        XMPT.transfer(_winner,winnerXMPTRewards);
        _createNFT(_winner);
    }


    function getWinnerByOwner(address _owner) external view returns(uint [] memory){
        uint winnerTimes = winnerToCounter[_owner];
        uint [] memory result = new uint [](winnerTimes) ;
        uint counter = 0;
        for(uint i =0;i< nonce;i++){
            if(nonceToWinner[i] == _owner){
                result[counter] = nonce;
                counter ++;
            }
        }
    }


    function winnerNumber() private returns(uint) {
        uint256 winner = uint(keccak256(abi.encodePacked(now, msg.sender, nonce))).mod(5);
        nonce++;
        return winner;
    }


    function ethJackpot() public view returns(uint256){
        return address(this).balance;
    }

    function xmptJackpot() public view  returns (uint256){
        return XMPT.balanceOf(address(this));
    }

    function burnNFT(uint _nftId) external {
        _burn(msg.sender,_nftId);
        uint256 burnNFTRewards = NFTs[_nftId].level*levelUpFee*6/10;
        XMPT.transfer(msg.sender,burnNFTRewards);
    }

    function getBurnNFTRewards(uint _nftId) public view returns(uint256){
        return  NFTs[_nftId].level*levelUpFee*6/10;
    }

    function buyNFT() external payable returns(uint){
        require(msg.value >= buyNFTFee,'No enough money');
        address(uint160(teamWallet)).transfer(buyNFTFee/10);
        return _createNFT(msg.sender);
    }

    function getNFTById(uint _nftId) public view returns(uint32,uint32,uint32,uint,uint){
        NFT memory n =  NFTs[_nftId];
        return(n.quality,n.level,n.medal,n.dna,n.power);
    }

    function levelUp (uint _nftId,uint _amount) external onlyOwnerOf(_nftId) returns (uint){
        require(_amount >= levelUpFee,'No enough money');
        require(NFTs[_nftId].level <= maxLevel,'Upgraded to the highest level');
        XMPT.transferFrom(msg.sender,address(this),_amount*9/10);
        XMPT.transferFrom(msg.sender,address(uint160(teamWallet)),_amount/10);
        NFTs[_nftId].level = uint32(NFTs[_nftId].level.add(1));
        if(NFTs[_nftId].level % 5 == 0){
            NFTs[_nftId].medal = uint32(NFTs[_nftId].medal.add(1));
        }
        uint addPower = _randomByModulus(levelUpPower).add(levelUpPower *  NFTs[_nftId].quality);
        NFTs[_nftId].power = uint32(NFTs[_nftId].power.add(addPower));
        return 1;

    }
}