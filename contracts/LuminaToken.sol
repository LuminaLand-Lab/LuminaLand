// SPDX-License-Identifier: BSL-1.1
// Copyright © 2026 LuminaLand-Lab. All Rights Reserved.
// Licensed under Business Source License 1.1
// Commercial use prohibited until February 28, 2030
// Contact for early commercial license or acquisition: contact@luminaland.org

// SPDX-License-Identifier: BSL-1.1
pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LuminaToken is ERC20, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18;

    constructor() ERC20("Lumina", "LUMI") Ownable(msg.sender) {
        _mint(msg.sender, MAX_SUPPLY);
    }

    // Burn utilisé automatiquement par le marketplace (0,5 % sur reventes)
    function burnFrom(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
}
