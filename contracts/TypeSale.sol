pragma solidity ^0.4.23;

// File: contracts/OpenZeppelin/ERC20Basic.sol

/**
 * @title ERC20
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: contracts/OpenZeppelin/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
*/

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether.
 */

contract Crowdsale {
  using SafeMath for uint256;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // Address of the contract owner
  address public owner;

  // The rate of tokens per ether. Only applied for the first tier, the first
  // 150 million tokens sold
  uint256 public rate;

  // The rate of tokens per ether. Only applied for the second round, at between
  // 150 million tokens sold and 210 million tokens sold
  uint256 public rateRound2;

  // The rate of tokens per ether. Only applied for the third round, at between
  // 210 million tokens sold and 255 million tokens sold
  uint256 public rateRound3;

  // The rate of tokens per ether. Only applied for the fourth round, at between
  // 255 million tokens sold and 285 million tokens sold
  uint256 public rateRound4;

  // The rate of tokens per ether. Only applied for the fifth round, at between
  // 285 million tokens sold and 300 million tokens sold
  uint256 public rateRound5;

  // The rate of tokens per ether. Only applied for the fifth round, at between
  // 300 million tokens sold and 1 billion tokens sold
  uint256 public rateRound6;

  // Amount of wei raised
  uint256 public weiRaised;

  // Amount of sold tokens
  uint256 public soldTokens;

  // Amount of unsold tokens to burn
  uint256 public unSoldTokens;

  // ICO state paused or not
  bool public paused = false;

  // Minimal amount to exchange in ETH
  uint minPurchase = 10 szabo;

  // Keeping track of current round
  uint currentRound = 1;

  // Amount of tokens for current round (default value rond11 150,000,000 TYPE)
  uint256 public constant currentRoundLimit = 150000000E4;

  // We can only sell maximum total amount- 1,000,000,000 tokens during the ICO
  uint256 public constant maxTokensRaised = 1000000000E4;

  // uint256 public constant round2Cap = 150000000E4;
  uint256 public constant round1Max = 150000000E4;

  // uint256 public constant round2Cap = 60000000E4;
  uint256 public constant round2Max = 210000000E4;

  // uint256 public constant round3Cap = 45000000E4;
  uint256 public constant round3Max = 255000000E4;

  // uint256 public constant round4Cap = 30000000E4;
  uint256 public constant round4Max = 285000000E4;

  // uint256 public constant round5Cap = 15000000E4;
  uint256 public constant round5Max = 300000000E4;

  // Timestamp when the crowdsale starts 01/01/2018 @ 00:00am (UTC);
  uint256 public startTime = 1514764800;

  // Timestamp when the initial round ends (UTC);
  uint256 public currentRoundStart = startTime;

  // Timestamp when the crowdsale ends 07/07/2018 @ 00:00am (UTC);
  uint256 public endTime = 1530921600;

  // If the crowdsale has ended or not
  bool public isEnded = false;

  // How much each user paid for the crowdsale
  mapping(address => uint256) public crowdsaleBalances;

  // How many tokens each user got for the crowdsale
  mapping(address => uint256) public tokensBought;

  // How many tokens each user got for the crowdsale as bonus
  mapping(address => uint256) public bonusBalances;

  // Bonus levels per each round
  mapping (uint => uint) public bonusLevels;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  event Pause();
  event Unpause();

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  modifier whenPaused() {
    require(paused);
    _;
  }

  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }

  function setNewBonusLevel (uint256 _bonusIndex, uint256 _bonusValue) onlyOwner external {
    bonusLevels[_bonusIndex] = _bonusValue;
  }

  function setMinPurchase (uint _minPurchase) onlyOwner external {
    minPurchase = _minPurchase;
  }

   // @notice Set's the rate of tokens per ether for each round
  function setNewRates (uint256 _r1, uint256 _r2, uint256 _r3, uint256 _r4, uint256 _r5, uint256 _r6) onlyOwner external {
    require(_r1 > 0 && _r2 > 0 && _r3 > 0 && _r4 > 0 && _r5 > 0 && _r6 > 0);

      rate = _r1;
      rateRound2 = _r2;
      rateRound3 = _r3;
      rateRound4 = _r4;
      rateRound5 = _r5;
      rateRound6 = _r6;
  }


  /**
   * @param _rate Number of token units a buyer gets per ETH
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */

  constructor(uint256 _rate, address _wallet, address _owner, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
    owner = _owner;

    //bonus values per each round;
    bonusLevels[1] =  5;
    bonusLevels[2] = 10;
    bonusLevels[3] = 15;
    bonusLevels[4] = 20;
    bonusLevels[5] = 50;

  }

  // -----------------------------------------
  // Crowdsale interface
  // -----------------------------------------

  function () external payable whenNotPaused {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable whenNotPaused {

    uint256 amountPaid = msg.value;
    _preValidatePurchase(_beneficiary, amountPaid);

    uint256 tokens = 0;
    uint256 bonusTokens = 0;

    if(soldTokens < round1Max) {

        tokens = _getTokensAmount(amountPaid, 1);
        bonusTokens = _getBonusAmount(tokens, 1);

        // If the amount of tokens that you want to buy gets out of round 1
        if(soldTokens.add(tokens) > round1Max) {
            setCurrentRound(2);
            tokens = _calculateExcessTokens(amountPaid, round1Max, 1, rate);
            bonusTokens = _calculateExcessBonus(tokens, 2);
        }

    // Round 2
    } else if(soldTokens >= round1Max && soldTokens < round2Max) {
        tokens = _getTokensAmount(amountPaid, 2);

        // If the amount of tokens that you want to buy gets out of round 2
        if(soldTokens.add(tokens) > round2Max) {
            setCurrentRound(3);
            tokens = _calculateExcessTokens(amountPaid, round2Max, 2, rateRound2);
            bonusTokens = _calculateExcessBonus(tokens, 3);
        }

    // Round 3
    } else if(soldTokens >= round2Max && soldTokens < round3Max) {
         tokens = _getTokensAmount(amountPaid, 3);

         // If the amount of tokens that you want to buy gets out of round 3
         if(soldTokens.add(tokens) > round3Max) {
            setCurrentRound(4);
            tokens = _calculateExcessTokens(amountPaid, round3Max, 3, rateRound3);
            bonusTokens = _calculateExcessBonus(tokens, 4);
         }

    // Round 4
    } else if(soldTokens >= round3Max && soldTokens < round4Max) {
         tokens = _getTokensAmount(amountPaid, 4);

         // If the amount of tokens that you want to buy gets out of round 4
         if(soldTokens.add(tokens) > round4Max) {
            setCurrentRound(5);
            tokens = _calculateExcessTokens(amountPaid, round4Max, 4, rateRound4);
            bonusTokens = _calculateExcessBonus(tokens, 5);
         }

    // Round 5
    } else if(soldTokens >= round4Max && soldTokens < round5Max) {
         tokens = _getTokensAmount(amountPaid, 5);

         // If the amount of tokens that you want to buy gets out of round 5
         if(soldTokens.add(tokens) > round5Max) {
            setCurrentRound(6);
            tokens = _calculateExcessTokens(amountPaid, round4Max, 5, rateRound5);
            bonusTokens = 0;
         }

    // Round 6
    } else if(soldTokens >= round5Max) {
        tokens = _getTokensAmount(amountPaid, 6);
    }

    // update state
    weiRaised = weiRaised.add(amountPaid);
    soldTokens = soldTokens.add(tokens);
    soldTokens = soldTokens.add(bonusTokens);

    // Keep a record of how many tokens everybody gets in case we need to do refunds
    tokensBought[msg.sender] = tokensBought[msg.sender].add(tokens);

    // Kepp a record of how many wei everybody contributed in case we need to do refunds
    crowdsaleBalances[msg.sender] = crowdsaleBalances[msg.sender].add(amountPaid);

    // Kepp a record of how many token everybody got as bonus to display in
    bonusBalances[msg.sender] = bonusBalances[msg.sender].add(bonusTokens);

   // Combine bought tokens with bonus tokens before sending to investor
    uint256 totalTokens = tokens.add(bonusTokens);

    // Distribute the token
    _processPurchase(_beneficiary, totalTokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      amountPaid,
      totalTokens
    );
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) view internal {

    require(_beneficiary != address(0));
    require(_weiAmount != 0);

    bool withinPeriod = hasStarted() && hasNotEnded();
    bool nonZeroPurchase = msg.value > 0;
    bool withinTokenLimit = soldTokens < maxTokensRaised;
    bool minimumPurchase = msg.value >= minPurchase;

    require(withinPeriod);
    require(nonZeroPurchase);
    require(withinTokenLimit);
    require(minimumPurchase);
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override to extend the way in which ether is converted to bonus tokens.
   * @param _tokenAmount Value in wei to be converted into tokens
   * @return Number of bonus tokens that can be distributed with the specified bonus percent
   */
  function _getBonusAmount(uint256 _tokenAmount, uint256 _bonusIndex) internal view returns (uint256) {
    uint bonusValue = _tokenAmount.mul(bonusLevels[_bonusIndex]);
    return bonusValue.div(100);
  }

    function _calculateExcessBonus(uint256 tokens, uint256 level) internal view returns (uint256 totalBonus) {
        uint256 thisLevelTokens = soldTokens.add(tokens);
        uint256 nextLevelTokens = thisLevelTokens.sub(round1Max);
        totalBonus = _getBonusAmount(nextLevelTokens, level);
    }

   function _calculateExcessTokens(
      uint256 amount,
      uint256 tokensThisRound,
      uint256 roundSelected,
      uint256 _rate
   ) public returns(uint256 totalTokens) {
      require(amount > 0 && tokensThisRound > 0 && _rate > 0);
      require(roundSelected >= 1 && roundSelected <= 6);

      uint weiThisRound = tokensThisRound.sub(soldTokens).div(_rate);
      uint weiNextRound = amount.sub(weiThisRound);
      uint tokensNextRound = 0;

      // If there's excessive wei for the last tier, refund those
      if(roundSelected != 6) {
        tokensNextRound = _getTokensAmount(weiNextRound, roundSelected.add(1));
      }
      else
         msg.sender.transfer(weiNextRound);

      totalTokens = tokensThisRound.sub(soldTokens).add(tokensNextRound);
   }


   function _getTokensAmount(uint256 weiPaid, uint256 roundSelected)
        internal constant returns(uint256 calculatedTokens)
   {
      require(weiPaid > 0);
      require(roundSelected >= 1 && roundSelected <= 6);
      uint typeTokenWei = weiPaid.div(1E14);

      if(roundSelected == 1)
         calculatedTokens = typeTokenWei.mul(rate);
      else if(roundSelected == 2)
         calculatedTokens = typeTokenWei.mul(rateRound2);
      else if(roundSelected == 3)
         calculatedTokens = typeTokenWei.mul(rateRound3);
      else if(roundSelected == 4)
         calculatedTokens = typeTokenWei.mul(rateRound4);
      else if(roundSelected == 5)
         calculatedTokens = typeTokenWei.mul(rateRound5);
      else
         calculatedTokens = typeTokenWei.mul(rateRound6);
   }

  // -----------------------------------------
  // External interface (withdraw)
  // -----------------------------------------

  /**
   * @dev Determines how ETH is being transfered to owners wallet.
   */
  function _withdrawAllFunds() onlyOwner external {
    wallet.transfer(weiRaised);
  }

  function _withdrawWei(uint256 _amount) onlyOwner external {
    wallet.transfer(_amount);
  }

  function changeWallet(address _newWallet) onlyOwner external {
    wallet = _newWallet;
  }

   /// @notice Public function to check if the crowdsale has ended or not
   function hasNotEnded() public constant returns(bool) {
      return now < endTime && soldTokens < maxTokensRaised;
   }

   /// @notice Public function to check if the crowdsale has started or not
   function hasStarted() public constant returns(bool) {
      return now > startTime;
   }

    function setCurrentRound(uint256 _roundIndex) internal {
        currentRound = _roundIndex;
        currentRoundStart = now;
    }


    //move to next round by overwriting soldTokens value, unsold tokens will be burned;
   function goNextRound() onlyOwner external {
       uint256 nextRound = currentRound.add(1);
       uint256 unSoldTokensLastRound;
       setCurrentRound(nextRound);
        if(currentRound == 2) {
            unSoldTokensLastRound = round1Max.sub(soldTokens);
            unSoldTokens.add(unSoldTokensLastRound);
            soldTokens = round1Max;
       } else if(currentRound == 3) {
            unSoldTokensLastRound = round2Max.sub(soldTokens);
            unSoldTokens.add(unSoldTokensLastRound);
           soldTokens = round2Max;
       } else if(currentRound == 4) {
            unSoldTokensLastRound = round3Max.sub(soldTokens);
            unSoldTokens.add(unSoldTokensLastRound);
           soldTokens = round3Max;
       } else if(currentRound == 5) {
            unSoldTokensLastRound = round4Max.sub(soldTokens);
            unSoldTokens.add(unSoldTokensLastRound);
           soldTokens = round4Max;
       } else if(currentRound == 6) {
            unSoldTokensLastRound = round5Max.sub(soldTokens);
            unSoldTokens.add(unSoldTokensLastRound);
           soldTokens = round5Max;
       }
   }

    function currentBonusLevel() public view returns(uint256) {
        return bonusLevels[currentRound];
    }

}
