pragma solidity ^0.8;

contract Bank {
    uint constant commission = 1; // 1 pct commission
    address owner;
    address payable[] entrantsWallets;
    mapping(address => uint) entrantAccounts;
    uint lastLottery;
    
    event NotReadyYet(uint timeRemaining);
    event WinnerAnnounced(uint amount, address winner);
    
    constructor() {
        owner = msg.sender;
        lastLottery = block.timestamp;
    }
    
    modifier onlyEntrants() {
        uint entrantAmount = entrantAccounts[msg.sender];
        require(entrantAmount > 0, "you have not participated in this lottery, please fuck off");
        _;
    }
    
    modifier registrationOpen() {
        require((block.timestamp - lastLottery) > 1);
        _;
    }
    
    function _getInvested() private view returns(uint256[3] memory) {
        uint biggestInvestment = 0;
        uint allInvestments = 0;
        uint posBiggestInvestor = 0;
        
        for (uint i = 0; i < entrantsWallets.length; i++) {
            address addy = entrantsWallets[i];
            uint amount = entrantAccounts[addy];
            allInvestments += amount;
            if (amount > biggestInvestment) {
                biggestInvestment = amount;
                posBiggestInvestor = i;
            }
        }
        uint256[3] memory result = [allInvestments, biggestInvestment, posBiggestInvestor];
        return result;
    }
    
    function _reset() private {
        for (uint i = 0; i < entrantsWallets.length; i++) {
            address addy = entrantsWallets[i];
            entrantAccounts[addy] = 0;
        }
        lastLottery = block.timestamp;
    }
    
    function getWinner() public {
        uint diffSecs = block.timestamp - lastLottery;
        if (diffSecs < 30) {
            // still waiting for lottery to finish
            emit NotReadyYet(30 - diffSecs);
        }
        else {
            // lottery is over
            uint256[3] memory res = _getInvested();
            uint allInvestments = res[0];
            uint biggestInvestment = res[1];
            uint posBiggestInvestor = res[2];
            
            address payable winnerAddress = entrantsWallets[posBiggestInvestor];
            winnerAddress.transfer(allInvestments);
            emit WinnerAnnounced(allInvestments, winnerAddress);
            
            // reset
            _reset();
        }
        
        
    }
    
    function getBankBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function participateLottery() payable public registrationOpen {
        uint amount = msg.value;
        require(amount > 0, "you have to transact money u poor fuck");
        uint comm = amount * (commission / 100);
        amount -= comm;
        entrantAccounts[msg.sender] = amount;
        entrantsWallets.push(payable(msg.sender));
    }
    
    
    
}