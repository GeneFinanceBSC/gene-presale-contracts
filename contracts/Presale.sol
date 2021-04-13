pragma solidity ^0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./GeneToken.sol";

contract Presale is Ownable {
    using SafeMath for uint256;

    GeneToken public token;
    address payable public dev;
    uint256 public presaleStartTimestamp;
    uint256 public presaleEndTimestamp;
    uint256 public hardCapEthAmount = 6000 ether;
    uint256 public totalDepositedEthBalance;
    uint256 public minimumDepositEthAmount = 0.1 ether;
    uint256 public maximumDepositEthAmount = 50 ether;
    uint256 public rewardTokenAmount;

    mapping(address => uint256) public deposits;

    event Deposited(address indexed user, uint256 amount);
    event Recovered(address token, uint256 amount);
    event TokenOwnerTransfered(address newOwner);

    constructor(
        GeneToken _token,
        uint256 _rewardTokenAmount,
        address payable _dev,
        uint256 _presaleStartTimestamp,
        uint256 _presaleEndTimestamp
    ) public {
        token = _token;
        dev = _dev;
        rewardTokenAmount = _rewardTokenAmount;
        presaleStartTimestamp = _presaleStartTimestamp;
        presaleEndTimestamp = _presaleEndTimestamp;
    }

    receive() payable external {
        deposit();
    }

    function deposit() public payable {
        require(now >= presaleStartTimestamp && now <= presaleEndTimestamp, "presale is not active");
        require(totalDepositedEthBalance.add(msg.value) <= hardCapEthAmount, "deposit limits reached");
        require(deposits[msg.sender].add(msg.value) >= minimumDepositEthAmount && deposits[msg.sender].add(msg.value) <= maximumDepositEthAmount, "incorrect amount");

        uint256 tokenAmount = msg.value.mul(rewardTokenAmount).div(1e18);
        token.mint(msg.sender, tokenAmount);
        totalDepositedEthBalance = totalDepositedEthBalance.add(msg.value);
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        emit Deposited(msg.sender, msg.value);
    }

    function releaseFunds() public {
        require(now >= presaleEndTimestamp || totalDepositedEthBalance == hardCapEthAmount, "presale is active");
        require(msg.sender == dev, "dev: Not Owner");
        dev.transfer(address(this).balance);
    }

    function recoverBEP20(address tokenAddress, uint256 tokenAmount) public {
        require(msg.sender == dev, "dev: Not Owner");
        IERC20(tokenAddress).transfer(this.owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function getDepositAmount() public view returns (uint256) {
        return totalDepositedEthBalance;
    }

    function getLeftTimeAmount() public view returns (uint256) {
        if(now > presaleEndTimestamp) {
            return 0;
        } else {
            return (presaleEndTimestamp - now);
        }
    }

    function transferTokenOwner(address newOwner) public onlyOwner {
        token.transferOwnership(newOwner);
        emit TokenOwnerTransfered(newOwner);
    }
}