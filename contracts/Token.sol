pragma solidity ^0.4.23;

contract SafeMath {
	function safeMul(uint a, uint b) internal pure returns(uint) {
		uint c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}
	function safeSub(uint a, uint b) internal pure returns(uint) {
		assert(b <= a);
		return a - b;
	}
	function safeAdd(uint a, uint b) internal pure returns(uint) {
		uint c = a + b;
		assert(c >= a && c >= b);
		return c;
	}
}

contract TypeToken is SafeMath {
	/* Public variables of the token */
	string constant public standard = "ERC20";
	string constant public name = "Typerium";
	string constant public symbol = "TYPE";
	uint8 constant public decimals = 4;
	uint public totalSupply = 10000000000000;
	uint constant public tokensForIco = 20120000000000;
	uint constant public reservedAmount = 20120000000000;
	uint constant public lockedAmount = 15291200000000;
	address public owner;
	address public ico;
	uint public startTime;
	uint public lockReleaseDate;
	bool allowBurn;
	mapping(address => uint) public balanceOf;
	mapping(address => mapping(address => uint)) public allowance;

	/* Events */
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed _owner, address indexed spender, uint value);
	event Burned(uint amount);

	/* Initializes contract with initial supply tokens to the creator of the contract */
	constructor(address _ownerAddr, uint _startTime) public {
		owner = _ownerAddr;
		startTime = _startTime;
		lockReleaseDate = startTime + 1 years;
		balanceOf[owner] = totalSupply; // Give the owner all initial tokens
	}

	function transfer(address _to, uint _value) internal returns(bool success) {
		require(now >= startTime); //check if the crowdsale is already over
		if (msg.sender == owner && now < lockReleaseDate) //prevent the owner of spending his share of tokens within first year
			require(safeSub(balanceOf[msg.sender], _value) >= lockedAmount);
		balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value); // Subtract from the sender
		balanceOf[_to] = safeAdd(balanceOf[_to], _value); // Add the same to the recipient
		emit Transfer(msg.sender, _to, _value); // Notify anyone listening that this transfer took place
		return true;
	}

	function approve(address _spender, uint _value) internal returns(bool success) {
		return _approve(_spender,_value);
	}

	function _approve(address _spender, uint _value) internal returns(bool success) {
		require((_value == 0) || (allowance[msg.sender][_spender] == 0));
		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function transferFrom(address _from, address _to, uint _value) internal returns(bool success) {
		if (now < startTime)  //check if the crowdsale is already over
			require(_from == owner);
		if (_from == owner && now < lockReleaseDate) //prevent the owner of spending his share of tokens for company, loyalty program and future financing of the company within the first year
			require(safeSub(balanceOf[_from], _value) >= lockedAmount);
		uint _allowance = allowance[_from][msg.sender];
		balanceOf[_from] = safeSub(balanceOf[_from], _value); // Subtract from the sender
		balanceOf[_to] = safeAdd(balanceOf[_to], _value); // Add the same to the recipient
		allowance[_from][msg.sender] = safeSub(_allowance, _value);
		emit Transfer(_from, _to, _value);
		return true;
	}


	/*  to be called when ICO is closed. burns the remaining tokens except the tokens reserved for the bounty/advisors/marketing program
	 *  (48288000), for the loyalty program (52312000) and for future financing of the company (40240000).
	 *  anybody may burn the tokens after ICO ended, but only once (in case the owner holds more tokens in the future).
	 *  this ensures that the owner will not posses a majority of the tokens. */
	function burn() internal {
		//if tokens have not been burned already and the ICO ended
		if (!allowBurn && now > startTime) {
			uint difference = safeSub(balanceOf[owner], reservedAmount);
			balanceOf[owner] = reservedAmount;
			totalSupply = safeSub(totalSupply, difference);
			allowBurn = false;
			emit Burned(difference);
		}
	}

	/**
	* sets the ico address and give it allowance to spend the crowdsale tokens. Only callable once.
	* @param _icoAddress the address of the ico contract
	* value the max amount of tokens to sell during the ICO
	**/
	function setICO(address _icoAddress) internal {
		require(msg.sender == owner);
		ico = _icoAddress;
		assert(_approve(ico, tokensForIco));
	}
	/**
	* Allows the ico contract to set the trading start time to an earlier point of time.
	* (In case the soft cap has been reached)
	* @param _newStart the new start date
	**/
	function setStart(uint _newStart) internal {
		require(msg.sender == ico && _newStart < startTime);
		startTime = _newStart;
	}
}
