// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract BatchAirdrop is AccessControl  {
    using SafeERC20 for IERC20;

    IERC20 public token;
    uint256 public batchSize = 120;
    uint public totalAmount = 0;
    bytes32 public constant DEPOSITER_ROLE = keccak256("DEPOSITER_ROLE");
    bytes32 public constant SET_DISTRIBUTION_ROLE = keccak256("SET_DISTRIBUTION_ROLE");
    bytes32 public constant DISTRIBUTE_ROLE = keccak256("DISTRIBUTE_ROLE");


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
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(DEPOSITER_ROLE, _msgSender());
        _grantRole(DISTRIBUTE_ROLE, _msgSender());
        _grantRole(SET_DISTRIBUTION_ROLE, _msgSender());

    }

    function changeToken(address _token) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token = IERC20(_token);
    }

    function deposit(uint256 _amount) external onlyRole(DEPOSITER_ROLE) {
        require(_amount > 0, "Amount must be greater than 0");
        token.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposited(msg.sender, _amount);
    }

    function resetDistribution() external onlyRole(DEFAULT_ADMIN_ROLE) {
        delete distributions;
        currentDistributionIndex = 0;
        totalAmount = 0;
    }

    function setTotalAmount(uint _amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        totalAmount = _amount;
    }
    
    function setDistribution(address[] calldata _recipients, uint256[] calldata _amounts) external onlyRole(SET_DISTRIBUTION_ROLE) {
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

    function setBatchSize(uint _size) external onlyRole(DEFAULT_ADMIN_ROLE) {
        batchSize = _size;
    }

    function distribute() external onlyRole(DISTRIBUTE_ROLE) {
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
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_to != address(0), "Cant be zero address");
        if (address(_token) == address(0)) {
            (bool success, ) = payable(_to).call{value: _amount}('');
            require(success, "Ether transfer failed");
        } else {
            _token.safeTransfer(_to, _amount);
        }
    }
}