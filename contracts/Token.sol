pragma solidity ^0.4.13;

import './SafeMath.sol';
import './StandardToken.sol';

/// @title Generic Token Contract
contract Token is StandardToken {
    using SafeMath for uint256;

    string public tokenName; // Defines the name of the token.
    string public tokenSymbol; // Defines the symbol of the token.
    uint256 public decimals; // Number of decimal places for the token.
    uint256 public constant RATE_PER_ETH = 1000; // Number of tokens to be sold per Ether.

    /*****
        * @dev Sets the variables related to the Token
        * @param _name              string      The name of the Token
        * @param _symbol            string      Defines the Token Symbol
        * @param _initialSupply     uint256     The total number of the tokens available
        * @param _decimals          uint256     Defines the number of decimals places of the token
        */
    function Token(string _name, string _symbol, uint256 _initialSupply, uint256 _decimals){
        require(_initialSupply > 0);
        tokenName = _name;
        tokenSymbol = _symbol;
        decimals = _decimals;
        totalTokenSupply = _initialSupply * 10 ** decimals;
    }


    /*****
        * @dev Used to remove the balance, when asking for refund
        * @param _recipient address The beneficiary of the refund
        * @return           bool    Returns true, if successful
        */
    function refundedAmount(address _recipient) returns (bool) {
        require(balances[_recipient] != 0);
        balances[_recipient] = 0;
        return true;
    }
}
