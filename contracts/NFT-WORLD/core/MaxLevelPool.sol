pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

import '../library/Governance.sol';
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/Math.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC20/SafeERC20.sol";
//import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/token/ERC721/IERC721.sol';
import "../interface/IERC721.sol";

contract MaxLevelReward is Governance {
    using SafeMath for uint256;

    uint256 public DURATION = 30 minutes;
    uint256 public initReward = 10 *1e18;
    uint256 public startTime = now + 365 days;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerPowerStored;

    uint256 public totalPower;

    mapping (address => uint256) public userRewardPerPowerPaid;
    mapping (address => uint256) public rewards;
    mapping (address => uint256) public weightBalances;
    mapping (address => uint256) public lastStakedTime;

    mapping(address => uint256) public powerBalances;
    mapping(uint256 => uint256) public stakeBalances;

    mapping (address => uint256 []) public playerNft;
    mapping (uint256 => uint256) public nftMapIndex;

    bool public hasStart = false;
    uint256 public fixRateBase = 100000;


    IERC721 public nft;
    IERC20 public quoteErc20;
    constructor(address _nftAddress, address _quoteErc20Address) public {
        require(_nftAddress != address(0) && _nftAddress != address(this));
        require(_quoteErc20Address != address(0) && _quoteErc20Address != address(this));
        nft = IERC721(_nftAddress);
        quoteErc20 = IERC20(_quoteErc20Address);
    }

    event RewardAdded(uint256 _reward);
    event StakedNFT(address indexed user, uint256 amount);
    event WithdrawnNFT(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    modifier updateReward (address _account){
        rewardPerPowerStored = rewardPerPower();
        lastUpdateTime = lastTimeRewardApplicable();
        rewards[_account] = earned(_account);
        userRewardPerPowerPaid[_account] = rewardPerPowerStored;

        _;
    }

    modifier checkEnd () {
        if(block.timestamp >= periodFinish){
            //initReward = initReward.mul(50).div(100);
            //rewardRate = initReward.div(DURATION);
            //periodFinish = block.timestamp.add(DURATION);
            //emit RewardAdded(initReward);
            startTime =  now + 365 days;
        }
        _;
    }

    modifier checkStart(){
        require(block.timestamp > startTime ,'NOT START');
        _;
    }


    function stake(uint256 _nftId) public  updateReward(msg.sender) checkEnd checkStart{
        require(msg.sender == nft.ownerOf(_nftId), 'Only Token Owner can stake');
        require(getNftLevel(_nftId) == 31 ,'NFT level must reach 31 ');
        uint256 [] storage nftIds = playerNft[msg.sender];

        nftIds.push(_nftId);
        nftMapIndex[_nftId] = nftIds.length -1;

        uint256 power = getStakeInfo(_nftId);

        uint256 stakedPower = powerBalances[msg.sender];
        uint256 stakingPower = power;

        if(stakingPower > 0){
            powerBalances[msg.sender] =stakedPower.add(stakingPower);
            stakeBalances[_nftId] = stakingPower;
            totalPower = totalPower.add(stakingPower);
        }

        nft.transferFrom(msg.sender,address(this),_nftId);
        lastStakedTime[msg.sender] = now;
        emit StakedNFT(msg.sender, _nftId);

    }

    function withdrawNftAfterEnd(uint256 _nftId)
    public
    {

        uint256[] memory nftIds = playerNft[msg.sender];
        uint256 nftIndex = nftMapIndex[_nftId];

        require(nftIds[nftIndex] == _nftId, "not nft owner");

        uint256 nftArrayLength = nftIds.length-1;
        uint256 tailId = nftIds[nftArrayLength];

        playerNft[msg.sender][nftIndex] = tailId;
        playerNft[msg.sender][nftArrayLength] = 0;
        playerNft[msg.sender].length--;
        nftMapIndex[tailId] = nftIndex;
        nftMapIndex[_nftId] = 0;


        uint256 stakeBalance = stakeBalances[_nftId];
        powerBalances[msg.sender] = powerBalances[msg.sender].sub(stakeBalance);
        totalPower = totalPower.sub(stakeBalance);


        nft.transfer(msg.sender,_nftId);

        stakeBalances[_nftId] = 0;

        emit WithdrawnNFT(msg.sender, _nftId);
    }


    function withdrawNft(uint256 _nftId)
    public
    updateReward(msg.sender)
    checkEnd
    checkStart
    {

        uint256[] memory nftIds = playerNft[msg.sender];
        uint256 nftIndex = nftMapIndex[_nftId];

        require(nftIds[nftIndex] == _nftId, "not nft owner");

        uint256 nftArrayLength = nftIds.length-1;
        uint256 tailId = nftIds[nftArrayLength];

        playerNft[msg.sender][nftIndex] = tailId;
        playerNft[msg.sender][nftArrayLength] = 0;
        playerNft[msg.sender].length--;
        nftMapIndex[tailId] = nftIndex;
        nftMapIndex[_nftId] = 0;


        uint256 stakeBalance = stakeBalances[_nftId];
        powerBalances[msg.sender] = powerBalances[msg.sender].sub(stakeBalance);
        totalPower = totalPower.sub(stakeBalance);


        nft.transfer(msg.sender,_nftId);

        stakeBalances[_nftId] = 0;

        emit WithdrawnNFT(msg.sender, _nftId);
    }

    function withdraw()
    public
    checkStart
    {

        uint256[] memory nftIds = playerNft[msg.sender];
        for (uint8 index = 1; index < nftIds.length; index++) {
            if (nftIds[index] >= 0) {
                withdrawNft(nftIds[index]);
            }
        }
    }

    function getReward() public updateReward(msg.sender) checkEnd checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;
            quoteErc20.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function getPlayerIds( address _account ) public view returns( uint256[] memory nftId )
    {
        nftId = playerNft[_account];
    }

    function getStakeInfo(uint256 _nftId)public view returns (uint256 power){
        power = nft.getPowerById(_nftId);
    }

    function rewardPerPower() public view returns (uint256){
        if(totalPower == 0){
            return rewardPerPowerStored;
        }
        return rewardPerPowerStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime)
            .mul(rewardRate)
            .div(totalPower)
        );
    }


    function startNFTReward(uint256 _startTime)
    external
    onlyGovernance
    updateReward(address(0))
    {
        require(hasStart == false, "has started");
        hasStart = true;

        rewardRate = initReward.div(DURATION);
        //XMPT.transfer(address(this), initReward);
        startTime = _startTime;
        lastUpdateTime = startTime;
        periodFinish = startTime.add(DURATION);

        emit RewardAdded(initReward);
    }


    function lastTimeRewardApplicable() public view returns (uint256){
        return Math.min(block.timestamp,periodFinish);
    }


    function earned (address _account) public view returns (uint256) {
        return powerBalances[_account].mul(rewardPerPower().sub(userRewardPerPowerPaid[_account]))
        .add(rewards[_account]);
    }

    function withdrawLocalToken() external onlyGovernance {
        msg.sender.transfer(address(this).balance);
    }

    function withdrawXMPT() external onlyGovernance {
        quoteErc20.transfer(msg.sender,quoteErc20.balanceOf(address(this)));
    }

    function getNftLevel(uint _nftId) public view returns(uint32){
        uint32 level;
        (, level, , , ) = nft.getNFTById(_nftId);
        return level;
    }
}