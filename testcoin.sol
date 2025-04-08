// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title TestCoin
 * @dev 简单的 ERC20 Token，允许用户每个地址只领取一次，领取数量在 100 到 100,000 之间。
 * 总供应量限制为 10,000,000 个。此token无任何意义，仅为做任务
 */
contract TestCoin {
    // Token 详细信息
    string public name = "TestCoin";
    string public symbol = "TST";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    uint256 public constant MAX_SUPPLY = 10_000_000 * 10 ** 18;

    // 所有者地址
    address public owner;

    // 用户余额和授权
    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    // 记录哪些地址已经领取过
    mapping(address => bool) public hasClaimed;

    // 事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Claimed(address indexed claimant, uint256 amount);

    // 构造函数，设置合约部署者为所有者
    constructor() {
        owner = msg.sender;
    }

    // 修饰符，仅限所有者调用
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // ERC20 标准函数

    /**
     * @dev 返回账户的余额
     */
    function balanceOf(address account) public view returns (uint256) {
        return balances[account];
    }

    /**
     * @dev 转账函数
     */
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Zero address");
        require(balances[msg.sender] >= amount, "Insufficient balance");

        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev 查看授权额度
     */
    function allowance(address _owner, address spender) public view returns (uint256) {
        return allowances[_owner][spender];
    }

    /**
     * @dev 授权函数
     */
    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Zero address");

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev 从授权账户转账
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Zero address");
        require(balances[sender] >= amount, "Insufficient balance");
        require(allowances[sender][msg.sender] >= amount, "Allowance exceeded");

        balances[sender] -= amount;
        balances[recipient] += amount;
        allowances[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    // 铸造函数，仅限所有者调用
    function mint(address account, uint256 amount) public onlyOwner {
        require(totalSupply + amount <= MAX_SUPPLY, "Exceeds max supply");
        require(account != address(0), "Zero address");

        balances[account] += amount;
        totalSupply += amount;

        emit Transfer(address(0), account, amount);
    }

    // 领取函数，允许每个地址只领取一次
    function claim() public {
        require(!hasClaimed[msg.sender], "Already claimed");

        uint256 randomAmount = _getRandomAmount();
        require(totalSupply + randomAmount <= MAX_SUPPLY, "Exceeds max supply");

        balances[msg.sender] += randomAmount;
        totalSupply += randomAmount;
        hasClaimed[msg.sender] = true;

        emit Transfer(address(0), msg.sender, randomAmount);
        emit Claimed(msg.sender, randomAmount);
    }

    // 内部函数，生成 100 到 100,000 之间的随机数
    function _getRandomAmount() internal view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    block.prevrandao, // 替代 block.difficulty
                    block.timestamp,
                    msg.sender
                )
            )
        );

        uint256 amount = 100 + (random % 99901); // 100 到 100,000
        return amount * 10 ** decimals;
    }

    // 转移所有权函数，仅限所有者调用
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Zero address");
        owner = newOwner;
    }

    // 恢复误发送到合约的 ERC20 代币，仅限所有者调用
    function recoverERC20(address tokenAddress, uint256 amount) public onlyOwner {
        require(tokenAddress != address(this), "Cannot recover own tokens");
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature("transfer(address,uint256)", owner, amount)
        );
        require(success, "Transfer failed");
    }
}
