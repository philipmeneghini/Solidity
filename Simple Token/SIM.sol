//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

import "./ERC-20.sol";

contract simple is ERC20Interface{
    string public name = "simple";
    string public symbol = "SIM";
    uint public decimals = 0;
    uint public override totalSupply;

    address public founder;
    mapping(address => uint)public balances; // mapping of the account to the amount of simple owned
    mapping(address => mapping(address => uint))public amt; // mapping of a lender and borrower showing how much credit they have available

    constructor(){
        totalSupply = 10000;
        founder = msg.sender;
        balances[founder] = totalSupply; // initially all of simple goes to the founder
    }

// Function returns the balance of the account specified

    function balanceOf(address _owner) public view override returns (uint256){
        return balances[_owner];
    }

// Transfers simple tokens from sender to the recievers account

    function transfer(address _to, uint256 _value) public override returns (bool success){
        if (balances[msg.sender]>= _value){
            balances[_to]+=_value;
            balances[msg.sender] -= _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        else{
            return false;
        }
    }

// Transfers funds from one account to another if there is a line of credit available

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success){
        require(amt[_from][_to]>=_value);
        require(balances[_from]>=_value);
        balances[_to]+= _value;
        balances[_from]-= _value;
        amt[_from][_to] -= _value;
        emit Transfer(_from, _to, _value);

        return true;
    }

// Approves a borrower to have a line of credit on the lender's account

    function approve(address _spender, uint256 _value) public override returns (bool success){
        require(balances[msg.sender]>= _value);
        amt[msg.sender][_spender]= _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

// Returns how much "allowance" a borrower has from a lender

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining){
        return amt[_owner][_spender];
    }

}
