//SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.19;

// ============ Imports ============
import "./enums.sol";
import "contracts/soulboundNFTSample.sol";
//============== Structures ============

/*
*@dev Structure of Entity Registered into Detick
*/
struct Entity{
    string name;
    address _address;
    bytes proof; //polygon id proof.                                                                                                                                     
    bool isVerified;
    Role role;
}

/*
*@dev Structure of Tickets
*/
struct Ticket{
    address owner;
    uint256 eventID;
    uint256 ticketNumber;
    uint256 price;
    TicketType ticketType;
}

/*
*@dev Structure of Prices
*/
struct Prices {
    uint256 regular;
    uint256 vip;
    uint256 vvip;
}
/*
*@dev Structure of Events
*/

struct Event{
    string name;
    string venue;
    string location;
    string imageUrl;
    uint256 availableTickets;
    uint256 date;
    SoulBoundNFT nft;
    Prices price;
    Categories category;
    Entity organization;
}

contract DeTick {
    /*
    *@dev protocolFees
    */
    uint256 immutable protocolFees = 4; //4% of total sold tickets
    string baseURI ;
    /*
    *@dev event counter
    */
    uint256 eventCounter = 0;
    /*
    *@dev mapping of event IDs to participants addresses
    */
    mapping (uint256=>Ticket[]) private EventEntities;
    /*
    *@dev mapping of event IDs to events
    */
    mapping (uint256=>Event) private EventMap;
    /*
    *@dev mapping of address of register entities to Entity
    */
    mapping (address => Entity) private RegisteredEntities;

    /*
    *@dev admin mapping and modifier
    */
    mapping(address => bool) private Admin;
    modifier admin (){
        require(Admin[msg.sender],"Unauthorized Access");
        _;
    }


    //============= Events =====================
    event CreateEvent(string indexed name , string indexed venue);
    event TicketPurchased(string indexed name , uint indexed ticketNUmber);
    event OnboardSuccess(string indexed name, address indexed entity, Role indexed role);
    event RemittedOrgnizer(string indexed name, address indexed organization, uint indexed valueAfterFees);

    constructor(string memory _baseURI){
        //initialize sender as admin
        Admin[msg.sender] = true;
        baseURI = _baseURI;
    }

    /*
    *@dev create Event
    *@params - _event - (event structure)
    */

    function createEvent (Event calldata _event,string memory organizationSymbol) public {
        //require creator/caller is an ORGANIZATION
        require(RegisteredEntities[msg.sender].role == Role.ORGANIZATION,"ORGANIZER_ACCESS_REQUIRED");
        SoulBoundNFT nft = new SoulBoundNFT(msg.sender,_event.organization.name,baseURI,organizationSymbol);
        Event memory newEvent = Event(_event.name,_event.venue,_event.location,_event.imageUrl,_event.availableTickets,_event.date,nft,_event.price,_event.category,_event.organization);
        EventMap[eventCounter] = newEvent;
        //Bind soulbound token creation to event
        eventCounter++;
        emit CreateEvent (newEvent.name,newEvent.venue);
    }

    /*
    *@dev Purchase Event Tickets
    *@params - eventID - (event ID)
    *@params - ticketType - (Type of ticket) regular|vip|vvip
    */

    function purchaseTicket (uint256 eventID,TicketType ticketType) public payable{
        //require that ticket buyer is a registered
        require(RegisteredEntities[msg.sender].role == Role.PARTICIPANT);
        Event memory e = EventMap[eventID];
        uint price = TicketType.REGULAR == ticketType? e.price.regular:TicketType.VIP == ticketType?e.price.vip:e.price.vvip;
        Ticket[] storage entities = EventEntities[eventID];
        uint ticketNumber = entities.length + 1;
        //require sufficient ask amount
        require(msg.value == price, "INSUFFICIENT_ASK)_PRICE");
        //require tickets availability
        require(ticketNumber < e.availableTickets,"TICKETS_UNAVAILABLE");
       
        Ticket memory newTicket = Ticket(msg.sender,eventID,ticketNumber,price,ticketType);
        entities.push(newTicket);
        e.nft.mintSoulBound(msg.sender);
        emit TicketPurchased (e.name,ticketNumber);
    }

     /*
    *@dev Upcoming Events
    *@returns - Events[] - list of upcomming events
    */
    function upcomingEvents () public view returns(Event[] memory){
        Event[] memory e = new Event[](eventCounter);
        uint256 index = 0;
        for(uint i=0;i<eventCounter;){
            if(EventMap[i].date > block.timestamp){
                e[index] = EventMap[i];
                index++;
            }
            i++;
        }
        return e;
    }
     /*
    *@dev Past Events
    *@returns - Events[] - list of past events
    */
    function pastEvents () public view returns(Event[] memory){
        Event[] memory e = new Event[](eventCounter);
        uint256 index = 0;
        for(uint i=0;i<eventCounter;){
            if(EventMap[i].date < block.timestamp){
                e[index] = EventMap[i];
                index++;
            }
            i++;
        }
        return e;
    }

    //================== Admin Functions ==================

     /*
    *@dev Onboard entity
    *@params - entity - (entity structure)
    */

    function onboardEntity(Entity memory entity) public admin {
        Entity memory e = Entity(entity.name,entity._address,entity.proof,entity.isVerified,entity.role);
        RegisteredEntities[entity._address] = e;
        emit OnboardSuccess(entity.name,entity._address, entity.role);
    }

    /*
    *@dev Onboard Admin
    *@params - address - (new admin )
    */
    function onboardAdmin(address _admin) public admin {
       Admin[_admin] = true;
    }

    /*
    *@dev Remit organizers of events after ticket sales
    *@params - eventID - (ID of the Event )
    */

    function remitOrganizers(uint256 eventID) public admin {
        Ticket[] memory tickets = EventEntities[eventID];
        Event memory e = EventMap[eventID];
        //Calculate amount realized for event ticket sales
        uint256 amountRealized = reducer(tickets); // this can be considered potential not gas efficient-- possible of-chain considerations
        uint256 valueAfterFees = amountRealized - ((protocolFees * amountRealized)/100);

        require(address(this).balance > valueAfterFees,"INSUFFICIENT_BALANCE");
        payable(e.organization._address).transfer(valueAfterFees);
        emit RemittedOrgnizer(e.organization.name,e.organization._address,valueAfterFees);
    }

    receive() external payable {}

    //============== Internal functions ================
    function reducer(Ticket[] memory data) internal pure returns (uint256) {
        uint256 result = 0;
        for (uint256 i = 0; i < data.length; i++) {
            result += data[i].price;
        }
        return result;
    }
}

//["code camp","cole work oo","ikot abasi","https://github.com/sancrystal/image.png",50,1222334455,3,["pampam","0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x72e29f32a0cccb4e4fec467368096fe80c5971c5c92c0fe4be3aa41abce12531",true,0]]