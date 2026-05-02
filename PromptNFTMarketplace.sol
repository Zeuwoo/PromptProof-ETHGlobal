// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract PromptNFTMarketplace is ERC721URIStorage, Ownable, ReentrancyGuard {
    constructor() ERC721("AI Prompt NFT", "PRMPT") Ownable(msg.sender) {}
    uint256 public nextTokenId;
    uint256 public platformFeePercentage = 2; 

    struct Prompt {
        address payable creator;
        uint256 price;
        bool isActive;
        uint256 totalScore;
        uint256 ratingCount;
    }

    mapping(uint256 => Prompt) public promptDetails;
    mapping(uint256 => mapping(address => bool)) public hasAccess;
    mapping(uint256 => mapping(address => bool)) public hasRated;

    event PromptMinted(uint256 indexed tokenId, address indexed creator, uint256 price);
    event AccessPurchased(uint256 indexed tokenId, address indexed buyer, uint256 creatorRevenue, uint256 platformFee);
    event PromptRated(uint256 indexed tokenId, address indexed rater, uint8 score);


    function mintPrompt(string memory metadataURI, uint256 _price) public returns (uint256) {
        uint256 tokenId = nextTokenId++;
        
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, metadataURI);

        promptDetails[tokenId] = Prompt({
            creator: payable(msg.sender),
            price: _price,
            isActive: true,
            totalScore: 0,
            ratingCount: 0
        });

        hasAccess[tokenId][msg.sender] = true;

        emit PromptMinted(tokenId, msg.sender, _price);
        return tokenId;
    }

    function buyAccess(uint256 tokenId) public payable nonReentrant {
        require(ownerOf(tokenId) != address(0), "Prompt NFT does not exist"); 
        require(promptDetails[tokenId].isActive, "Prompt is not active");
        require(msg.value == promptDetails[tokenId].price, "Incorrect ETH value");
        require(!hasAccess[tokenId][msg.sender], "Already purchased");

        hasAccess[tokenId][msg.sender] = true;

        uint256 platformFee = (msg.value * platformFeePercentage) / 100;
        uint256 creatorRevenue = msg.value - platformFee;

        promptDetails[tokenId].creator.transfer(creatorRevenue);
        payable(owner()).transfer(platformFee);

        emit AccessPurchased(tokenId, msg.sender, creatorRevenue, platformFee);
    }

    function ratePrompt(uint256 tokenId, uint8 score) public {
        require(hasAccess[tokenId][msg.sender], "Must purchase to rate");
        require(!hasRated[tokenId][msg.sender], "Already rated");
        require(score > 0 && score <= 5, "Score must be between 1 and 5");

        hasRated[tokenId][msg.sender] = true;
        promptDetails[tokenId].totalScore += score;
        promptDetails[tokenId].ratingCount += 1;

        emit PromptRated(tokenId, msg.sender, score);
    }

    function getAverageRating(uint256 tokenId) public view returns (uint256) {
        if (promptDetails[tokenId].ratingCount == 0) return 0;
        return (promptDetails[tokenId].totalScore * 10) / promptDetails[tokenId].ratingCount;
    }
}
