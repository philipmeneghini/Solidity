//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20

interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);

    // first three functions required to be a ERC-20 token
    // The remaining functions are required for it to be fully functional

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
