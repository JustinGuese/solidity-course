pragma solidity ^0.8;

import "./KingdomSeedCoin.sol";
import "./KingdomAttackCoin.sol";
import "./KingdomDefenseCoin.sol";

contract KingdomBank {
    address public owner;
    string public name = "Kingdom Bank";
    uint8 public exchangeRate = 100;
    uint8 public exchangeRate_Attackpoints = 10;
    uint8 public exchangeRate_Defensepoints = 8;
    uint8 public exchangeRate_Burnpct = 10;
    uint public stakingPeriod = 60 seconds;
    
    KingdomSeedCoin public kgdsc;
    KingdomAttackCoin public kgdat;
    KingdomDefenseCoin public kgddf;

    event HarvestAttackPoints(address indexed _to, uint _amount);
    event HarvestDefensePoints(address indexed _to, uint _amount);
    event HarvestRemainingSeedCoins(address indexed _to, uint _amount);
    
    struct Staking {
        uint seedCoinAmount;
        uint8 targetCoinType; // 0 = attackCoin, 1 = defenseCoin
        uint readyTime;
    }
    
    mapping (address => Staking[]) private _Staking;

    constructor(KingdomSeedCoin _kgdsc, KingdomAttackCoin _kgdat, KingdomDefenseCoin _kgddf) {
        kgdsc = _kgdsc;
        kgdat = _kgdat;
        kgddf = _kgddf;
        // after that the coins need to be transferred to KingdomBank
        owner = msg.sender;
    }

    modifier contractHasSeedcoins {
        require (kgdsc.balanceOf(msg.sender) > 0);
        _;
    }

    modifier contractHasAttackcoins {
        require (kgdat.balanceOf(msg.sender) > 0);
        _;
    }

    modifier contractHasDefensecoins {
        require (kgddf.balanceOf(msg.sender) > 0);
        _;
    }
    
    // you can only buy the seed coins 
    function buyForETH() public payable contractHasSeedcoins {
        require(msg.value > 0, "you have to send some ETH to get KingdomSeedcoin");
        require(kgdsc.balanceOf(address(this)) > 0, "uhoh, sry i can't send any more KingdomSeedcoin");
        
        uint rewardTokens = msg.value * exchangeRate;
        kgdsc.transfer(msg.sender, rewardTokens);
    }
    
    function plantForAttackpoints(uint nrSeedCoins) public contractHasAttackcoins {
        uint kgdsc_balance = kgdsc.balanceOf(msg.sender);
        require(kgdsc_balance >= nrSeedCoins && nrSeedCoins > 0, "you don't have enough seedcoins! buy or trade some");
        
        // enter staking
        // first transact the kgdsc
        kgdsc.transferFrom(msg.sender, address(this), nrSeedCoins);
        // kgdsc.transfer(address(this), nrSeedCoins);
        // then store in array
        _Staking[msg.sender].push(Staking(
            nrSeedCoins,
            0,
            block.timestamp + stakingPeriod
            ));
    }
    
    function getCurrentStakes() public view returns(uint[2] memory balances){
        uint attackPoints = 0;
        uint defensePoints = 0;
        for (uint i = 0; i < _Staking[msg.sender].length; i++) {
            Staking memory stakeobj = _Staking[msg.sender][i];
            if (stakeobj.targetCoinType == 0) {
                attackPoints += stakeobj.seedCoinAmount;
            }
            else if (stakeobj.targetCoinType == 1) {
                defensePoints += stakeobj.seedCoinAmount;
            }
        }
        uint[2] memory res = [attackPoints, defensePoints];
        return res;
    }

    function _burnReturnSeedcoins(uint nrSeedCoins) private {
        uint remainingSeedcoins = nrSeedCoins * exchangeRate_Burnpct / 100;
        kgdsc.transfer(msg.sender, remainingSeedcoins);
        emit HarvestRemainingSeedCoins(msg.sender, remainingSeedcoins);
    }

    function harvestAll() public {
        for (uint i = 0; i < _Staking[msg.sender].length; i++) {
            Staking memory stakeobj = _Staking[msg.sender][i];
            if (stakeobj.readyTime < block.timestamp) {
                // ready for harvest
                if (stakeobj.targetCoinType == 0) {
                    uint attackPoints = stakeobj.seedCoinAmount / exchangeRate_Attackpoints;
                    _burnReturnSeedcoins(stakeobj.seedCoinAmount);
                    kgdat.transfer(msg.sender, attackPoints);
                    emit HarvestAttackPoints(msg.sender, attackPoints);
                }
                else if (stakeobj.targetCoinType == 1) {
                    uint defensePoints = stakeobj.seedCoinAmount / exchangeRate_Attackpoints;
                    _burnReturnSeedcoins(stakeobj.seedCoinAmount);
                    kgddf.transfer(msg.sender, defensePoints);
                    emit HarvestDefensePoints(msg.sender, defensePoints);
                }
                // finally remove from array
                delete _Staking[msg.sender][i];
            }
        }
    } 
}