// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract RewardBnbPool is ERC20 {
    IERC20 public tokenZ; // 质押代币
    uint256 public totalSupplys; // 总质押量
    uint256 public rewardRate; // 奖励发放速率
    uint256 public lastTime; // 最新时间
    uint256 public rewardPerTokenStored; // 奖励值
    mapping(address => uint256) public userRewardPerTokenPaid; // 存储用户奖励值
    mapping(address => uint256) public rewards; // 用户当前可领取奖励值
    mapping(address => uint256) public zBalances; // 用户质押余额

    event Staked(address indexed from, uint256 value); //质押事件
    event Withdrawn(address indexed from, uint256 value); // 释放事件
    event RewardPaid(address indexed from, uint256 value); // 领取事件

    /* 构造函数，传入奖励代币名称，代号，质押代币的合约地址，和初始化区块时间 */
    constructor(IERC20 _tokenZ) ERC20("RewardBNB", "RBNB") {
        tokenZ = _tokenZ;
        lastTime = block.timestamp;
    }

    //质押，每次质押前更新池子奖励
    function stake(uint256 amount) external updateReward(msg.sender) {
        // 检测质押金额是否大于0
        require(amount > 0, "Cannot stake 0");
        // 池子总质押量更新
        totalSupplys = totalSupplys + amount;
        // 用户质押金额更新
        zBalances[msg.sender] = zBalances[msg.sender] + amount;
        // 发送质押代币到池子合约，需提前approve
        tokenZ.transferFrom(msg.sender, address(this), amount);
        // 释放事件
        emit Staked(msg.sender, amount);
    }

    //释放，每次释放前更新池子奖励
    function withdraw(uint256 amount) public updateReward(msg.sender) {
        // 检测提取金额是否大于0
        require(amount > 0, "Cannot withdraw 0");
        // 池子总质押量更新
        totalSupplys = totalSupplys - amount;
        // 用户质押金额更新
        zBalances[msg.sender] = zBalances[msg.sender] - amount;
        // 从合约返回质押代币到用户
        tokenZ.transfer(msg.sender, amount);
        // 释放事件
        emit Withdrawn(msg.sender, amount);
    }

    //领取，每次领取前更新池子奖励
    function claemReward() public updateReward(msg.sender) {
        // 获取当前用户奖励
        uint256 reward = rewards[msg.sender];
        // 若奖励满足条件，则领取
        if (reward > 0) {
            // 重置用户奖励
            rewards[msg.sender] = 0;
            // 再一次检查奖励是否满足条件
            require(reward > 0, "Cannot claim 0");
            // 检查领取时间是否存在漏洞
            require(
                block.timestamp >= lastTime,
                "Too early to withdraw rewards"
            );
            // 发送奖励代币给用户
            _mint(msg.sender, reward);
            // 释放事件
            emit RewardPaid(msg.sender, reward);
        }
    }

    // 计算当前时刻的累加值
    function rewardPerToken() public view returns (uint256) {
        // 如果池子里的数量为0，说明上一个区间内没有必要发放奖励，因此累加值不变
        if (totalSupplys == 0) {
            return rewardPerTokenStored;
        }
        // 计算累加值，上一个累加值加上最近一个区间的单位数量可获得的奖励数量
        return
            rewardPerTokenStored +
            (block.timestamp -
                ((lastTime) * (rewardRate) * (1e18)) /
                (totalSupplys));
    }

    // 计算用户可以领取的奖励数量
    // 质押数量 * （当前累加值 - 用户上次操作时的累加值）+ 上次更新的奖励数量
    function earned(address account) public view returns (uint256) {
        return
            (zBalances[account] *
                (rewardPerToken() - (userRewardPerTokenPaid[account]))) /
            (1e18) +
            (rewards[account]);
    }

    modifier updateReward(address account) {
        // 更新累加值
        rewardPerTokenStored = rewardPerToken();
        // 更新最新有效时间戳
        lastTime = block.timestamp;
        if (account != address(0)) {
            // 更新奖励数量
            rewards[account] = earned(account);
            // 更新用户的累加值
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function update(address account) internal {
        // 更新累加值
        rewardPerTokenStored = rewardPerToken();
        // 更新最新有效时间戳
        lastTime = block.timestamp;
        if (account != address(0)) {
            // 更新奖励数量
            rewards[account] = earned(account);
            // 更新用户的累加值
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }
}
