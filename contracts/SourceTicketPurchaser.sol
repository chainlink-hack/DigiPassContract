// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
//===========================IMPORTS================================================================
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/token/ERC20/IERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {Withdraw} from "./Withdraw.sol";
import "./enums.sol";


contract SourceTicketPurchase is Withdraw {
    enum PayFeesIn {
        Native,
        LINK
    }

    address immutable i_router;
    address immutable i_link;
    address immutable defaultToken;

    event MessageSent(bytes32 messageId);

    constructor(address router, address link,address _defaultToken) {//_defaultToken ccip-bnm
        i_router = router;
        i_link = link;
        defaultToken = _defaultToken;
        LinkTokenInterface(i_link).approve(i_router, type(uint256).max);
        IERC20(defaultToken).approve(i_router, type(uint256).max);
    }

    receive() external payable {}

    function purchaseTicket(
        uint64 destinationChainSelector,
        uint256 eventID,
        uint256 amount,
        TicketType typeEvent,
        address sender,
        address receiver,
        address token,
        string memory qrCode
    ) external {
        IERC20(token).transferFrom(msg.sender,address(this),amount);
        // Compose the EVMTokenAmountStruct. This struct describes the tokens being transferred using CCIP.
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({token: token, amount: amount});
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = tokenAmount;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encodeWithSignature("purchaseTicketCrossChain(address ,uint256,string,TicketType)",sender, eventID,qrCode,typeEvent),
            tokenAmounts: tokenAmounts,
            extraArgs: "",
            feeToken: address(0)
        });

        uint256 fee = IRouterClient(i_router).getFee(
            destinationChainSelector,
            message
        );

        bytes32 messageId;

        messageId = IRouterClient(i_router).ccipSend{value: fee }(
            destinationChainSelector,
            message
        );


        emit MessageSent(messageId);
    }
}






//sender 0xa620Ba8bEFa099D0b315b64541e771387a3926a9
//router plygon selector 12532609583862916517
//router polygon 0x70499c328e1e2a3c41108bd3730f6670a44595d1
//router sepolia 0xd0daae2231e9cb96b94c8512223533293c3693bf
//link token sepolia 0x779877A7B0D9E8603169DdbD7836e478b4624789
//default token purchaser sepolia ccip-bnm 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05
//source sepolia 0x6066D7a2B2467c165Cfd6B214B340319B0686994