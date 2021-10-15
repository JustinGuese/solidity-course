pragma solidity ^0.8;

contract Blackjack {
    address owner;
    mapping(address => uint8[]) private gameLocation;
    mapping(address => uint) private betStore;
    
    // dealer card number 2, player card 1, player card 2
    event GameStart(uint8 d2, uint8 p1, uint8 p2);
    
    modifier onlyOneGamePerUser() {
        require(gameLocation[msg.sender].length == 0, "only one game allowed per player");
        _;
    }
    
    function _random() private view returns (uint8) {
        // should return number between 2 and 14 (blackjack)
        // 2 - 10, numbers as usual
        // jack, queen, king = 10
        // ace -> one or 11 
        return uint8( uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp))) % 12 + 2);
    }
    
    function getRandomNumber() public view returns (uint8) {
        return _random();
    }
    
    function getNrGames() public view returns(uint8) {
        return uint8(gameLocation[msg.sender].length);
    }
    
    function startGame() payable public onlyOneGamePerUser {
        uint bet = msg.value;
        // draw two cards for dealer
        // first card not visible for player
        gameLocation[msg.sender].push(_random());
        // second card visible to player
        gameLocation[msg.sender].push(_random());
        // 0 marks the split 
        gameLocation[msg.sender].push(0);
        // draw two player cards
        gameLocation[msg.sender].push(_random());
        gameLocation[msg.sender].push(_random());
        // save bet amount in betStore
        betStore[msg.sender] = bet;
        
        emit GameStart(gameLocation[msg.sender][1], gameLocation[msg.sender][3], gameLocation[msg.sender][4]);
    }
    
}