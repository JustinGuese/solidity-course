pragma solidity ^0.8;

contract Blackjack {
    address owner;
    mapping(address => uint8[]) private gameLocation;
    mapping(address => uint) private betStore;
    uint8 private nowStore = uint8(block.timestamp);
    
    // dealer card number 2, player card 1, player card 2
    event GameStart(uint8 d2, uint8 p1, uint8 p2, uint8 playerSum);
    event DrawCard(uint8 d2, uint8[] playerCards, uint8 playerSum);
    event GameLost(uint8[] dealerCards, uint8[] playerCards, uint8 dealerSum, uint8 playerSum, string winDescription);
    event GameWon(uint8[] dealerCards, uint8[] playerCards, uint8 dealerSum, uint8 playerSum, string winDescription);
    event Log(string message);
    
    constructor() payable {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "can only be called by the owner");
        _;
    }
    
    modifier hasNoRunningGame() {
        require(gameLocation[msg.sender].length == 0, "only one game allowed per player");
        _;
    }
    
    modifier hasRunningGame() {
        require(gameLocation[msg.sender].length > 1, "you need to have a game running to run this. please run startGame");
        _;
    }
    
    function _random() private returns (uint8) {
        // should return number between 2 and 14 (blackjack)
        // 2 - 10, numbers as usual
        // jack, queen, king = 10
        // ace -> one or 11 
        uint8 random = uint8( uint(keccak256(abi.encodePacked(block.difficulty, nowStore))) % 12 + 2);
        nowStore = uint8(nowStore + random);
        return random;
    }
    
    function getRandomNumber() public returns (uint8) {
        return _random();
    }
    
    function getNrGames() public view returns(uint8) {
        return uint8(gameLocation[msg.sender].length);
    }
    
    function _getCardValue(uint8 nr) private pure returns(uint8) {
        if (2 <= nr && nr <= 10) {
            return nr;
        }
        else if (11 <= nr && nr <= 13) {
            return 10;
        }
        else if (nr == 14) {
            return 11; // ace! we deal with the one case in the aceCheckAddition
        }
        else return 0; // or raise error
    }
    
    function _aceCheckSum(uint8[] memory cards) private pure returns(uint8) {
        uint8 aceCount = 0;
        uint8 cardSum = 0;
        for (uint8 i = 0; i < cards.length; i++) {
            uint8 newCard = cards[i];
            if (newCard == 11) {
                // if it is an ace
                aceCount++; // deal with it later
            }
            else {
                cardSum += newCard;
            }
        }
        // now create the ideal combination for every ace there is
        for (uint8 i = 0; i < aceCount; i++) {
            // logic behind this: if we have 3 aces, we have to take 21 - 3 = 18 as max
            if ((cardSum + 11) > (21 - aceCount)) {
                // count it as 1
                cardSum += 1;
            }
            else {
                cardSum += 11;
            }
        }
        return cardSum;
    }
    
    function getCurrentCards() public view hasRunningGame returns (uint8, uint8, uint8[] memory) {
        // basically the user centric version of getCurrentCards
        ( , uint8 playerCardSum, uint8[] memory dealerCards, uint8[] memory playerCards) = _checkValues();
        uint8 secondDealerCard = dealerCards[1];
        return (secondDealerCard, playerCardSum, playerCards);
    }
    
    function _checkValues() private view hasRunningGame returns(uint8, uint8, uint8[] memory, uint8[] memory) {
        // first values of player
        uint8[] memory playerCards = new uint8[](gameLocation[msg.sender].length); // max version, todo improve. cant use push unfortunately
        uint8[] memory dealerCards = new uint8[](gameLocation[msg.sender].length);
        bool playerSwitch = false;
        for (uint8 i = 0; i < gameLocation[msg.sender].length; i++ ) {
            // 0 marks the seperation
            if (gameLocation[msg.sender][i] == 0) {
                // marks the switch
                playerSwitch = true;
            }
            else {
                if (!playerSwitch) {
                    dealerCards[i] = _getCardValue(gameLocation[msg.sender][i]);
                }
                else {
                    playerCards[i] = _getCardValue(gameLocation[msg.sender][i]);
                }
            }
        }
        // next create sum taking account of the ace
        uint8 dealerCardSum = _aceCheckSum(dealerCards);
        uint8 playerCardSum = _aceCheckSum(playerCards);
        return (dealerCardSum, playerCardSum, dealerCards, playerCards);
    }
    
    function getBankBalance() public view onlyOwner returns(uint) {
        return uint(address(this).balance);
    }
    
    function _checkWinOrLooseCondition(uint8 playerCardSum) private view hasRunningGame returns(bool) {
        // won or lost if player either has exactly 21, or if he is above
        // true if ending condition, false if game should go on
        if (playerCardSum == 21) {
            return true;
        }
        else if (playerCardSum > 21) {
            return true;
        }
        else {
            return false;
        }
    }
    
    function drawCard() public hasRunningGame {
        gameLocation[msg.sender].push(_random());
        ( , uint8 playerCardSum, , uint8[] memory playerCards) = _checkValues();
        emit DrawCard(gameLocation[msg.sender][1], playerCards, playerCardSum);
        if (_checkWinOrLooseCondition(playerCardSum)) {
            // if true we need to handle endgame logic
            emit Log("forcing endgame");
            endGame();
        }
    }
    
    function _resetGame() private hasRunningGame {
        delete gameLocation[msg.sender];
        delete betStore[msg.sender];
    }
    
    function _handleWin(uint8 multiplier) private hasRunningGame {
        // first get betStore
        emit Log("trying to payout ...");
        uint payout = betStore[msg.sender] * multiplier / 10;
        require(address(this).balance > payout, "ohoh, bank has not enough ca$HHH");
        payable(msg.sender).transfer(payout);
    }
    
    function _handleLoss() private hasRunningGame {
        // just keep the money
    }
    
    function endGame() public hasRunningGame {
        // if there has been an easy end, above 21 or exactly 21 handled in _checkWinOrLooseCondition, then
        // it would already have been triggered, meaning we only need endGame if we do not have an easy end condition
        (uint8 dealerCardSum, uint8 playerCardSum, uint8[] memory dealerCards, uint8[] memory playerCards) = _checkValues();
        
        
        // just for safety check again
        if (! _checkWinOrLooseCondition(playerCardSum)) {
            // dealer needs to draw until he has at least 17
            // attention, we are not working on gameLocation, that is why we need to adapt manually !!
            // do not call the checkValues from here on!!!
            while(dealerCardSum <= 17) {
                uint8 dealerCard = _random();
                // find the next spot to add it
                uint8 tmpCnt = 0;
                while (dealerCards[tmpCnt] != 0) {
                    tmpCnt++;
                }
                // emit Log("found tmpcnt");
                // add card at empty spot
                dealerCards[tmpCnt] = dealerCard;
                // now get real card value
                dealerCard = _getCardValue(dealerCard);
                if (dealerCard == 11) {
                    if ((dealerCardSum + dealerCard) > 21) {
                        dealerCardSum += 1;
                    }
                    else {
                        dealerCardSum += 11;
                    }
                }
                else {
                    dealerCardSum += dealerCard;
                }
            }
            // now dealer should at least have 17 as card sum
        }    
        else {
            // either player is above 21 or has exactly 21
            require(playerCardSum == 21 || playerCardSum > 21);
            if (playerCardSum == 21) {
                // instant win 
                emit GameWon(dealerCards, playerCards, dealerCardSum, playerCardSum, "player has exactly 21");
                // handle win transaction
                // if player hits blackjack the payout is 3:2, or * 2.5
                _handleWin(25);
                _resetGame();
                return;
            }
            else if (playerCardSum > 21) {
                emit GameLost(dealerCards, playerCards, dealerCardSum, playerCardSum, "player is above 21");
                // handle lost transaction
                _resetGame();
                return;
            }
        }
        
        // if no easy win or loose condition check the amounts
        require(playerCardSum < 21, "playerCardSum is above or equal 21, shouldn't happen!");
        require(dealerCardSum >= 17, "dealer should have at least 17. shouldnt happen!");
        
        
        
        // first case, dealer is above 21 or exactly 21, easy win for dealer
        if (dealerCardSum == 21) {
            emit GameLost(dealerCards, playerCards, dealerCardSum, playerCardSum, "dealer has 21. player less than 21");
            // handle lost transaction
            _resetGame();
            return;
        }
        else if (dealerCardSum > 21) {
            emit GameWon(dealerCards, playerCards, dealerCardSum, playerCardSum, "dealer is above 21, player below");
            // handle win transaction
            _handleWin(20);
            _resetGame();
            return;
        }
        
        emit Log("the second case ");
        if (playerCardSum > dealerCardSum) {
            emit GameWon(dealerCards, playerCards, dealerCardSum, playerCardSum, "player has higher sum than dealer");
            // handle win transaction
            _handleWin(20);
        }
        else if (dealerCardSum > playerCardSum) {
            emit GameLost(dealerCards, playerCards, dealerCardSum, playerCardSum, "dealer has higher sum than player");
            // handle lost transaction
        }
    emit Log("resetting game now...");
    _resetGame();
    }
    
    function startGame() payable public hasNoRunningGame {
        uint bet = msg.value;
        require(bet > 0, "you have to bet something...");
        
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
        
        // get current values
        ( , uint8 playerCardSum, , ) = _checkValues();
        emit GameStart(gameLocation[msg.sender][1], gameLocation[msg.sender][3], gameLocation[msg.sender][4], playerCardSum);
        if (_checkWinOrLooseCondition(playerCardSum)) {
            // if true we need to handle endgame logic
            emit Log("forcing endgame");
            endGame();
        }
    }
    
}