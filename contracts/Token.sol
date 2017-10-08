pragma solidity ^0.4.13;

import './Ownable.sol';
import './SafeMath.sol';
import './BasicToken.sol';

/// @title Generic Token Contract
contract Token is BasicToken {
    using SafeMath for uint256;

    string public tokenName; // Defines the name of the token.
    string public tokenSymbol; // Defines the symbol of the token.
    uint256 public decimals; // Number of decimal places for the token.

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
        totalSupply = _initialSupply ** decimals;
    }
    /*****
        * @dev Transfer the amount of money invested by the investor to his balance
        * Also, keeps track of at what rate did they buy the token, keeps track of
        * different rates of tokens at PreSale and ICO
        * @param _recipient     address     The address of the investor
        * @param _value         uint256     The number of the tokens bought
        * @param _ratePerETH    uint256     The rate at which it was bought, different for Pre Sale/ICO
        * @return               bool        Returns true, if all goes as expected
        */
    function transferTokens(address _recipient, uint256 _value, uint256 _ratePerETH) returns (bool) {
        uint256 finalAmount = _value.mul(_ratePerETH);
        return transfer(_recipient, finalAmount);
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
