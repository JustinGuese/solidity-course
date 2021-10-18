pragma solidity ^0.8;

import "./REW.sol";
import "./Tether.sol";

contract DecentralBank {
    address public owner;
    string public name = "Justins Bank";
    
    Tether public tether;
    REW public rwd;

    constructor(REW _rew, Tether _tether) {
        rwd = _rew;
        tether = _tether;
    }
}