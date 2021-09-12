		pragma solidity ^0.5.0;
		 
		import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
		import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
		import "./22.3_02MartianAuction.sol";
		 
		contract MartianMarket is ERC721Full, Ownable {
		 
			constructor() ERC721Full("MartianMarket", "MARS") public {}
		 
			// Setup counter for token_ids (using safemath version, then creating an instance of counters called token_ids)
			using Counters for Counters.Counter;
			Counters.Counter token_ids;
			
			// Set foundation_address to the contract deployer (msg.sender) and make it payable
			address payable foundation_address = msg.sender;
		 
			// Create a mapping of uint (token_id) => MartianAuction (the contract we created earlier), and name it auctions
			mapping(uint=>MartianAuction) auctions;
		
			// Create a modifier called landRegistered that accepts a uint token_id, and checks if the token exists using the
			// ERC721 _exists function. If the token does not exist, return a message like "Land not registered!" 
			// then run the rest of the function which calls the modifier after the check.
			modifier landRegistered(uint token_id) {
				require(_exists(token_id), "Land not registered!");
				_;
			}
		
			function createAuction(uint token_id) public onlyOwner {
				// Create a new MartianAuction contract in the mapping relating to the token_id
				// refer to our exercise 02 MartianAuction contract, the constructor requires only the beneficiary to create this auction contract.
				// We are adding this to our mapping auctions, at the location of token_id.
				auctions[token_id] = new MartianAuction(foundation_address);
				// Pass the foundation_address to the MartianAuction constructor to set it as the beneficiary
			}
		 
			function registerLand(string memory uri) public onlyOwner {
				// Increment the token_ids, and set a new id as token_ids.current
				token_ids.increment();
				uint token_id = token_ids.current();
		 
				// Mint a new token, setting the foundation as the owner, at the newly created id
				// the _mint function is from our inherited ERC721Full dependencies.   Can get the inputs from OpenZeppelin's github, or the dep section in Remix.
				_mint(foundation_address, token_id);
				
				// Use the _setTokenURI ERC721 function to set the token's URI by the id
				_setTokenURI(token_id, uri);
				
				// Call the createAuction function and pass the token's id
				createAuction(token_id);
			}
		 
			function endAuction(uint token_id) public onlyOwner landRegistered(token_id) {
				// Fetch the MartianAuction from the token_id
				// endAuction can only be run by Owner, and if the land has been registered
				MartianAuction auction = auctions[token_id];
		 
				// Call the auction.end() function (from our earlier contract)
				auction.auctionEnd();
		 
				// Call ERC721 safeTransferFrom, passing in owner() as the first param, auction.highestBidder() as the second, and token_id as the third
				// (Transfer from the owner of the token to the highest bidder of this auction, given this token_id)
				safeTransferFrom(owner(), auction.highestBidder(), token_id);
			}
		 
			function auctionEnded(uint token_id) public view returns(bool) {
				// Fetch the MartianAuction relating to a given token_id, then return the value of auction.ended()
				MartianAuction auction = auctions[token_id];
				return auction.ended();
			}
		 
			function highestBid(uint token_id) public view landRegistered(token_id) returns(uint) {
				// Return the highest bid of the MartianAuction relating to the given token_id
				MartianAuction auction = auctions[token_id];
				return auction.highestBid();
			}
		 
			function pendingReturn(uint token_id, address sender) public view landRegistered(token_id) returns(uint) {
				// Return the auction.pendingReturn() value of a given address and token_id
				MartianAuction auction = auctions[token_id];
				return auction.pendingReturn(sender);
			}
		 
			function bid(uint token_id) public payable landRegistered(token_id) {
				// Fetch the current MartianAuction relating to a given token_id
				MartianAuction auction = auctions[token_id];
		 
				// Call the auction.bid function using the auction.bid.value()() syntax.  Ethereum will be forwarded from this contract (originally from the bidder), and sent to the specific auction that the bidder wants.
				auction.bid.value(msg.value)(msg.sender);
				
				// passing in msg.value in the first set of parenthesis to set the Ether being sent to the bid function,
				// and msg.sender in the second set of parenthesis to pass in the bidder parameter to the auction contract
			}
		}
