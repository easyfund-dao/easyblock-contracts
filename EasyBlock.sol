// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol) Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// ERC20 Interface
interface IERC20 {
    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract EasyBlock {
    // TODO: Should any things be private ?
    // TODO: Emits
    // Shareholder Info
    address[] public holders;
    mapping(address => uint) public shareCount;
    mapping(address => uint) public claimableReward;

    uint public totalShareCount = 0;
    // Manager Info
    address public manager;
    uint public fee = 0; // per 1000
    address public feeCollector;
    // Deposit Token
    address public rewardToken;
    // Purchase Tokens
    address[] public purchaseTokens;
    mapping(address => uint) public purchaseTokensPrice; // In USD
    // StrongBlock Node Holders
    address[] public nodeHolders;


    function EasyBlock(){

    }

    // Deposit to Purchase Methods
    function addPurchaseToken(address _tokenAddress, uint _tokenPrice) external {
        require(msg.sender == manager, "Not Authorized!");
        require(!listContains(purchaseTokens, _tokenAddress), "Token already added.")

        purchaseTokens.push(_tokenAddress);
        purchaseTokensPrice[_tokenAddress] = _tokenPrice;
    }

    function editPurchaseToken(address _tokenAddress, uint _tokenPrice) external {
        require(msg.sender == manager, "Not Authorized!");
        require(listContains(purchaseTokens, _tokenAddress), "Token is not a purchase asset.")

        purchaseTokensPrice[_tokenAddress] = _tokenPrice;
    }

    // Deposit to Share Rewards Methods
    function setDepositToken(address _tokenAddress) external {
        require(msg.sender == manager, "Not Authorized!");
        rewardToken = _tokenAddress;
    }

    // NodeHolders
    function setNodeHolder(address _address) external {
        require(msg.sender == manager, "Not Authorized!");
        require(!listContains(nodeHolders, _address), "Address already added.");
        nodeHolders.push(_address);
    }

    // Manager Related Methods
    function setManager(address _address) external {
        require(msg.sender == manager, "Not Authorized!");
        manager = _address;
    }

    function setFeeCollector(address _address) external {
        require(msg.sender == manager, "Not Authorized!");
        feeCollector = _address;
    }

    function setFee(uint _fee) external {
        require(msg.sender == manager, "Not Authorized!");
        fee = _fee;
    }

    function withdrawToManager(address _token, uint _amount) external {
        require(msg.sender == manager, "Not Authorized!");
        require(listContains(purchaseTokens, _token), "Not a Purchase Token.")
        IERC20( _token ).safeTransfer( manager, _amount);
    }

    function depositRewards(uint _amount) external {
        IERC20(rewardToken ).safeTransferFrom( msg.sender, address(this), _amount );

        uint _feeAmount = div(mul(fee,_amount), 1000);
        IERC20(rewardToken ).safeTransfer(feeCollector, _feeAmount);
        _amount = sub(_amount, _feeAmount);

        for(uint _i = 0; i < holders.length; i++) {
            address _currentHolder = holders[i]
            claimableReward[_currentHolder] = add(claimableReward[_currentHolder], div(mul(_amount, shareCount[_currentHolder]), totalShareCount))
        }
        // TODO: should there be a variable to keep track of all time earnings of both user and protocol
    }

    // Shareholder Methods
    function claimRewards() external {
        IERC20(rewardToken ).safeTransfer( msg.sender, claimableReward[msg.sender]);
        claimableReward[msg.sender] = 0;
        // Same question with above TODO
    }

    function buyShares(address _token, uint _shareCount) external {
        require(listContains(purchaseTokens, _token), "Not a Purchase Token.")

        uint _tokenDecimals = IERC20(_token ).decimals();
        uint _price = purchaseTokensPrice[_token]
        IERC20(_token ).safeTransferFrom( msg.sender, address(this), mul(mul(_price, _tokenDecimals), _shareCount );

        if(!listContains(holders, msg.sender)) {
            holders.push(msg.sender);
            shareCount[msg.sender] = 0;
        }
        shareCount[msg.sender] = add(shareCount[msg.sender], _shareCount);
        totalShareCount = add(totalShareCount, _shareCount);
    }

    // HELPERS START
    /** (Taken from OlympusDAO)
        @notice checks array to ensure against duplicate
        @param _list address[]
        @param _token address
        @return bool
     */
    function listContains( address[] storage _list, address _token ) internal view returns ( bool ) {
        for( uint i = 0; i < _list.length; i++ ) {
            if( _list[ i ] == _token ) {
                return true;
            }
        }
        return false;
    }
    // HELPERS END
}
