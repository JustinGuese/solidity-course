pragma solidity ^0.8;

import "./KingdomTitles.sol";

contract KingdomGameMechanic is KingdomTitles {

    uint private nowStore;

    event Log(address error);

    constructor (KingdomSeedCoin kgdsc, KingdomAttackCoin kgdat, KingdomDefenseCoin kgddf) KingdomTitles(kgdsc, kgdat, kgddf) {
        nowStore = block.timestamp;
    }

    event Attack(address attacker, address defender, 
                uint16 attacker_id, uint16 defender_id, 
                uint attackPointsBefore, uint defensePointsBefore,
                uint deadAttackers, uint deadDefenders,
                bool won);

    event Sacked(address attacker, address defender, 
                uint16 new_attacker_id);

    modifier hasTitle {
        require(balanceOf(msg.sender) > 0, "to use this function you need a title! go buy one!");
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

    function _attackResults(uint16 attackerId, uint16 defenderId, address attackerAddress, address defenderAddress, uint attackerPoints, uint defenderPoints, bool won) private {
        // we have to give the title of the looser to the attacker
        if (won) {
            emit Log(attackerAddress);
            transferFrom(defenderAddress, attackerAddress, defenderId);
            emit Sacked(attackerAddress, defenderAddress, 
                    defenderId);
        }
        // next we have to let the people die accordingly
        uint ratio = attackerPoints / defenderPoints * 10;
        uint8 randyDie = _random();

        // set default die values
        uint dieCountDefenders = defenderPoints;
        uint dieCountAttackers = defenderPoints;

        if (ratio > 20) {
            // more than double the units
            // all dead of defenders, some dead of attackers
            dieCountDefenders = defenderPoints;
            dieCountAttackers = defenderPoints / 10;
            kgddf.transferFrom(defenderAddress, address(this), dieCountDefenders);
            // calculate how many died of attackers
            if (randyDie > 80 && ratio < 30) {
                // let 10 pct of defenderpoints die
                kgdat.transferFrom(attackerAddress, address(this), dieCountAttackers);
            }
            else {
                //no dead
            }
        }
        else {
            // calculate the difference 
            dieCountAttackers = defenderPoints * (randyDie / 100) * 2;
            if (dieCountAttackers > attackerPoints) {
                dieCountAttackers = attackerPoints;
            }
            dieCountDefenders = defenderPoints - dieCountAttackers;
            if (dieCountDefenders < 0) {
                dieCountDefenders = defenderPoints;
            }
            kgdat.transferFrom(attackerAddress, address(this), dieCountAttackers);
            kgddf.transferFrom(defenderAddress, address(this), dieCountDefenders);
        }
        emit Attack(attackerAddress, defenderAddress, 
                attackerId, defenderId, 
                attackerPoints, defenderPoints,
                dieCountAttackers, dieCountDefenders,
                won);
        // finally update the title struct
        kingdomtitles[attackerId].attackPoints -= dieCountAttackers;
        kingdomtitles[defenderId].defensePoints -= dieCountDefenders; 
    }

    function attackBoss(uint16 titleId) public hasTitle {
        require(ownerOf(titleId) == msg.sender, "sorry, only the owner can attack his boss");
        uint16 bossid = getBoss(titleId);
        address bossid_address = ownerOf(bossid);

        require(bossid_address != msg.sender, "boy, don't attack yourself plz");

        (uint attacker_Attackpoints, , bool ready4Attack ) = getTitleStats(titleId);
        require(ready4Attack, "your attack cooldown is not down yet. please try again after cooldown");

        ( , uint defender_Defensepoints, ) = getTitleStats(bossid);

        uint tmp_game_defender_Defensepoints = defender_Defensepoints * 15 / 10; // counts 1.5

        // make it so that more than double attack points is a sure win
        uint8 randy = _random();
        uint ratio = attacker_Attackpoints / tmp_game_defender_Defensepoints * 10; // double would be 20
        if (ratio > 20) {
            if (randy == 99) {
                // really tiny chance that an attack is lost
                _attackResults(titleId, bossid, msg.sender, bossid_address, attacker_Attackpoints, tmp_game_defender_Defensepoints, false);
            }
            else {
                // win attack
                _attackResults(titleId, bossid, msg.sender, bossid_address, attacker_Attackpoints, tmp_game_defender_Defensepoints, true);
            }
        }
        else if (ratio >= 10) {
            // if it's one against one
            uint bonus = ratio - 10;
            if (randy + bonus * 5 > 60) {
                // win
                _attackResults(titleId, bossid, msg.sender, bossid_address, attacker_Attackpoints, tmp_game_defender_Defensepoints, true);
            }
            else {
                // lost
                _attackResults(titleId, bossid, msg.sender, bossid_address, attacker_Attackpoints, tmp_game_defender_Defensepoints, false);
            }
        }
        else if (ratio >= 8) {
            // slightly attackers than defenders
            if (randy > 90) {
                // win
                _attackResults(titleId, bossid, msg.sender, bossid_address, attacker_Attackpoints, tmp_game_defender_Defensepoints, true);
            }
            else {
                // lost
                _attackResults(titleId, bossid, msg.sender, bossid_address, attacker_Attackpoints, tmp_game_defender_Defensepoints, false);
            }
        }
        else {
            // lost
            _attackResults(titleId, bossid, msg.sender, bossid_address, attacker_Attackpoints, tmp_game_defender_Defensepoints, false);
        }

    }


}