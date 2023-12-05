//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.19;

// ============ Imports ============
import "./enums.sol";
import "./soulboundNFT.sol";
//============== Structures ============

/**
*@dev Structure of Entity Registered into DigiPass
*@notice The Entity represents the user of the application. This can be the a user that has a role of an organization or a regular user. An entity whose role is an organization can be able to create events and get remitted when the tickets are sold out or when the tickets availability period is reached.
*@param - name: The name of the entity
*@param - address: The address of the entity
*@param - proof: The polygon ID proof that holds the ID of the entity
*@param - isVerified: Check if the entity is verified
*@param - role: The role of the entity (e.g. organization | participant)
*/
struct Entity{
    string name;
    address _address;
    bytes proof; //polygon id proof.                                                                                                                                     
    bool isVerified;
    Role role;
}

/**
*@dev Structure of Tickets
*@notice The tickets represents ticket stucture for an event created. Each ticket holds the event information(eventID), that associate each event with a ticket. Tickets are of different types and each type falls into different price ranges. Ticket type can be either regular, vip or vvip. All tickets are soulbound to their respective owners and hence unique for each generated.
*@param - owner: Owner of the ticket.
*@param - eventID: Event ID for which the tickets are for.
*@param - ticketNumber: unique number for the ticket generated.
*@param - price: price of the ticket.
*@param - ticketType: type of the ticket for the event. This is either regular, vip or vvip.
*/
struct Ticket{
    address owner;
    uint256 eventID;
    uint256 ticketNumber;
    uint256 price;
    bool isVerified;
    string ticketQrCode;
    TicketType ticketType;
}

/**
*@dev Structure of Prices
*@notice The prices structure represents the category of price that each ticket type would be sold for. The event organizer chooses the price and each price choose would be the price for which the ticket that falls into that category would be exchanged for. The category includes regular , vip and vvip.
*@param - regular: prices for regular tickets.
*@param - vip: prices for vip tickets.
*@param - vvip: prices for vvip tickets.
*/
struct Prices {
    uint256 regular;
    uint256 vip;
    uint256 vvip;
}

/**
*@dev Parameter Structure of Events
*@notice The EventParams structure contains the event information, this includes the name of the event,venue,location etc. During the creation of any event the organizer will be responsible for accurately filling out the event information.
*@param - name: the name of the event.
*@param - venue: the venue that the event will be held.
*@param - location: the location where the event will be held. This could be some address,remote(virtual) or GPS coordinates.
*@param - imageUrl: the image url of the event. This is the URL that holds the image information of the event.
*@param - availableTickets: The number of tickets that is available for the event.
*@param - startDate: the starting date of the event.
*@param - endDate: the ending date of the event.
*@param - SoulBoundNFT: The soul bound nft that is tied to the event. 
*@param - price: Prices of the tickets to attend the event.
*@param - category: Category of the event eg. Seminar, workshop, art exhibitions etc.
*@param - Entity: The organizers information of the event.
*/

struct EventParams{
    string name;
    string venue;
    string location;
    string imageUrl;
    string eventURL;
    uint256 availableTickets;
    uint256 startDate;
    uint256 endDate;
    Prices price;
    Categories category;
    Entity organization;
}
/**
*@dev  Structure of Events
*@notice The EventParams structure contains the event information, this includes the name of the event,venue,location etc. During the creation of any event the organizer will be responsible for accurately filling out the event information.
*@param - SoulBoundNFT: The soul bound nft that is tied to the event. 
*/
struct Event{
    EventParams eventParams;
    SoulBoundNFT nft;
}

contract DigiPass {
    /**
    *@dev protocolFees 
    *@notice Fees remitted to protocol after the event tickets sales is over. By defualt is  4% of total revenue.
    */
    uint256 immutable protocolFees = 4; //4% of total sold tickets

    /**
    *@dev event counter
    *@notice Counter to track events created in the contract.
    */
    uint256 eventCounter = 0;
    /**
    *@dev mapping of event IDs to participants tickets ids.
    *@notice EventParticipants holds all tickets that have been purchased for an event. All tickets including regular, vip and vvip tickets.
    */
    mapping (uint256=>mapping(uint256=>Ticket)) private EventParticipants;
    /**
    *@dev mapping of participants addresses to participated events
    *@notice Isparticipant holds a boolean value that indicates whether a participant/user has indicated to participate in the event by purchasing a ticket.
    */
    mapping (address => mapping(uint256=>bool)) private IsParticipant;
    /**
    *@dev mapping of eventID to participants numbers that participated in the events
    *@notice totalEventParticipants holds a number value that indicates the total number to participants in the event.
    */
    mapping(uint256 => uint256) private totalEventParticipants;
    /**
    *@dev mapping of event IDs to events
    *@notice EventMap keeps track of all created events,referenced by their ID's.
    */
    mapping (uint256=>Event) private EventMap;
    /**
    *@dev mapping of address of register entities to Entity
    *@notice RegisteredEntities holds information/records of all onboarded users|entities.
    */
    mapping (address => Entity) private RegisteredEntities;

    /**
    *@dev admin mapping and modifier
    *@notice Admin keep tracks of users/entities who can perform administrative actions in the protocol.
    */
    mapping(address => bool) private Admin;
    modifier admin (){
        require(Admin[msg.sender],"Unauthorized Access");
        _;
    }

    /**
    *@dev Error Messages for contract
    */ 
    error EVENT_EXPIRED_NOT_AVAILABLE(uint256 eventID,string eventName);
    error EVENT_NOT_STARTED(uint256 eventID,string eventName);
    error ERROR_UNREGISTERED_ENTITY_ONLY_PARTICIPANTS(address  sender, string eventName);
    error ALREADY_PURCHASED_TICKET(address  sender, string eventName);
    error INSUFFICIENT_ASK_PRICE(address  sender, string eventName);
    error TICKETS_UNAVAILABLE(string eventName);
    error ORGANIZER_ACCESS_REQUIRED(address  sender,string accessRequired);
    error TICKET_SALES_ACTIVE(uint256  eventID,string eventName);
    error INSUFFICIENT_BALANCE(uint256  eventID,string eventName);
    error TICKET_ALREADY_VERIFIED(uint256  ticketNumber,string eventName);
    error ALREADY_REGISTERED_ENTITY(address entity);
    error EVENT_TICKET_EXPIRED(string name,uint256 endDate);


    //============= Events =====================
    /**
    *@dev createEvent
    *@notice Create Event is emitted whenever an event is created. This contains an indexed name and venue of the created event.
    */
    event CreateEvent(string indexed name , string indexed venue);
    /**
    *@dev Ticket Purchased  Event
    *@notice Ticket Purchased event is emitted when a ticket is successfully purchased. This contains an index name and the index ticketNumber associated with the event.
    */
    event TicketPurchased(string indexed name , uint indexed ticketNUmber);
     /**
    *@dev Ticket Verified  Event
    *@notice Ticket Verified event is emitted when a ticket is successfully verified at the event venue. This contains an  event ID, event name and the  ticketNumber associated with the event.
    */
    event TicketVerified(uint256 eventID,string eventName,uint256 ticketNumber);
    /**
    *@dev Onboard Success Event
    *@notice Onboard Success event is emitted when an entity (participant or organization) is successfully registered in the protocol.
    */
    event OnboardSuccess(string indexed name, address indexed entity, Role indexed role);
    /**
    *@dev Remitted Organizer
    *@notice Remitted Organizer event is emitted when tickets sales period for an event is over and the protocol successfully transfers revenues arcues from tickets sales to the organization.
    */
    event RemittedOrganizer(string indexed name, address indexed organization, uint indexed valueAfterFees);

    constructor(){
        //initialize sender as admin
        Admin[msg.sender] = true;
    }

    /**
    *@dev create a new Event using event calldata and organization symbol
    *@notice Create Event creates a new event with the given event call data and organization symbol or abbrevation. Only onboarded entities with organization role access are allowed to create an event. When the event is created a create event is emitted with indexed name and venue of the event created.
    *@param _eventParams - (event structure)
    *@param  organizationSymbol - symbol of the organization
    */

    function createEvent (EventParams calldata _eventParams,string memory organizationSymbol) public {
        //check that creator/caller is an ORGANIZATION
        if(!RegisteredEntities[msg.sender].isVerified || RegisteredEntities[msg.sender].role != Role.ORGANIZATION) revert ORGANIZER_ACCESS_REQUIRED(msg.sender,"ORGANIZATION_ACCESS");
        SoulBoundNFT nft = new SoulBoundNFT(address(this),_eventParams.organization.name,_eventParams.imageUrl,organizationSymbol);
        EventParams memory newEventParam = EventParams(_eventParams.name,_eventParams.venue,_eventParams.location,_eventParams.imageUrl,_eventParams.eventURL,_eventParams.availableTickets,_eventParams.startDate,_eventParams.endDate,_eventParams.price,_eventParams.category,_eventParams.organization);
        Event memory newEvent = Event(newEventParam,nft);

        EventMap[eventCounter] = newEvent;
        //Bind soulbound token creation to event
        eventCounter++;
        emit CreateEvent (newEvent.eventParams.name,newEvent.eventParams.venue);
    }

    /**
    *@dev Purchase Event Tickets 
    *@notice Purchase EventTickets is used to purchase a ticket for a particular event given the event ID and ticket type associated with the event. Only onboarded entities with participant role access can purchase tickets for an event. When a ticket is successfully purchased a TicketPurchased event is emitted with index name and ticket number associated with the event.
    *@param  eventID - (event ID)
    *@param ticketType - (Type of ticket) regular|vip|vvip
    */

    function purchaseTicket (address sender,uint256 eventID,string memory qrCode,TicketType ticketType) public payable{
        Event memory e = EventMap[eventID];
        //check that ticket buyer is a registered in the protocol
        if(!RegisteredEntities[sender].isVerified || RegisteredEntities[sender].role != Role.PARTICIPANT) revert ERROR_UNREGISTERED_ENTITY_ONLY_PARTICIPANTS(sender,e.eventParams.name);
        //check that participant has not purchased a ticket
        if(IsParticipant[sender][eventID]) revert ALREADY_PURCHASED_TICKET(sender,e.eventParams.name);
        //check that event is valid
        if(e.eventParams.endDate < block.timestamp) revert EVENT_TICKET_EXPIRED(e.eventParams.name,e.eventParams.endDate);
        uint price = TicketType.REGULAR == ticketType? e.eventParams.price.regular:TicketType.VIP == ticketType?e.eventParams.price.vip:e.eventParams.price.vvip;

        uint ticketNumber = totalEventParticipants[eventID] + 1;
        //check that user has sufficient ask amount
        if(!(msg.value == price)) revert INSUFFICIENT_ASK_PRICE(sender,e.eventParams.name);
        //check tickets availability
        if(!(ticketNumber < e.eventParams.availableTickets)) revert TICKETS_UNAVAILABLE(e.eventParams.name);
       
        Ticket memory newTicket = Ticket(sender,eventID,ticketNumber,price,false,qrCode,ticketType);
        EventParticipants[eventID][ticketNumber] = newTicket;
        totalEventParticipants[eventID] +=1;
        IsParticipant[sender][eventID] = true;
        e.nft.mintSoulBound(sender,qrCode);
        emit TicketPurchased (e.eventParams.name,ticketNumber);
    }

    /**
    *@dev Upcoming Events
    *@notice Upcoming Events shows all events that are available
    *@return - Events[] - list of upcomming events
    */
    function upcomingEvents () public view returns(Event[] memory){
        Event[] memory e = new Event[](eventCounter);
        uint256 index = 0;
        for(uint i=0;i<eventCounter;){
            if(EventMap[i].eventParams.endDate > block.timestamp){
                e[index] = EventMap[i];
                index++;
            }
            i++;
        }
        return e;
    }
     /**
    *@dev Past Events
    *@notice Past Events shows all events that are unavailable
    *@return - Events[] - list of past events
    */
    function pastEvents () public view returns(Event[] memory){
        Event[] memory e = new Event[](eventCounter);
        uint256 index = 0;
        for(uint i=0;i<eventCounter;){
            if(EventMap[i].eventParams.endDate < block.timestamp){
                e[index] = EventMap[i];
                index++;
            }
            i++;
        }
        return e;
    }
    /**
    *@dev Get single event corresponding to the event ID
    *@param eventID - ID of the event to be returned
    */
    function getEvent(uint256 eventID) public view returns(Event memory){
        return EventMap[eventID];
    }

    /**
    *@dev Verify tickets
    *@notice Function to verify tickets for an event
    *@param ticket - Ticket to be verified
    */ 
    function verifyTickets (Ticket calldata ticket) public{
        //ensure that event is available
        Event memory e = EventMap[ticket.eventID]; 
        if(block.timestamp>e.eventParams.endDate){
            revert EVENT_EXPIRED_NOT_AVAILABLE(ticket.eventID,e.eventParams.name);
        }
        if(block.timestamp<e.eventParams.startDate){
            revert EVENT_NOT_STARTED(ticket.eventID,e.eventParams.name);
        }
        Ticket storage participantAccess = EventParticipants[ticket.eventID][ticket.ticketNumber];
        if(participantAccess.isVerified) revert TICKET_ALREADY_VERIFIED(participantAccess.ticketNumber,e.eventParams.name);
        participantAccess.isVerified = true;
        //TODO: mint poap to ticket owner
        emit TicketVerified(ticket.eventID,e.eventParams.name,participantAccess.ticketNumber);
    }

    //================== Admin Functions ==================

     /**
    *@dev Onboard entity
    *@notice Onboard entity is an administrator function that is responsible for onboarding users into the protocol after a valid polygon ID proof has been verified. This takes a verified entity information and records it in the protocol database(RegisteredEntities). When an entitity has been successfully registered an OnboardSuccess event is emitted with an indexed name, address and role information of the entity.
    *@param entity - (entity structure)
    */
    function onboardEntity(Entity memory entity) public admin {
        if(RegisteredEntities[entity._address].isVerified)revert ALREADY_REGISTERED_ENTITY(entity._address);
        Entity memory e = Entity(entity.name,entity._address,entity.proof,entity.isVerified,entity.role);
        RegisteredEntities[entity._address] = e;
        emit OnboardSuccess(entity.name,entity._address, entity.role);
    }

    /**
    *@dev Check entity registration
    *@param _entity - address of the entity to check registration details for
    */ 

    function checkRegistration(address _entity) public view returns(Entity memory){
        return RegisteredEntities[_entity];
    }
    /**
    *@dev Onboard Admin
    *@notice Onboard Admin is an administrative function that is responsible for onboarding admin users/entities into the protocol. This takes an admin address and records it in the protocol admin database (Admin).
    *@param  _admin - (new admin address)
    */
    function onboardAdmin(address _admin) public admin {
       Admin[_admin] = true;
    }

    /**
    *@dev Remit organizers of events after ticket sales
    *@notice Remit Organizers is an administrative function that is responsible for remitting arcued revenue from purchased tickets of an event when the event ticket sales period is over. This takes the event ID as a parameter and emits a RemittedOrganizer event on successful remitting.
    *@param  eventID - (ID of the Event )
    */

    function remitOrganizers(uint256 eventID) public admin {
        Event memory e = EventMap[eventID];
        //Calculate amount realized for event ticket sales
        uint256 amountRealized = reducer(eventID); // this can be considered potential not gas efficient-- possible of-chain considerations
        uint256 valueAfterFees = amountRealized - ((protocolFees * amountRealized)/100);
        //check that period of ticket sales is over
        if(!(block.timestamp >= e.eventParams.endDate)) revert TICKET_SALES_ACTIVE(eventID,e.eventParams.name);
        //check that protocol has enough balance
        if(!(address(this).balance > valueAfterFees)) revert INSUFFICIENT_BALANCE(eventID,e.eventParams.name);
        payable(e.eventParams.organization._address).transfer(valueAfterFees);
        emit RemittedOrganizer(e.eventParams.organization.name,e.eventParams.organization._address,valueAfterFees);
    }

    receive() external payable {}

    //============== Internal functions ================
    /**
    *@dev Ticket Reducer: This function sums up the ticket prices in a array and returns the result
    */
    function reducer(uint256 eventID) internal view returns (uint256) {
        uint256 arrLength = totalEventParticipants[eventID];
        
        uint256 result = 0;
        for (uint256 i = 0; i < arrLength; i++) {
            Ticket memory ticket = EventParticipants[eventID][i];
            result += ticket.price;
        }
        return result;
    }
}

//["code camp","cole work oo","ikot abasi","https://github.com/sancrystal/image.png",50,1222334455,1222334459,[3,5,10],2,["pampam","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x72e29f32a0cccb4e4fec467368096fe80c5971c5c92c0fe4be3aa41abce12531",true,0]]
//register entity organization ["santacodes","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x9abe48fc59a1b5328811ce50e7ab0260803dc31aefdde3ef42dd052105e7f063",true,0]