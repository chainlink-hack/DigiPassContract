// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {CCIPReceiver} from "@chainlink/contracts-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {DigiPass} from "./DigiPass.sol";

contract DestinationTicketPurchaser is CCIPReceiver {
    /**
     * @dev Contract digiPass
     * **/ 
    DigiPass digitalPass;
    //======================= EVENTS =================
    event TicketPurchaseSuccess();

    //=========================ERROR =================
    error TicketPurchaseFailure();

    constructor(address router, address payable  digitalPassAddress) CCIPReceiver(router) {
        digitalPass = DigiPass(digitalPassAddress);
    }

    function _ccipReceive(
        Client.Any2EVMMessage memory message
    ) internal override {
        (bool success, ) = address(digitalPass).call(message.data);
        if(!success) revert TicketPurchaseFailure();
        emit TicketPurchaseSuccess();
    }

}