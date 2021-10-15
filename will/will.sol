pragma solidity ^0.8;

contract Will {
    address owner;
    uint fortune;
    bool deceased;
    address payable[] familyWallets;
    mapping(address => uint) inheritance;
    
    
    constructor() payable public {
        owner = msg.sender;
        fortune = msg.value;
        deceased = false;
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "fook off boy");
        _;
    }
    
    modifier onlyWhenDead {
        require(deceased == true, "boyz not dead yet fook off");
        _;
    }
    
    function setInheritanceForEachAddress(address payable wallet, uint amount) public {
        inheritance[wallet] = amount;
        familyWallets.push(wallet);
    }
}