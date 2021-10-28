pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./KingdomBank.sol";

contract KingdomTitles is ERC721, KingdomBank {
    using Counters for Counters.Counter;
    
    address private _owner;

    uint16 constant public totalSupply = 10000;
    uint public attackCooldown = 60 seconds;
    string public baseUrl = "https://www.kingdomcrypto.com/titles/";

    struct KingdomTitle {
        uint attackPoints;
        uint defensePoints;
        uint readyTimeAttack;
    }

    KingdomTitle[totalSupply] public kingdomtitles;

    mapping (address => uint[]) public address2ids;

    // this one is used to remember which title belonged to the user if transferred temporarily to the contract
    mapping(uint => address) public borrowed_id2owner;

    constructor(KingdomSeedCoin kgdsc, KingdomAttackCoin kgdat, KingdomDefenseCoin kgddf) ERC721("Kingdom Titles", "KGD") KingdomBank(kgdsc, kgdat, kgddf) {
        _owner = _msgSender();
    }

    modifier onlyOwner {
        require(_owner == msg.sender, "fook off, you are not the owner of the contract");
        _;
    }

    modifier onlyAssignedAndOwner(uint256 titleId) {
        // titles can only be interacted with if they belong to the contract. this has to be done in order to transfer titles later on
        require(ownerOf(titleId) == address(this), "title has to belong to the contract to be interacted with. Please transfer it to the contract first - your address will of course be saved");
        require(borrowed_id2owner[titleId] == msg.sender, "you are not the owner of this title");
        _;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function currentPosition() public view returns (uint256) {
        return uint256(kingdomtitles.length);
    }

    function awardItem(address player) public onlyOwner returns (uint256) {
        require(kingdomtitles.length < totalSupply, "uhoh, no titles available anymore");     

        uint256 newItemId = kingdomtitles.length + 1;
        _mint(address(this), newItemId); // player

        // remember whcih player it usually belongs to
        borrowed_id2owner[newItemId] = player;

        // mark it down in address2ids
        address2ids[player].push(newItemId);

        // then add data to storage
        kingdomtitles[newItemId] = KingdomTitle(0,0,block.timestamp + attackCooldown);

        return newItemId;
    }

    function transferFrom(address from, address to, uint256 tokenId) 

    function withdraw(uint titleId) public onlyAssignedAndOwner {
        // onlyAssignedAndOwner checks if the title belongs to the contract and if the player is the owner of the title
        _transfer(address(this), msg.sender, titleId);
        uint pos = 6666;
        require(pos != 6666, "reverse item function... item not found in address2ids");
        delete address2ids[ownerOfItem][pos];
        address2ids[msg.sender].remove(titleId);
        delete borrowed_id2owner[titleId];
    }

    // function reverseItem(uint256 itemId) public onlyOwner returns (bool) {
    //     address ownerOfItem = ownerOf(itemId);
    //     _transfer(ownerOfItem, address(this), itemId);
    //     uint pos = 6666;
    //     for (uint i = 0; i < address2ids[ownerOfItem].length; i++) {
    //         if (address2ids[ownerOfItem][i] == itemId) {
    //             pos = i;
    //             break;
    //         }
    //     }
    //     require(pos != 6666, "reverse item function... item not found in address2ids");
    //     delete address2ids[ownerOfItem][pos];
    //     return true;
    // }

    function tokenMetadata(uint256 _tokenId) public view returns (string memory infoUrl) {
        return string(abi.encodePacked(baseUrl, uint2str(_tokenId)));
    }

    function balanceOf(address own) override external view returns (uint256 balance) {
        // return balanceOf(msg.sender);
        // not that simple, bc it can actually be assigned to the contract
        return uint256(address2ids[own].length);
    }

    function returnIdsOfAddress(address _own) external view returns (uint256[] memory ownedIds) {
        return address2ids[_own];
    }
}