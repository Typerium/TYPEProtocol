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

  // Amount of wei raised
  uint256 public weiRaised;

  // Amount of sold tokens
  uint256 public soldTokens;

  // Amount of unsold tokens to burn
  uint256 public unSoldTokens;

  // Amount of locked tokens
  uint256 public lockedTokens;

  // Amount of distributed tokens
  uint256 public distributedTokens;

  // ICO state paused or not
  bool public paused = false;

  // Minimal amount to exchange in ETH
  uint256 minPurchase = 10 szabo;

  // Keeping track of current round
  uint256 currentRound;

  // We can only sell maximum total amount- 1,000,000,000 tokens during the ICO
  uint256 public constant maxTokensRaised = 1000000000E4;

  // Timestamp when the crowdsale starts 01/01/2018 @ 00:00am (UTC);
  uint256 public startTime = 1514764800;

  // Timestamp when the initial round ends (UTC);
  uint256 public currentRoundStart = startTime;

  // Timestamp when the crowdsale ends 07/07/2018 @ 00:00am (UTC);
  uint256 public endTime = 1530921600;

  // Timestamp when locked tokens become unlocked 21/09/2018 @ 00:00am (UTC);
  uint256 public lockedTill = 1537488000;

  // How much each user paid for the crowdsale
  mapping(address => uint256) public crowdsaleBalances;

  // How many tokens each user got for the crowdsale
  mapping(address => uint256) public tokensBought;

  // How many tokens each user got for the crowdsale as bonus
  mapping(address => uint256) public bonusBalances;

  // How many tokens each user got locked
  mapping(address => uint256) public lockedBalances;

  // How many tokens each user got distributed
  mapping(address => uint256) public distributedBalances;

  // Bonus levels per each round
  mapping (uint => uint) public bonusLevels;

  // Rate levels per each round
  mapping (uint => uint) public rateLevels;

  // Cap levels per each round
  mapping (uint => uint) public capLevels;


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

  function setNewRateLevel (uint256 _rateIndex, uint256 _rateValue) onlyOwner external {
    rateLevels[_rateIndex] = _rateValue;
  }

  function setMinPurchase (uint _minPurchase) onlyOwner external {
    minPurchase = _minPurchase;
  }

   // @notice Set's the rate of tokens per ether for each round
  function setNewRatesCustom (uint256 _r1, uint256 _r2, uint256 _r3, uint256 _r4, uint256 _r5, uint256 _r6) onlyOwner external {
    require(_r1 > 0 && _r2 > 0 && _r3 > 0 && _r4 > 0 && _r5 > 0 && _r6 > 0);
    rateLevels[1] = _r1;
    rateLevels[2] = _r2;
    rateLevels[3] = _r3;
    rateLevels[4] = _r4;
    rateLevels[5] = _r5;
    rateLevels[6] = _r6;
  }

   // @notice Set's the rate of tokens per ether for each round
  function setNewRatesBase (uint256 _r1) onlyOwner external {
    require(_r1 > 0);
    rateLevels[1] = _r1;
    rateLevels[2] = _r1.div(2);
    rateLevels[3] = _r1.div(3);
    rateLevels[4] = _r1.div(4);
    rateLevels[5] = _r1.div(5);
    rateLevels[6] = _r1.div(6);
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

    wallet = _wallet;
    token = _token;
    owner = _owner;

    soldTokens = 0;
    unSoldTokens = 0;

    lockedTokens = 0;
    distributedTokens = 0;

    currentRound = 1;

    //bonus values per each round;
    bonusLevels[1] =  5;
    bonusLevels[2] = 10;
    bonusLevels[3] = 15;
    bonusLevels[4] = 20;
    bonusLevels[5] = 50;

    //rate values per each round;
    rateLevels[1] = _rate;
    rateLevels[2] = _rate.div(2);
    rateLevels[3] = _rate.div(3);
    rateLevels[4] = _rate.div(4);
    rateLevels[5] = _rate.div(5);
    rateLevels[6] = _rate.div(6);

    //cap values per each round
    capLevels[1] = 150000000E4;
    capLevels[2] = 210000000E4;
    capLevels[3] = 255000000E4;
    capLevels[4] = 285000000E4;
    capLevels[5] = 300000000E4;
    capLevels[6] = maxTokensRaised;

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

    if(soldTokens < capLevels[1]) {

        tokens = _getTokensAmount(amountPaid, 1);
        bonusTokens = _getBonusAmount(tokens, 1);

        // If the amount of tokens that you want to buy gets out of round 1
        if(soldTokens.add(tokens) > capLevels[1]) {
            setCurrentRound(2);
            tokens = _calculateExcessTokens(amountPaid, 1);
            bonusTokens = _calculateExcessBonus(tokens, 2);
        }

    // Round 2
    } else if(soldTokens >= capLevels[1] && soldTokens < capLevels[2]) {
        tokens = _getTokensAmount(amountPaid, 2);
        bonusTokens = _getBonusAmount(tokens, 2);

        // If the amount of tokens that you want to buy gets out of round 2
        if(soldTokens.add(tokens) > capLevels[2]) {
            setCurrentRound(3);
            tokens = _calculateExcessTokens(amountPaid, 2);
            bonusTokens = _calculateExcessBonus(tokens, 3);
        }

    // Round 3
    } else if(soldTokens >= capLevels[2] && soldTokens < capLevels[3]) {
         tokens = _getTokensAmount(amountPaid, 3);
         bonusTokens = _getBonusAmount(tokens, 3);

         // If the amount of tokens that you want to buy gets out of round 3
         if(soldTokens.add(tokens) > capLevels[3]) {
            setCurrentRound(4);
            tokens = _calculateExcessTokens(amountPaid, 3);
            bonusTokens = _calculateExcessBonus(tokens, 4);
         }

    // Round 4
    } else if(soldTokens >= capLevels[3] && soldTokens < capLevels[4]) {
         tokens = _getTokensAmount(amountPaid, 4);
         bonusTokens = _getBonusAmount(tokens, 4);

         // If the amount of tokens that you want to buy gets out of round 4
         if(soldTokens.add(tokens) > capLevels[4]) {
            setCurrentRound(5);
            tokens = _calculateExcessTokens(amountPaid, 4);
            bonusTokens = _calculateExcessBonus(tokens, 5);
         }

    // Round 5
    } else if(soldTokens >= capLevels[4] && soldTokens < capLevels[5]) {
         tokens = _getTokensAmount(amountPaid, 5);
         bonusTokens = _getBonusAmount(tokens, 5);

         // If the amount of tokens that you want to buy gets out of round 5
         if(soldTokens.add(tokens) > capLevels[5]) {
            setCurrentRound(6);
            tokens = _calculateExcessTokens(amountPaid, 5);
            bonusTokens = 0;
         }

    // Round 6
    } else if(soldTokens >= capLevels[5]) {
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
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    uint256 _tokensToDeliver = _tokenAmount.div(2);
    uint256 _tokensToLock = _tokenAmount.sub(_tokensToDeliver);
    _deliverTokens(_beneficiary, _tokensToDeliver);
    _lockTokens(_beneficiary, _tokensToLock);

    distributedBalances[_beneficiary] = distributedBalances[_beneficiary].add(_tokensToDeliver);
  }


  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
    distributedTokens = distributedTokens.add(_tokenAmount);
  }

  function _lockTokens(address _beneficiary, uint256 _tokenAmount) internal {
    lockedBalances[_beneficiary] = lockedBalances[_beneficiary].add(_tokenAmount);
    lockedTokens = lockedTokens.add(_tokenAmount);
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
        uint256 nextLevelTokens = thisLevelTokens.sub(capLevels[level]);
        totalBonus = _getBonusAmount(nextLevelTokens, level);
    }

   function _calculateExcessTokens(
      uint256 amount,
      uint256 roundSelected
   ) public returns(uint256 totalTokens) {
      require(amount > 0);
      require(roundSelected >= 1 && roundSelected <= 6);

      uint _rate = rateLevels[roundSelected];
      uint weiThisRound = capLevels[roundSelected].sub(soldTokens).div(_rate);
      uint weiNextRound = amount.sub(weiThisRound);
      uint tokensNextRound = 0;

      // If there's excessive wei for the last tier, refund those
      if(roundSelected != 6) {
        tokensNextRound = _getTokensAmount(weiNextRound, roundSelected.add(1));
      }
      else
         msg.sender.transfer(weiNextRound);

      totalTokens = capLevels[roundSelected].sub(soldTokens).add(tokensNextRound);
   }


   function _getTokensAmount(uint256 weiPaid, uint256 roundSelected)
        internal constant returns(uint256 calculatedTokens)
   {
      require(weiPaid > 0);
      require(roundSelected >= 1 && roundSelected <= 6);
      uint typeTokenWei = weiPaid.div(1E14);
      calculatedTokens = typeTokenWei.mul(rateLevels[roundSelected]);

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
       uint256 unSoldTokensLastRound;
       unSoldTokensLastRound = capLevels[currentRound].sub(soldTokens);
       unSoldTokens.add(unSoldTokensLastRound);
       soldTokens = capLevels[currentRound];
       currentRound = currentRound.add(1);
       currentRoundStart = now;
   }

    function round() public view returns(uint256) {
        return currentRound;
    }

    function currentBonusLevel() public view returns(uint256) {
        return bonusLevels[currentRound];
    }

    function currentRateLevel() public view returns(uint256) {
        return rateLevels[currentRound];
    }

    function currentCapLevel() public view returns(uint256) {
        return capLevels[currentRound];
    }

    function transferLockedBalance(address _beneficiary) public {
        require(_beneficiary != address(0));
        require(now >= lockedTill);
        require(lockedTokens > 0);
        uint256 _lockedTokensToTransfer = lockedBalances[_beneficiary];
        token.transfer(_beneficiary, _lockedTokensToTransfer);
        lockedTokens.sub(_lockedTokensToTransfer);
    }

}
