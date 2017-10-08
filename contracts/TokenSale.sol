pragma solidity ^0.4.13;

import './SafeMath.sol';
import './Ownable.sol';
import './Token.sol';

/*****
    * @title The Crowd Sale Contract
    */
contract TokenSale is Ownable {
    using SafeMath for uint256;
    // Instance of the Real Token
    Token public token;
    // Received funds are transferred to the beneficiary
    address public beneficiary;
    // Number of Tokens/ETH in PreSale
    uint256 public tokenPerEthPreSale;
    // Number of Tokens/ETH in ICO
    uint256 public tokenPerEthICO;
    // Start Timestamp of Pre Sale
    uint256 public presaleStartTimestamp;
    // End Timestamp of Pre Sale
    uint256 public presaleEndTimestamp;
    // Start Timestamp for the ICO
    uint256 public icoStartTimestamp;
    // End Timestamp for the ICO
    uint256 public icoEndTimestamp;
    // Amount of tokens available for sale in Pre Sale Period
    uint256 public presaleTokenLimit;
    // Amount of tokens available for sale in ICO Period
    uint256 public icoTokenLimit;
    // Total Tokens Sold in Pre Sale Period
    uint256 public presaleTokenRaised;
    // Total Tokens Sold in ICO Period
    uint256 public icoTokenRaised;
    // Max Cap for Pre Sale
    uint256 public presaleMaxEthCap;
    // Min Cap for ICO
    uint256 public icoMinEthCap;
    // Max Cap for ICO
    uint256 public icoMaxEthCap;
    // Different number of Investors
    uint256 public investorCount;
    /*****
        * State machine
        *   - Unknown:      Default Initial State of the Contract
        *   - Preparing:    All contract initialization calls
        *   - PreSale:      We are into PreSale Period
        *   - ICO:          The real Sale of Tokens, after Pre Sale
        *   - Success:      Minimum funding goal reached
        *   - Failure:      Minimum funding goal not reached
        *   - Finalized:    The ICO has been concluded
        *   - Refunding:    Refunds are loaded on the contract for reclaim.
        */
    enum State{Unknown, Preparing, PreSale, ICO, Success, Failure, PresaleFinalized, ICOFinalized}
    State public crowdSaleState;
    /*****
        * @dev Modifier to check that amount transferred is not 0
        */
    modifier nonZero() {
        require(msg.value != 0);
        _;
    }
    /*****
        * @dev The constructor function to initialize the token related properties
        * @param _token             address     Specifies the address of the Token Contract
        * @param _presaleRate       uint256     Specifies the amount of tokens that can be bought per ETH during Pre Sale
        * @param _icoRate           uint256     Specifies the amount of tokens that can be bought per ETH during ICO
        * @param _presaleStartTime  uint256     Specifies the Start Date of the Pre Sale
        * @param _presaleDays       uint256     Specifies the duration of the Pre Sale
        * @param _icoStartTime      uint256     Specifies the Start Date for the ICO
        * @param _icoDays           uint256     Specifies the duration of the ICO
        * @param _maxPreSaleEthCap  uint256     Maximum amount of ETHs to raise in Pre Sale
        * @param _minICOEthCap      uint256     Minimum amount of ETHs to raise in ICO
        * @param _maxICOEthCap      uint256     Maximum amount of ETHs to raise in ICO
        */
    function TokenSale(
        address _token,
        uint256 _presaleRate,
        uint256 _icoRate,
        uint256 _presaleStartTime,
        uint256 _presaleDays,
        uint256 _icoStartTime,
        uint256 _icoDays,
        uint256 _maxPreSaleEthCap,
        uint256 _minICOEthCap,
        uint256 _maxICOEthCap){
            require(_token != address(0));
            require(_presaleRate != 0);
            require(_icoRate != 0);
            require(_presaleStartTime > now);
            require(_icoStartTime > _presaleStartTime);
            require(_minICOEthCap <= _maxICOEthCap);
            token = Token(_token);
            tokenPerEthPreSale = _presaleRate;
            tokenPerEthICO = _icoRate;
            presaleStartTimestamp = _presaleStartTime;
            presaleEndTimestamp = presaleEndTimestamp + _presaleDays * 1 days;
            require(_icoStartTime > presaleEndTimestamp);
            icoStartTimestamp = _icoStartTime;
            icoEndTimestamp = _icoStartTime + _icoDays * 1 days;
            presaleMaxEthCap = _maxPreSaleEthCap;
            icoMinEthCap = _minICOEthCap;
            icoMaxEthCap = _maxICOEthCap;
            presaleTokenLimit = _maxPreSaleEthCap.div(_presaleRate);
            icoTokenLimit = _maxICOEthCap.div(_icoRate);
            assert(token.totalSupply() >= presaleTokenLimit.add(icoTokenLimit));
            crowdSaleState = State.Preparing;
    }
    /*****
        * @dev Fallback Function to buy the tokens
        */
    function () nonZero payable {
        if(isPreSalePeriod()) {
            if(crowdSaleState == State.Preparing) {
                crowdSaleState = State.PreSale;
            }
            buyTokens(msg.sender, msg.value);
        } else if (isICOPeriod()) {
            if(crowdSaleState == State.PresaleFinalized) {
                crowdSaleState = State.ICO;
            }
            buyTokens(msg.sender, msg.value);
        } else {
            revert();
        }
    }
    /*****
        * @dev Internal function to execute the token transfer to the Recipient
        * @param _recipient     address     The address who will receives the tokens
        * @param _value         uint256     The amount invested by the recipient
        * @return success       bool        Returns true if executed successfully
        */
    function buyTokens(address _recipient, uint256 _value) internal returns (bool success) {
        uint256 boughtTokens = calculateTokens(_value);
        require(boughtTokens != 0);
        if(token.balanceOf(_recipient) == 0) {
            investorCount++;
        }
        if(isCrowdSaleStatePreSale()) {
            token.transferTokens(_recipient, boughtTokens, tokenPerEthPreSale);
            presaleTokenRaised = presaleTokenRaised.add(_value);
            return true;
        } else if (isCrowdSaleStateICO()) {
            token.transferTokens(_recipient, boughtTokens, tokenPerEthICO);
            icoTokenRaised = icoTokenRaised.add(_value);
            return true;
        }
    }
    /*****
        * @dev Calculates the number of tokens that can be bought for the amount of WEIs transferred
        * @param _amount    uint256     The amount of money invested by the investor
        * @return tokens    uint256     The number of tokens
        */
    function calculateTokens(uint256 _amount) returns (uint256 tokens){
        if(isCrowdSaleStatePreSale()) {
            tokens = _amount.mul(tokenPerEthPreSale);
        } else if (isCrowdSaleStateICO()) {
            tokens = _amount.mul(tokenPerEthICO);
        } else {
            tokens = 0;
        }
    }
    /*****
        * @dev Check the state of the Contract, if in Pre Sale
        * @return bool  Return true if the contract is in Pre Sale
        */
    function isCrowdSaleStatePreSale() constant returns (bool) {
        return crowdSaleState == State.PreSale;
    }
    /*****
        * @dev Check the state of the Contract, if in ICO
        * @return bool  Return true if the contract is in ICO
        */
    function isCrowdSaleStateICO() constant returns (bool) {
        return crowdSaleState == State.ICO;
    }
    /*****
        * @dev Check if the Pre Sale Period is still ON
        * @return bool  Return true if the contract is in Pre Sale Period
        */
    function isPreSalePeriod() constant returns (bool) {
        if(presaleTokenRaised > presaleMaxEthCap || now >= presaleEndTimestamp) {
            crowdSaleState = State.PresaleFinalized;
            return false;
        } else {
            return now > presaleStartTimestamp;
        }
    }
    /*****
        * @dev Check if the ICO is in the Sale period or not
        * @return bool  Return true if the contract is in ICO Period
        */
    function isICOPeriod() constant returns (bool) {
        if (icoTokenRaised > icoMaxEthCap || now >= icoEndTimestamp){
            crowdSaleState = State.ICOFinalized;
            return false;
        } else {
            return now > icoStartTimestamp;
        }
    }
    /*****
        * @dev Called by the owner of the contract to close the Sale
        */
    function endCrowdSale() onlyOwner {
        require(now >= icoEndTimestamp || icoTokenRaised >= icoMaxEthCap);
        if(icoTokenRaised >= icoMinEthCap){
            crowdSaleState = State.Success;
            beneficiary.transfer(icoTokenRaised);
            beneficiary.transfer(presaleTokenRaised);
        } else {
            crowdSaleState = State.Failure;
        }
    }
    /*****
        * @dev Allow investors to take their mmoney back after a failure in ICO
        * @param _recipient     address     The caller of the function who is looking for refund
        * @return               bool        Return true, if executed successfully
        */
    function getRefund(address _recipient) returns (bool){
        require(crowdSaleState == State.Failure);
        uint256 amount = token.balanceOf(_recipient);
        require(token.refundedAmount(_recipient));
        _recipient.transfer(amount);
        return true;
    }
    /*****
        * Fetch some statistics about the ICO
        */
    /*****
        * @dev Fetch the count of different Investors
        * @return   bool    Returns the total number of different investors
        */
    function getInvestorCount() constant returns (uint256) {
        return investorCount;
    }
    /*****
        * @dev Fetch the amount raised in Pre Sale
        * @return   uint256     Returns the amount of money raised in Pre Sale
        */
    function getPresaleRaisedAmount() constant returns (uint256) {
        return presaleTokenRaised;
    }
    /*****
        * @dev Fetch the amount raised in ICO
        * @return   uint256     Returns the amount of money raised in ICO
        */
    function getICORaisedAmount() constant returns (uint256) {
        return icoTokenRaised;
    }
}
