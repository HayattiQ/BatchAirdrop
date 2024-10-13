// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract Distributor is Ownable(msg.sender) {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public batchSize = 100;
    uint public totalAmount = 0;

    struct Distribution {
        address recipient;
        uint256 amount;
    }

    Distribution[] public distributions;
    uint256 public currentDistributionIndex;

    event Deposited(address indexed from, uint256 amount);
    event DistributionSet(uint256 totalRecipients, uint256 totalAmount);
    event Distributed(uint256 batchSize, uint256 totalAmount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function changeToken(address _token) external onlyOwner {
        token = IERC20(_token);
    }

    function deposit(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount must be greater than 0");
        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(msg.sender, _amount);
    }

    function deleteDistribution() external onlyOwner {
        delete distributions;
        currentDistributionIndex = 0;
        totalAmount = 0;
    }

    function setTotalAmount(uint _amount) external onlyOwner {
        totalAmount = _amount;
    }
    
    function setDistribution(address[] calldata _recipients, uint256[] calldata _amounts) external onlyOwner {
        uint _recipientLength = _recipients.length;
        require(_recipientLength == _amounts.length, "Arrays must have the same length");
        currentDistributionIndex = 0;

        for (uint256 i = 0; i < _recipientLength; i++) {
            distributions.push(Distribution(_recipients[i], _amounts[i]));
            totalAmount += _amounts[i];
        }

        require(token.balanceOf(address(this)) >= totalAmount, "Insufficient balance for distribution");
        emit DistributionSet(_recipientLength, totalAmount);
    }

    function setBatchSize(uint _size) external onlyOwner {
        batchSize = _size;
    }

    function distribute() external onlyOwner {
        require(distributions.length > 0, "No distributions set");
        require(currentDistributionIndex < distributions.length, "All distributions completed");

        uint256 batchEnd = Math.min(currentDistributionIndex + batchSize, distributions.length);
        uint256 totalDistributed = 0;

        for (uint256 i = currentDistributionIndex; i < batchEnd; i++) {
            Distribution memory dist = distributions[i];
            token.safeTransfer(dist.recipient, dist.amount);
            totalDistributed += dist.amount;
        }

        currentDistributionIndex = batchEnd;
        emit Distributed(batchEnd - currentDistributionIndex, totalDistributed);
    }

    function getDistributionProgress() external view returns (uint256 completed, uint256 total) {
        return (currentDistributionIndex, distributions.length);
    }

    function getContractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }

        function withdrawToken(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOwner {
        require(_to != address(0), "Cant be zero address");
        if (address(_token) == address(0)) {
            (bool success, ) = payable(_to).call{value: _amount}('');
            require(success, "Ether transfer failed");
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }
}