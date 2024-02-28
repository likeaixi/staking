//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Array {
    /**
    *   @notice remove given elements from array
    *   @dev usable only if _array contains unique elements only
     */
    function removeElement(uint256[] storage _array, uint256 _element) internal {
        for (uint256 i; i<_array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }

    /**
    *   @notice remove given address from array
    *   @dev usable only if _array contains unique address only
     */
    function removeAddress(address[] storage _array, address _element) internal {
        for (uint256 i; i<_array.length; i++) {
            if (_array[i] == _element) {
                _array[i] = _array[_array.length - 1];
                _array.pop();
                break;
            }
        }
    }
}
