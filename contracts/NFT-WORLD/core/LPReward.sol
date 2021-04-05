pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/Math.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v2.5.0/contracts/ownership/Ownable.sol";

import "../interface/IERC20.sol";

import "../library/LPTokenWrapper.sol";
//import "../library/SafeERC20.sol";

contract LPReward is LPTokenWrapper{

    //IERC20 public _XMPT = IERC20(0x1E2FC5E6D3C954c6c2E7B74CE65F920750CA5a64);
    IERC20 public _XMPT = IERC20(0x4A2d7984A2c35780E431675053Ba93Af674e9520);

    address public _teamWallet = 0x3D0a845C5ef9741De999FC068f70E2048A489F2b;

    uint256 public constant DURATION = 7 days;

    uint256 public _initReward = 2100000 * 1e18;
    uint256 public _startTime =  now + 365 days;
    uint256 public _periodFinish = 0;
    uint256 public _rewardRate = 0;
    uint256 public _lastUpdateTime;
    uint256 public _rewardPerTokenStored;

    uint256 public _teamRewardRate = 500;
    uint256 public _baseRate = 10000;
    uint256 public _punishTime = 3 days;

    mapping(address => uint256) public _userRewardPerTokenPaid;
    mapping(address => uint256) public _rewards;
    mapping(address => uint256) public _lastStakedTime;

    bool public _hasStart = false;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);


    modifier updateReward(address account) {
        _rewardPerTokenStored = rewardPerToken();
        _lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            _rewards[account] = earned(account);
            _userRewardPerTokenPaid[account] = _rewardPerTokenStored;
        }
        _;
    }

    /* Fee collection for any other token */
    function seize(IERC20 token, uint256 amount) external onlyGovernance{
        require(token != _XMPT, "reward");
        require(token != _lpToken, "stake");
        token.transfer(_governance, amount);
    }

    function setTeamRewardRate( uint256 teamRewardRate ) public onlyGovernance{
        _teamRewardRate = teamRewardRate;
    }

    function setWithDrawPunishTime( uint256  punishTime ) public onlyGovernance{
        _punishTime = punishTime;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, _periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalPower() == 0) {
            return _rewardPerTokenStored;
        }
        return
        _rewardPerTokenStored.add(
            lastTimeRewardApplicable()
            .sub(_lastUpdateTime)
            .mul(_rewardRate)
            .div(totalPower())
        );
    }

    function earned(address account) public view returns (uint256) {
        return
        balanceOfPower(account)
        .mul(rewardPerToken().sub(_userRewardPerTokenPaid[account]))
        .add(_rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount)
    public
    updateReward(msg.sender)
    checkHalve
    checkStart
    {
        require(amount > 0, "Cannot stake 0");
        super.stake(amount);

        _lastStakedTime[msg.sender] = now;

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
    public
    updateReward(msg.sender)
    checkHalve
    checkStart
    {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit Withdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) checkHalve checkStart {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            _rewards[msg.sender] = 0;

            uint256 teamReward = reward.mul(_teamRewardRate).div(_baseRate);
            if(teamReward>0){
                _XMPT.transfer(_teamWallet, teamReward);
            }
            uint256 leftReward = reward.sub(teamReward);

            if(leftReward>0){
                _XMPT.transfer(msg.sender, leftReward );
            }

            emit RewardPaid(msg.sender, leftReward);
        }
    }

    modifier checkHalve() {
        if (block.timestamp >= _periodFinish) {
            _initReward = _initReward.mul(50).div(100);

            //_XMPT.mint(address(this), _initReward);

            _rewardRate = _initReward.div(DURATION);
            _periodFinish = block.timestamp.add(DURATION);
            emit RewardAdded(_initReward);
        }
        _;
    }

    modifier checkStart() {
        require(block.timestamp > _startTime, "not start");
        _;
    }

    // set fix time to start reward
    function startReward(uint256 startTime)
    external
    onlyGovernance
    updateReward(address(0))
    {
        require(_hasStart == false, "has started");
        _hasStart = true;

        _startTime = startTime;

        _rewardRate = _initReward.div(DURATION);
        //_XMPT.mint(address(this), _initReward);

        _lastUpdateTime = _startTime;
        _periodFinish = _startTime.add(DURATION);

        emit RewardAdded(_initReward);
    }

    //

    //for extra reward
    function notifyRewardAmount(uint256 reward)
    external
    onlyGovernance
    updateReward(address(0))
    {
        IERC20(_XMPT).transferFrom(msg.sender, address(this), reward);
        if (block.timestamp >= _periodFinish) {
            _rewardRate = reward.div(DURATION);
        } else {
            uint256 remaining = _periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(_rewardRate);
            _rewardRate = reward.add(leftover).div(DURATION);
        }
        _lastUpdateTime = block.timestamp;
        _periodFinish = block.timestamp.add(DURATION);
        emit RewardAdded(reward);
    }
}