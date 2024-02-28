// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library TransferHelper {
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function transferToken(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }
        if (_token == TransferHelper.ETH_ADDRESS) {
            if (_from == address(this)) {
                TransferHelper.safeTransferETH(_to, _amount);
            } else {
                // transfer by msg.value,  && msg.value == _amount
                require(_from == msg.sender && _to == address(this), 'error eth');
            }
        } else {
            if (_from == address(this)) {
                SafeERC20.safeTransfer(IERC20(_token), _to, _amount);
            } else {
                SafeERC20.safeTransferFrom(IERC20(_token), _from, _to, _amount);
            }
        }
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}
