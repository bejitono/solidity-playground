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
    
    /* ============ Constructor ============ */
    
    constructor(address _beneficiary, address[] memory _trustees) {
        beneficiary = _beneficiary;
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(TRUSTEE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(BENEFICIARY, DEFAULT_ADMIN_ROLE);
        
        grantRole(BENEFICIARY, _beneficiary);
        
        for (uint i = 0; i < _trustees.length; i++) {
            grantRole(TRUSTEE, _trustees[i]);
            emit AddedTrustee(_trustees[i]);
        }
    }
    
    receive() payable external {
        emit Deposited(msg.sender, msg.value, address(this).balance);
    }
}