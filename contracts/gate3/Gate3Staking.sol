// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./libs/Array.sol";

contract Gate3Staking is Ownable, ERC1155Holder{
    using Address for address;
    using Array for uint256[];
    using Array for address[];

    /**
     *    @notice keep track of each user and their info
     */
    struct UserInfo {
        mapping(address => uint256[]) stakedTokens;
        mapping(address => mapping(uint256 => uint256)) stakedTokenAmounts;
        uint256 amountStaked;
    }

    /**
     *    @notice keep track of each collection and their info
     */
    struct CollectionInfo {
        bool isStakable;
        address collectionAddress;
        uint256 stakingFee;
        uint256 unstakingFee;
        uint256 multiplier;
        uint256 amountOfStakers;
        address[] stakers;
        uint256 stakingLimit;
    }

    /**
     *    @notice map user addresses over their info
     */
    mapping(address => UserInfo) public userInfo;

    /**
     *    @notice collection address => (staked nft => user address)
     */
//    mapping(address => mapping(uint256 => address)) public tokenOwners;

    /**
     *   @notice array of each collection, we search through this by _cid (collection identifier)
     */
    CollectionInfo[] public collectionInfo;

    event Stake(address from, uint256 id, uint256 amount, address collection);
    event Unstake(address from, uint256 id, uint256 amount, address collection);

    constructor() {}

    /*-------------------------------Main external functions-------------------------------*/

    /**
     *   @notice external stake function, for single stake request
     *   @param _cid => collection id
     *   @param _id => nft id
     */
    function stake(uint256 _cid, uint256 _id, uint256 _amount) external payable {
        require(
            collectionInfo[_cid].isStakable,
            "Gate3Staking.stake: Not available"
        );
        require(
            msg.value >= collectionInfo[_cid].stakingFee,
            "Gate3Staking.stake: Fee"
        );
        _stake(msg.sender, _cid, _id, _amount);
    }

    /**
     *   @notice loops normal stake, in case of multiple stake requests
     *   @param _cid => collection id
     *   @param _ids => array of nft ids
     */
    function batchStake(uint256 _cid, uint256[] memory _ids, uint256[] memory _amounts) external payable {
        require(
            msg.value >= collectionInfo[_cid].stakingFee * _ids.length,
            "Gate3Staking.stake: Fee"
        );
        for (uint256 i = 0; i < _ids.length; ++i) {
            _stake(msg.sender, _cid, _ids[i], _amounts[i]);
        }
    }

    /**
     *   @notice external unstake function, for single unstake request
     *   @param _cid => collection id
     *   @param _id => nft id
     */
    function unstake(uint256 _cid, uint256 _id, uint256 _amount) external {
        _unstake(msg.sender, _cid, _id, _amount);
    }

    /**
     *   @notice loops normal unstake, in case of multiple unstake requests
     *   @param _cid => collection id
     *   @param _ids => array of nft ids
     */
    function batchUnstake(uint256 _cid, uint256[] memory _ids, uint256[] memory _amounts) external {
        for (uint256 i = 0; i < _ids.length; ++i) {
            _unstake(msg.sender, _cid, _ids[i], _amounts[i]);
        }
    }

    /*-------------------------------Main internal functions-------------------------------*/

    /**
     *    @notice internal stake function, called in external stake and batchStake
     *    @param _user => msg.sender
     *    @param _cid => collection id
     *    @param _id => nft id
     */
    function _stake(
        address _user,
        uint256 _cid,
        uint256 _id,
        uint256 _amount
    ) internal {
        UserInfo storage user = userInfo[_user];
        CollectionInfo storage collection = collectionInfo[_cid];

        require(
            user.amountStaked < collection.stakingLimit,
            "Gate3Staking._stake: You can't stake more"
        );

        IERC1155(collection.collectionAddress).safeTransferFrom(
            _user,
            address(this),
            _id,
            _amount,
            "0x00"
        );

        if (user.stakedTokens[collection.collectionAddress].length == 0) {
            collection.amountOfStakers += 1;
            collection.stakers.push(_user);
        }

//        user.amountStaked += 1;
        user.amountStaked += _amount;
//        user.timeStakedMapping[collection.collectionAddress][_id] = block.timestamp;
        user.stakedTokens[collection.collectionAddress].push(_id);
        user.stakedTokenAmounts[collection.collectionAddress][_id] += _amount;
//        tokenOwners[collection.collectionAddress][_id] = _user;

        emit Stake(_user, _id, _amount, collection.collectionAddress);
    }

    /**
     *    @notice internal unstake function, called in external unstake and batchUnstake
     *    @param _user => msg.sender
     *    @param _cid => collection id
     *    @param _id => nft id
     */
    function _unstake(
        address _user,
        uint256 _cid,
        uint256 _id,
        uint256 _amount
    ) internal {
        UserInfo storage user = userInfo[_user];
        CollectionInfo storage collection = collectionInfo[_cid];
          require(
               user.stakedTokenAmounts[collection.collectionAddress][_id] >= _amount,
               "Gate3Staking._unstake: Insufficient NFT balance"
          );
//        require(
//            tokenOwners[collection.collectionAddress][_id] == _user,
//            "Gate3Staking._unstake: Sender doesn't owns this token"
//        );

//        require(
//            ((block.timestamp - user.timeStakedMapping[collection.collectionAddress][_id]) / 60) >= collection.unstakingCooldown,
//            "Gate3Staking._unstake: You are on cooldown"
//        );

        user.stakedTokenAmounts[collection.collectionAddress][_id] -= _amount;

        if (user.stakedTokenAmounts[collection.collectionAddress][_id] == 0) {
            user.stakedTokens[collection.collectionAddress].removeElement(_id);
        }

        if (user.stakedTokens[collection.collectionAddress].length == 0) {
            collection.amountOfStakers -= 1;
            collection.stakers.removeAddress(_user);
        }

//        delete tokenOwners[collection.collectionAddress][_id];
//        delete user.timeStakedMapping[collection.collectionAddress][_id];

        user.amountStaked -= _amount;

        if (user.amountStaked == 0) {
            delete userInfo[_user];
        }

        IERC1155(collection.collectionAddress).safeTransferFrom(
            address(this),
            _user,
            _id,
            _amount,
            "0x00"
        );

        emit Unstake(_user, _id, _amount, collection.collectionAddress);
    }

    /*-------------------------------Admin functions-------------------------------*/

    /**
     *    @notice initialize new collection
     *    @param _isStakable => is pool active?
     *    @param _collectionAddress => address of nft collection
     *    @param _stakingFee => represented in WEI
     *    @param _unstakingFee => represented in WEI
     *    @param _multiplier => special variable to adjust returns
     *    @param _stakingLimit => total amount of nfts user is allowed to stake
     */
    function setCollection(
        bool _isStakable,
        address _collectionAddress,
        uint256 _stakingFee,
        uint256 _unstakingFee,
        uint256 _multiplier,
        uint256 _stakingLimit
    ) public onlyOwner {
        collectionInfo.push(
            CollectionInfo({
        isStakable: _isStakable,
        collectionAddress: _collectionAddress,
        stakingFee: _stakingFee,
        unstakingFee: _unstakingFee,
        multiplier: _multiplier,
        amountOfStakers: 0,
        stakers: new address[](0),
        stakingLimit: _stakingLimit
        })
        );
    }

    /**
     *    @notice update collection
     *    {see above function for param definition}
     */
    function updateCollection(
        uint256 _cid,
        bool _isStakable,
        address _collectionAddress,
        uint256 _stakingFee,
        uint256 _unstakingFee,
        uint256 _multiplier,
        uint256 _stakingLimit
    ) public onlyOwner {
        CollectionInfo storage collection = collectionInfo[_cid];
        collection.isStakable = _isStakable;
        collection.collectionAddress = _collectionAddress;
        collection.stakingFee = _stakingFee;
        collection.unstakingFee = _unstakingFee;
        collection.multiplier = _multiplier;
        collection.stakingLimit = _stakingLimit;
    }

    /**
     *    @notice enable/disable collections, without updating whole struct
     *    @param _cid => collection id
     *    @param _isStakable => enable/disable
     */
    function manageCollection(uint256 _cid, bool _isStakable) public onlyOwner {
        collectionInfo[_cid].isStakable = _isStakable;
    }


    /**
    *   @notice withdraw ETH from contract
     */
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
    *   @notice withdraw NFT from contract for emergency
     */
    function emergencyWithdraw(uint256 _cid, uint256 _id, uint256 _amount) external onlyOwner {
        CollectionInfo storage collection = collectionInfo[_cid];

        IERC1155(collection.collectionAddress).safeTransferFrom(
            address(this),
            msg.sender,
            _id,
            _amount,
            "0x00"
        );

        emit Unstake(msg.sender, _id, _amount, collection.collectionAddress);
    }

    /*-------------------------------Get functions for frontend-------------------------------*/

    function getUserInfo(address _user, address _collection)
    public
    view
    returns (
        uint256[] memory,
        uint256
    )
    {
        UserInfo storage user = userInfo[_user];
        return (
        user.stakedTokens[_collection],
        user.amountStaked
        );
    }

    function getCollectionInfo(uint256 _cid)
    public
    view
    returns (
        bool,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        address[] memory,
        uint256
    )
    {
        CollectionInfo memory collection = collectionInfo[_cid];
        return (
        collection.isStakable,
        collection.collectionAddress,
        collection.stakingFee,
        collection.unstakingFee,
        collection.multiplier,
        collection.amountOfStakers,
        collection.stakers,
        collection.stakingLimit
        );
    }

    /*-------------------------------Misc-------------------------------*/
    receive() external payable {}
}
