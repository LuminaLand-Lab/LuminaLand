// SPDX-License-Identifier: BSL-1.1
// Copyright © 2026 LuminaLand-Lab. All Rights Reserved.
// Licensed under Business Source License 1.1
// Commercial use prohibited until February 28, 2030
// Contact for early commercial license or acquisition: contact@luminaland.org

pragma solidity 0.8.28;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LuminaPlot is ERC721URIStorage, Ownable {
    uint256 public nextTokenId = 1;
    mapping(uint256 => string) public plotPrompt; // Prompt IA qui a généré le plot

    constructor() ERC721("LuminaPlot", "LPLOT") Ownable(msg.sender) {}

    /**
     * @dev Mint un plot généré par IA (appelable par le marketplace ou owner)
     */
    function mintPlot(address to, string memory prompt) external onlyOwner {
        uint256 tokenId = nextTokenId++;
        _safeMint(to, tokenId);
        plotPrompt[tokenId] = prompt;
        _setTokenURI(tokenId, string(abi.encodePacked("https://luminaland.org/metadata/", tokenId, ".json")));
    }

    /**
     * @dev Brûle un plot (utilisé pour le mécanisme de burn 0.5%)
     */
    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId);
    }
}
