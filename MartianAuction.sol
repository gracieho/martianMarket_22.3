		pragma solidity >=0.4.22 <0.6.0;
		
		contract MartianAuction {
			
			address deployer;
			address payable public beneficiary;
			address public highestBidder;
			uint public highestBid;
			mapping(address => uint) pendingReturns;
			bool public ended;
			
			event HighestBidIncreased(address bidder, uint amount);
			event AuctionEnded(address winner, uint amount);
			
			constructor(
				address payable _beneficiary
			) public {
				deployer = msg.sender;
				beneficiary = _beneficiary;
			}
			
			function bid(address payable sender) public payable {
				require(msg.value > highestBid, "There is already a higher bid.");
				// check the auction has not ended (!ended is not ended)
				require(!ended, "Auction has ended.");
				
				if(highestBid != 0){
					pendingReturns[highestBidder] += highestBid;
				}
			
				// in the below 3 lines, we aren’t setting it as msg.sender, because later, a function will call this function, so the msg.sender is the contract. Which we don't want to set as the highest bidder.
				highestBidder = sender;
				highestBid = msg.value;
				emit HighestBidIncreased(sender, msg.value);
			}
			
			function withdraw() public returns (bool) {
				uint amount = pendingReturns[msg.sender];
				
				if(amount>0) {
					pendingReturns[msg.sender] = 0;
					
					// we are using .send() rather than .transfer() because we want to handle the case that it fails.
					if(!msg.sender.send(amount)) {
						// we get here if transaction failed, ie !msg.sender.send(amount) means we didn't send the amount to the msg.sender.
						pendingReturns[msg.sender] = amount;
						// withdrawal not successful, so return false
						return false;
					}
				}
				// true means function successfully withdrew money to message sender's address. If not, return will be false.
				return true;
			}
			
			function pendingReturn(address sender) public view returns (uint) {
				// this function is for someone to check the balance value they have
				return pendingReturns[sender];
			}
			
			function auctionEnd() public {
				// check for 1) conditions, then carry out the 2) effects, then 3) undertake interactions with other contracts:
				// conditions: that need to be met (2 require statements)
				require(!ended, "Auction has already ended.");
				require(msg.sender == deployer, "You are not the auction deployer!");
				
				// effects
				ended = true;
				emit AuctionEnded(highestBidder, highestBid);
				
				// interactions with other contracts (the beneficiary will get the highestBid value).
				beneficiary.transfer(highestBid);
			}
}
