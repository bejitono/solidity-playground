// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Hashing

contract HashaGotchiGame {
    
    struct HashaGotchi {
        string name;
        uint256 strength;
        uint256 experience;
    }
    
    mapping (bytes32 => address) hashaGotchiOwners;
    mapping (address => HashaGotchi[]) gotchis;

    /* ============ Events ============ */

    event AddedGotchi(
        string name, 
        uint256 strength, 
        uint256 experience
    );
    
    /* ============ External Functions ============ */
    
    function addHashaGotchi(
        string memory _name, 
        uint256 _strength, 
        uint256 _experience
    ) external {
        bytes32 hash = _hash(_name, _strength, _experience);
        
        require(msg.sender != address(0), "Address can't be zero");
        require(hashaGotchiOwners[hash] != msg.sender, "HashaGotchi already exists"); 
        
        HashaGotchi memory hashaGotchi = HashaGotchi({
            name: _name,
            strength: _strength,
            experience: _experience
        });
        
        hashaGotchiOwners[hash] = msg.sender;
        HashaGotchi[] storage currentGotchis = gotchis[msg.sender];
        currentGotchis.push(hashaGotchi);

        emit AddedGotchi(_name, _strength, _experience);
    }
    
    /* ============ External Getters ============ */
    
    function owner(
        string memory _name,
        uint256 _strength,
        uint256 _experience
    ) external view returns (address) {
        bytes32 hash = _hash(_name, _strength, _experience);
        return hashaGotchiOwners[hash];
    }
    
    function gotchiCount() external view returns (uint256) {
        return gotchis[msg.sender].length;
    }
    
    /* ============ Internal ============ */
    
    // Have to be careful with strings. abi.encodePacked concatenates strings, so if two different 
    // string inputs that result in the same concatenated string, it will create a collision.
    function _hash(
        string memory _name, 
        uint256 _strength, 
        uint256 _experience
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            _name,
            _strength,
            _experience
        ));
    }
}
