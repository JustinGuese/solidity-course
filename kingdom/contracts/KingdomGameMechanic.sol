pragma solidity ^0.8;

import "./KingdomTitles.sol";

contract KingdomGameMechanic is KingdomTitles {
    uint public attackCooldown = 60 seconds;

    constructor (KingdomSeedCoin kgdsc, KingdomAttackCoin kgdat, KingdomDefenseCoin kgddf) KingdomTitles(kgdsc, kgdat, kgddf) {

    }

    event Attack(address attacker, address defender, 
                uint16 attacker_id, uint16 defender_id, 
                uint32 attackPoints, uint32 defensePoints,
                bool won);

    event Sacked(address attacker, address defender, 
                uint16 new_attacker_id, uint16 new_looser_id);

    struct KingdomTitle {
        uint32 attackPoints;
        uint32 defensePoints;
        uint readyTimeAttack;
    }

    function _getLeftChild(uint16 id) internal pure returns (uint16 left) {
        return id * 2;
    }

    function _getRightChild(uint16 id) internal pure returns (uint16 right) {
        return _getLeftChild(id) + 1;
    }

    function getServants(uint16 id) public view returns (uint16 left, uint16 right) {
        uint currentPos = currentPosition();
        require(id <= currentPos, "id is not yet assigned");

        // binary tree
        left = _getLeftChild(id);
        right = _getRightChild(id);

        // check if they even exist yet
        
        if (left > currentPos) {
            left = 0;
        }
        if (right > currentPos) {
            right = 0;
        }
        return (left, right);
    }

    function getBoss(uint16 id) public view returns (uint16 bossid) {
        uint currentPos = currentPosition();
        require(id <= currentPos, "id is not yet assigned");

        // remember binary tree
        if (id % 2 == 0) {
            // if even
            bossid = id / 2;
        }
        else {
            // if odd
            bossid = (id - 1) / 2;
        }
        return bossid;
    }


}