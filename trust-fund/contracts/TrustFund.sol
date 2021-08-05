// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface ITrustFund {
    
}

contract TrustFund is ITrustFund, ReentrancyGuard, AccessControl {
    
    /* ============ Events ============ */
    
    event Deposited(address indexed sender, uint amount, uint balance);
    event AddedTrustee(address indexed trustee);
    event RemovedTrustee(address indexed trustee);
    
    /* ============ Modifiers ============ */
    
    modifier onlyAdmin() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Not an admin");
        _;
    }
    
    modifier onlyTrustee() {
        require(hasRole(TRUSTEE, msg.sender), "Not a trustee");
        _;
    }
    
    modifier onlyBeneficiary() {
        require(hasRole(BENEFICIARY, msg.sender), "Not the beneficiary");
        _;
    }
    
    /* ============ Properties ============ */
    
    using SafeMath for uint256;
    
    bytes32 constant TRUSTEE = keccak256("TRUSTEE");
    bytes32 constant BENEFICIARY = keccak256("BENEFICIARY");
    
    address beneficiary;
    uint256 numberOfTrustees;
    uint256 numberOfReleaseApprovals;
    mapping (address => bool) hasApprovedRelease;
    
    /* ============ Constructor ============ */
    
    constructor(address _beneficiary, address[] memory _trustees) {
        beneficiary = _beneficiary;
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(TRUSTEE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(BENEFICIARY, DEFAULT_ADMIN_ROLE);
        
        grantRole(BENEFICIARY, _beneficiary);
        
        for (uint i = 0; i < _trustees.length; i++) {
            grantRole(TRUSTEE, _trustees[i]);
            numberOfTrustees = numberOfTrustees.add(1);
            emit AddedTrustee(_trustees[i]);
        }
        
        grantRole(TRUSTEE, msg.sender);
        numberOfTrustees = numberOfTrustees.add(1);
    }
    
    receive() payable external {
        emit Deposited(msg.sender, msg.value, address(this).balance);
    }
    
    /* ============ External Functions ============ */
    
    function withdraw(uint256 _amount) external onlyBeneficiary nonReentrant {
        require(address(this).balance >= _amount, "Insufficient funds");
        require(_allTrusteesApproved(), "All trustees must approve release");
        require(_attemptETHTransfer(beneficiary, _amount), "Transfer failed");
    }
    
    function approveRelease() external onlyTrustee {
        require(!hasApprovedRelease[msg.sender], "Already approved");
        hasApprovedRelease[msg.sender] = true;
        numberOfReleaseApprovals = numberOfReleaseApprovals.add(1);
    }
    
    function revokeReleaseApproval() external onlyTrustee {
        require(hasApprovedRelease[msg.sender], "Not yet approved");
        hasApprovedRelease[msg.sender] = false;
        numberOfReleaseApprovals = numberOfReleaseApprovals.sub(1);
    }
    
    function addTrustee(address _trustee) external {
        grantRole(TRUSTEE, _trustee);
        numberOfTrustees = numberOfTrustees.add(1);
        emit AddedTrustee(_trustee);
    }
    
    function removeTrustee(address _trustee) external {
        revokeRole(TRUSTEE, _trustee);
        numberOfTrustees = numberOfTrustees.sub(1);
        emit RemovedTrustee(_trustee);
    }
    
    /* ============ Getter Functions ============ */
    
    function getNumberOfTrustees() external view returns (uint256) {
        return numberOfTrustees;
    }
    
    function getNumberReleaseApprovals() external view returns (uint256) {
        return numberOfReleaseApprovals;
    }
    
    /* ============ Internal Functions ============ */
    
    function _allTrusteesApproved() internal view returns (bool) {
        return numberOfTrustees == numberOfReleaseApprovals;
    }
    
    function _attemptETHTransfer(address _to, uint256 _value) internal returns (bool) {
        (bool success, ) = _to.call{value: _value}("");
        return success;
    }
}