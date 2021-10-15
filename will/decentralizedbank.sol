pragma solidity ^0.8;

contract Bank {
    uint amountHeld;
    uint commissionStore;
    uint constant commission = 1; // 1 pct commission
    address owner;
    address payable[] customerWallets;
    mapping(address => uint) bankAccounts;
    
    constructor() {
        owner = msg.sender;
        amountHeld = 0;
        commissionStore = 0;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "fook off boy");
        _;
    }
    
    modifier hasAccount {
        uint storedAmount = bankAccounts[msg.sender];
        require(storedAmount > 0, "you don't have any money with us sir, please fuck off");
        _;
    }
    
    function depositMoney() payable public {
        uint amount = msg.value;
        require(amount > 0, "fuck off poor fuck");
        uint comm = amount * commission / 100;
        amount -= comm;
        bankAccounts[msg.sender] = amount;
        commissionStore += comm;
        customerWallets.push(payable(msg.sender));
    }
    
    function getBankBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    function getBankWin() public view returns (uint) {
        return commissionStore;
    }
    
    function withdrawMoney() public hasAccount {
        uint storedAmount = bankAccounts[msg.sender];
        uint comm = storedAmount * commission / 100;
        storedAmount -= comm;
        commissionStore += comm;
        payable(msg.sender).transfer(storedAmount);
        bankAccounts[msg.sender] = 0;
    }
    
    function getMyBalance() public view hasAccount returns (uint) {
        uint storedAmount = bankAccounts[msg.sender];
        return storedAmount;
    }
}