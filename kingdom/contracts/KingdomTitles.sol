pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./KingdomBank.sol";

contract KingdomTitles is ERC721, KingdomBank {
    using Counters for Counters.Counter;
    
    address private _owner;
    
    Counters.Counter private _tokenIds;
    uint16 public totalSupply = 10000;
    string public baseUrl = "https://www.kingdomcrypto.com/titles/";

    constructor(KingdomSeedCoin kgdsc, KingdomAttackCoin kgdat, KingdomDefenseCoin kgddf) ERC721("Kingdom Titles", "KGD") KingdomBank(kgdsc, kgdat, kgddf) {
        _owner = _msgSender();
    }

    modifier onlyOwner {
        require(_owner == msg.sender, "fook off");
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

    function awardItem(address player) public onlyOwner returns (uint256) {
        require(_tokenIds.current() < totalSupply, "uhoh, no titles available anymore");

        _tokenIds.increment();      

        uint256 newItemId = _tokenIds.current();
        _mint(player, newItemId);

        return newItemId;
    }

    function tokenMetadata(uint256 _tokenId) public view returns (string memory infoUrl) {
        return string(abi.encodePacked(baseUrl, uint2str(_tokenId)));
    }
}