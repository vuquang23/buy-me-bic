// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Whitelist is Context, AccessControlEnumerable {
    bytes32 public constant UPDATE_WHITELIST_ROLE = keccak256("UPDATE_WHITELIST_ROLE");
    constructor() {
        address adminAddress = _msgSender();

        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);

        _setupRole(UPDATE_WHITELIST_ROLE, adminAddress);
    }

    struct UserInfo {
        mapping(bytes32 => bool) role;
        address ref;
        address[] listExtra;
    }

    mapping(address => UserInfo) public userInfo;

    event UpdateMultiUserInfo(address[] _listAddrUser, bytes32[] _listRole, bool[] _listValueRole, address[] _listAddrRef, address[][] _listListExtra, uint256 _time);

    function updateMultiUserInfo(
        address[] memory _listAddrUser,
        bytes32[] memory _listRole,
        bool[] memory _listValueRole,
        address[] memory _listAddrRef,
        address[][] memory _listListExtra) public {
        require(hasRole(UPDATE_WHITELIST_ROLE, _msgSender()), "Must have UPDATE_WHITELIST_ROLE to update userInfo");
        // check
        uint256 lenArray = _listAddrUser.length;
        require(_listRole.length == lenArray, "_listRole.length != lenArray");
        require(_listValueRole.length == lenArray, "_listValueRole.length != lenArray");
        require(_listAddrRef.length == lenArray, "_listAddrRef.length != lenArray");
        require(_listListExtra.length == lenArray, "_listExtra.length != lenArray");

        for (uint256 i = 0; i < lenArray; i++) {
            userInfo[_listAddrUser[i]].ref = _listAddrRef[i];
            userInfo[_listAddrUser[i]].role[_listRole[i]] = _listValueRole[i];
            userInfo[_listAddrUser[i]].listExtra = _listListExtra[i];
        }
        emit UpdateMultiUserInfo(_listAddrUser, _listRole, _listValueRole, _listAddrRef, _listListExtra, block.timestamp);
    }

    function getUserInfo(address _addrUser, bytes32 _role) view public returns (address, bool, address[] memory) {
        return (userInfo[_addrUser].ref, userInfo[_addrUser].role[_role], userInfo[_addrUser].listExtra);
    }

}
