pragma solidity ^0.8;

import "./KingdomTitles.sol";

contract KingdomGameMechanic is KingdomTitles {

    uint private nowStore;

    event Log(uint error);

    constructor (KingdomSeedCoin kgdsc, KingdomAttackCoin kgdat, KingdomDefenseCoin kgddf) KingdomTitles(kgdsc, kgdat, kgddf) {
        nowStore = block.timestamp;
    }

    event Attack(address attacker, address defender, 
                uint16 attacker_id, uint16 defender_id, 
                uint attackPointsBefore, uint defensePointsBefore,
                uint deadAttackers, uint deadDefenders,
                uint denominator, uint remainder, bool won);

    event Sacked(address attacker, address defender, 
                uint16 new_attacker_id);

    modifier hasTitle {
        require(balanceOf(msg.sender) > 0, "to use this function you need a title! go buy one!");
        _;
    }

    modifier contractNeedsTotalControl {
        require(isApprovedForAll(msg.sender, address(this)), "you need to call setApprovalForAll in order to play a game...");
        _;
    }

    function _random() private returns (uint8) {
        // random number between 0 and 99
        uint8 random = uint8( uint(keccak256(abi.encodePacked(block.difficulty, nowStore))) % 100);
        nowStore = uint8(nowStore + random);
        return random;
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
        require(0 < id && id <= currentPos, "id is not yet assigned");

        // remember binary tree
        if (id == 1) {
            bossid = 0;
        }
        else {
            if (id % 2 == 0) {
                // if even
                bossid = id / 2;
            }
            else {
                // if odd
                bossid = (id - 1) / 2;
            }
        }
        return bossid;
    }

    function getTitleStats(uint32 titleId) public view returns (uint attackPoints, uint defensePoints, bool ready4attack){
        require(titleId <= currentPosition(), "title id not yet assigned, go get one");
        attackPoints = kingdomtitles[titleId].attackPoints;
        defensePoints = kingdomtitles[titleId].defensePoints;
        ready4attack = kingdomtitles[titleId].readyTimeAttack >= block.timestamp;
        return (attackPoints, defensePoints, ready4attack);
    }

    function assignMilitaryToTitle(uint nrCoins, uint32 titleId, uint8 coinType) public {
        uint currentPos = currentPosition();
        require(0 < titleId && titleId <= currentPos, "title id is not yet assigned");
        // needs an approve first!

        // first checks
        // title needs to be owned by sender -> actually allow this for guilds etc
        // require(ownerOf(titleId) == msg.sender, "you can not assign Military P")
        // check if sender has that amount
        require(coinType == 0 || coinType == 1, "other coin types not supported yet, must be 0 or 1");
        if (coinType == 0) {
            // attack points
            require(kgdat.balanceOf(msg.sender) >= nrCoins, "you do not have that many attack coins");
            kgdat.transferFrom(msg.sender, address(this), nrCoins);
            kingdomtitles[titleId].attackPoints += nrCoins;
        }
        else if (coinType == 1) {
            // def coins
            require(kgddf.balanceOf(msg.sender) >= nrCoins, "you do not have that many defense coins");
            kgddf.transferFrom(msg.sender, address(this), nrCoins);
            kingdomtitles[titleId].defensePoints += nrCoins;
        }
    }

    function _attackResults(uint16 attackerId, uint16 defenderId, address attackerAddress, address defenderAddress, uint attackerPoints, uint defenderPoints, uint deadAttackers, uint deadDefenders, uint denominator, uint remainder, bool won) private {
        // we have to give the title of the looser to the attacker
        // if (won) {
        //     // idk how to solve it yet...
        //     emit Log(attackerAddress);
        //     transferFrom(defenderAddress, address(this), defenderId);
        //     emit Sacked(attackerAddress, defenderAddress, 
        //             defenderId);
        // }
        // next we have to let the people die accordingly
        emit Attack(attackerAddress, defenderAddress, 
                attackerId, defenderId, 
                attackerPoints, defenderPoints,
                deadAttackers, defenderPoints,
                denominator, remainder, won);
        // finally update the title struct
        kingdomtitles[attackerId].attackPoints -= deadAttackers;
        require(kingdomtitles[attackerId].attackPoints > 0, "uhoh, the attackpoints are zero...");
        kingdomtitles[defenderId].defensePoints -= deadDefenders; 
        require(kingdomtitles[defenderId].defensePoints > 0, "uhoh, the defensepoints are zero...");
    }

    function _divide(uint numerator, uint denominator) private pure returns (uint quotient, uint remainder) {
        quotient  = numerator / denominator;
        remainder = numerator - denominator * quotient;
        return (quotient, remainder);
    }

    function attackBoss(uint16 titleId) public hasTitle contractNeedsTotalControl {
        require(ownerOf(titleId) == msg.sender, "sorry, only the owner can attack his boss");

        uint16 bossid = getBoss(titleId);
        address bossid_address = ownerOf(bossid);
        // check if boss setApprovalForAll as well, required
        require(isApprovedForAll(bossid_address, address(this)), "your boss needs to setApprovedForAll to this contract, otherwise the mechanism does not work. He only earns money if that approval has been set though.");

        require(bossid_address != msg.sender, "boy, don't attack yourself plz");

        (uint attacker_Attackpoints, , bool ready4Attack ) = getTitleStats(titleId);
        require(ready4Attack, "your attack cooldown is not down yet. please try again after cooldown");

        ( , uint defender_Defensepoints, ) = getTitleStats(bossid);

        uint tmp_game_defender_Defensepoints = (defender_Defensepoints * 15) / 10; // counts 1.5

        // make it so that more than double attack points is a sure win
        uint8 randy = _random();
        (uint quotient, uint remainder) = _divide(attacker_Attackpoints, tmp_game_defender_Defensepoints); // double would be 20
        uint deadAttackers = 0;
        uint deadDefenders = 0;
        bool won = false;
        if (quotient > 3) {
            // no discussion needed
            deadDefenders = defender_Defensepoints;
            deadAttackers = 0;
            won = true;
        }
        else if (quotient > 2) {
            // more than double the attackers
            deadDefenders = defender_Defensepoints;
            won = true;
            // some attackers dead except rare case
            deadAttackers = uint(attacker_Attackpoints / 10);
            if (randy > 90) {
                // in a rare case not all defenders die, some can flee
                deadDefenders = uint(defender_Defensepoints / 2);
            }
        }
        else if (quotient > 1 && remainder > 5) {
            won = true;
            deadDefenders = uint(defender_Defensepoints / 2);
            deadAttackers = uint(attacker_Attackpoints / 2);
        }
        else {
            // tmp
            won = false;
            deadDefenders = randy;
            deadAttackers = randy;
        }

        _attackResults(titleId, bossid, msg.sender, bossid_address, attacker_Attackpoints, defender_Defensepoints, deadAttackers, deadDefenders, quotient, remainder, won);
    }
}