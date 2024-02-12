// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {ITicketNFT} from "./interfaces/ITicketNFT.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TicketNFT} from "./TicketNFT.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol"; 
import {ITicketMarketplace} from "./interfaces/ITicketMarketplace.sol";
import "hardhat/console.sol";

contract TicketMarketplace is ITicketMarketplace {
    address private coin_address;
    address private ticket_owner;
    TicketNFT public ticket_nft;
    uint128 private current_event_id;

    struct Event {
        uint128 maxTickets;
        uint256 nextTicketToSell;
        uint256 pricePerTicket;
        uint256 pricePerTicketERC20;
    }
    Event[] private market_events;

    constructor(address coinAddress) {
        coin_address = coinAddress;
        ticket_owner = msg.sender;
        ticket_nft = new TicketNFT();
        current_event_id = 0;
    }

    function createEvent(uint128 maxTickets, uint256 pricePerTicket, uint256 pricePerTicketERC20) external {
        require(msg.sender == ticket_owner, "Unauthorized access");
        Event memory newEvent = Event(maxTickets, 0, pricePerTicket, pricePerTicketERC20);
        market_events.push(newEvent);
        emit EventCreated(current_event_id, maxTickets, pricePerTicket, pricePerTicketERC20);
        current_event_id++;
    }

    function setMaxTicketsForEvent(uint128 eventId, uint128 newMaxTickets) external {
        require(msg.sender == ticket_owner, "Unauthorized access");
        console.log("Current maxTickets:", market_events[eventId].maxTickets);
        console.log("New maxTickets:", newMaxTickets);
        console.log("nextTicketToSell:", market_events[eventId].nextTicketToSell);
        if (newMaxTickets < market_events[eventId].maxTickets) {
            revert("The new number of max tickets is too small!");
        }
        market_events[eventId].maxTickets = newMaxTickets;
        emit MaxTicketsUpdate(eventId, newMaxTickets);
    }

    function setPriceForTicketETH(uint128 eventId, uint256 price) external {
        require(msg.sender == ticket_owner, "Unauthorized access");
        market_events[eventId].pricePerTicket = price;
        emit PriceUpdate(eventId, price, "ETH");
    }

    function setPriceForTicketERC20(uint128 eventId, uint256 price) external {
        require(msg.sender == ticket_owner, "Unauthorized access");
        market_events[eventId].pricePerTicketERC20 = price;
        emit PriceUpdate(eventId, price, "ERC20");
    }

    function buyTickets(uint128 eventId, uint128 ticketCount) payable external {
        uint256 ticket_price;
        unchecked { ticket_price = market_events[eventId].pricePerTicket * ticketCount; }
        require(ticket_price / market_events[eventId].pricePerTicket == ticketCount, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(msg.value >= ticket_price, "Not enough funds supplied to buy the specified number of tickets.");
        require(ticketCount <= market_events[eventId].maxTickets - market_events[eventId].nextTicketToSell, "We don't have that many tickets left to sell!");

        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 next_ticket = market_events[eventId].nextTicketToSell;
            uint256 next_ticket_id = (uint256(eventId) << 128) + next_ticket;
            ticket_nft.mintFromMarketPlace(msg.sender, next_ticket_id);
            market_events[eventId].nextTicketToSell++;
        }

        emit TicketsBought(eventId, ticketCount, "ETH");
    }

    function buyTicketsERC20(uint128 eventId, uint128 ticketCount) external {
        uint256 ticket_price;
        unchecked { ticket_price = market_events[eventId].pricePerTicketERC20 * ticketCount; }
        require(ticket_price / market_events[eventId].pricePerTicketERC20 == ticketCount, "Overflow happened while calculating the total price of tickets. Try buying smaller number of tickets.");
        require(IERC20(coin_address).balanceOf(msg.sender) >= ticket_price, "Not enough funds supplied to buy the specified number of tickets.");
        require(ticketCount <= market_events[eventId].maxTickets - market_events[eventId].nextTicketToSell, "We don't have that many tickets left to sell!");

        IERC20(coin_address).transferFrom(msg.sender, address(this), ticket_price);

        for (uint128 i = 0; i < ticketCount; i++) {
            uint256 next_ticket = market_events[eventId].nextTicketToSell;
            uint256 next_ticket_id = (uint256(eventId) << 128) + next_ticket;
            ticket_nft.mintFromMarketPlace(msg.sender, next_ticket_id);
            market_events[eventId].nextTicketToSell++;
        }

        emit TicketsBought(eventId, ticketCount, "ERC20");
    }

    function setERC20Address(address newERC20Address) external {
        require(msg.sender == ticket_owner, "Unauthorized access");
        coin_address = newERC20Address;
        emit ERC20AddressUpdate(newERC20Address);
    }

    function nftContract() public view returns (address) {
        return address(ticket_nft);
    }

    function events(uint128 eventId) public view returns (Event memory) {
        return market_events[eventId];
    }

    function ERC20Address() public view returns (address) {
        return coin_address;
    }

    function owner() public view returns (address) {
        return ticket_owner;
    }

    function currentEventId() public view returns (uint128) {
        return current_event_id;
    }
}