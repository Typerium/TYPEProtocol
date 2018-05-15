pragma solidity ^0.4.23;

// File: contracts/OpenZeppelin/ERC20Basic.sol
// File: contracts/OpenZeppelin/SafeMath.sol
// File: contracts/OpenZeppelin/BasicToken.sol
// File: contracts/OpenZeppelin/BurnableToken.sol

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

    /**
     * @dev Burns a specific amount of tokens.
     * @param _value The amount of token to be burned.
     */
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
        // no need to require value <= totalSupply, since that would imply the
        // sender's balance is greater than the totalSupply, which *should* be an assertion failure

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
        emit Transfer(burner, address(0), _value);
    }
}

// File: contracts/OpenZeppelin/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/OpenZeppelin/ERC827.sol

/**
   @title ERC827 interface, an extension of ERC20 token standard
   Interface of a ERC827 token, following the ERC20 standard with extra
   methods to transfer value and data and execute calls in transfers and
   approvals.
 */
contract ERC827 is ERC20 {

    function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
    function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
    function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}

// File: contracts/OpenZeppelin/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     *
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

// File: contracts/OpenZeppelin/ERC827Token.sol

/**
   @title ERC827, an extension of ERC20 token standard
   Implementation the ERC827, following the ERC20 standard with extra
   methods to transfer value and data and execute calls in transfers and
   approvals.
   Uses OpenZeppelin StandardToken.
 */
contract ERC827Token is ERC827, StandardToken {

    /**
       @dev Addition to ERC20 token methods. It allows to
       approve the transfer of value and execute a call with the sent data.
       Beware that changing an allowance with this method brings the risk that
       someone may use both the old and the new allowance by unfortunate
       transaction ordering. One possible solution to mitigate this race condition
       is to first reduce the spender's allowance to 0 and set the desired value
       afterwards:
       https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
       @param _spender The address that will spend the funds.
       @param _value The amount of tokens to be spent.
       @param _data ABI-encoded contract call to call `_to` address.
       @return true if the call function was executed successfully
     */
    function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
        require(_spender != address(this));

        super.approve(_spender, _value);

        require(_spender.call(_data));

        return true;
    }

    /**
       @dev Addition to ERC20 token methods. Transfer tokens to a specified
       address and execute a call with the sent data on the same transaction
       @param _to address The address which you want to transfer to
       @param _value uint256 the amout of tokens to be transfered
       @param _data ABI-encoded contract call to call `_to` address.
       @return true if the call function was executed successfully
     */
    function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
        require(_to != address(this));

        super.transfer(_to, _value);

        require(_to.call(_data));
        return true;
    }

    /**
       @dev Addition to ERC20 token methods. Transfer tokens from one address to
       another and make a contract call on the same transaction
       @param _from The address which you want to send tokens from
       @param _to The address which you want to transfer to
       @param _value The amout of tokens to be transferred
       @param _data ABI-encoded contract call to call `_to` address.
       @return true if the call function was executed successfully
     */
    function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
        require(_to != address(this));

        super.transferFrom(_from, _to, _value);

        require(_to.call(_data));
        return true;
    }

    /**
     * @dev Addition to StandardToken methods. Increase the amount of tokens that
     * an owner allowed to a spender and execute a call with the sent data.
     *
     * approve should be called when allowed[_spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to increase the allowance by.
     * @param _data ABI-encoded contract call to call `_spender` address.
     */
    function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns (bool) {
        require(_spender != address(this));

        super.increaseApproval(_spender, _addedValue);

        require(_spender.call(_data));

        return true;
    }

    /**
     * @dev Addition to StandardToken methods. Decrease the amount of tokens that
     * an owner allowed to a spender and execute a call with the sent data.
     *
     * approve should be called when allowed[_spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to decrease the allowance by.
     * @param _data ABI-encoded contract call to call `_spender` address.
     */
    function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
        require(_spender != address(this));

        super.decreaseApproval(_spender, _subtractedValue);

        require(_spender.call(_data));

        return true;
    }

}

// File: contracts/OpenZeppelin/Ownable.sol


// File: contracts/OpenZeppelin/Pausable.sol
// File: contracts/OpenZeppelin/PausableToken.sol

// File: contracts/TypeToken.sol
contract TypeToken is PausableToken, BurnableToken {

    string public constant name = "Typerium";
    string public constant symbol = "TYPE";
    uint32 public constant decimals = 4;

    constructor() public {
        totalSupply_ = 20000000000000E4;
        balances[owner] = totalSupply_; // Add all tokens to issuer balance
    }

}
