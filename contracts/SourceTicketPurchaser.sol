// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
//===========================IMPORTS================================================================
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/shared/interfaces/LinkTokenInterface.sol";
import {IERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/contracts/token/ERC20/IERC20.sol";
import {IRouterClient} from "@chainlink/contracts-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {Client} from "@chainlink/contracts-ccip/src/v0.8/ccip/libraries/Client.sol";
import {Withdraw} from "./Withdraw.sol";
import "./enums.sol";


contract SourceTicketPurchase is Withdraw {
    enum PayFeesIn {
        Native,
        LINK
    }
    uint256 private callGasLimit = 400000;
    IRouterClient private i_router;
    IERC20 private i_link;
    IERC20 private  defaultToken;

    event MessageSent(bytes32 messageId);
    error NotEnoughBalance(uint256 balance, uint256 amount);

    constructor(address router, address link,address _defaultToken) {//_defaultToken ccip-bnm
        i_router = IRouterClient(router);
        i_link = IERC20(link);
        defaultToken = IERC20(_defaultToken);
        IERC20(i_link).approve(router, type(uint256).max);
        IERC20(defaultToken).approve(router, type(uint256).max);
    }

    receive() external payable {}

    function purchaseTicket(
        uint64 destinationChainSelector,
        uint256 eventID,
        uint256 amount,
        TicketType ticketType,
        address sender,
        address receiver,
        address token,
        string memory qrCode

    ) external {
        {
            bool success = IERC20(token).transferFrom(msg.sender,address(this),amount);
            require(success,"FUNDING_CONTRACT_FAILED");
        }
        // Compose the EVMTokenAmountStruct. This struct describes the tokens being transferred using CCIP.
        Client.EVMTokenAmount memory tokenAmount = Client.EVMTokenAmount({token: token, amount: amount});
        Client.EVMTokenAmount[] memory tokenAmounts = new Client.EVMTokenAmount[](1);
        tokenAmounts[0] = tokenAmount;

        Client.EVM2AnyMessage memory message = Client.EVM2AnyMessage({
            receiver: abi.encode(receiver),
            data: abi.encode(sender, eventID,qrCode,ticketType),
            tokenAmounts: tokenAmounts,
            extraArgs:Client._argsToBytes(
                Client.EVMExtraArgsV1({gasLimit:callGasLimit})
            ),// Additional arguments, setting gas limit and non-strict sequency mode
            feeToken: address(0)
        });

        uint256 fee = i_router.getFee(
            destinationChainSelector,
            message
        );
        
        if (fee > address(this).balance)
            revert NotEnoughBalance(address(this).balance, fee);

        IERC20(token).approve(address(i_router), amount);

        bytes32 messageId = IRouterClient(i_router).ccipSend{value: fee }(
            destinationChainSelector,
            message
        );
        

        emit MessageSent(messageId);
    }

    function updateGas (uint gas) public{
        callGasLimit = gas; 
    }
}






//sender 0xa620Ba8bEFa099D0b315b64541e771387a3926a9
//router plygon selector 12532609583862916517
//router polygon 0x1035cabc275068e0f4b745a29cedf38e13af41b1



//router sepolia 0x0bf3de8c5d3e8a2b34d2beeb17abfcebaf363a59
//link token sepolia 0x779877A7B0D9E8603169DdbD7836e478b4624789
//default token purchaser sepolia ccip-bnm 0xFd57b4ddBf88a4e07fF4e34C487b99af2Fe82a05
//source sepolia 0x23107CFBd172eE8dD40afad286C0cF2c9e0B6757
//qrcode https://ik.imagekit.io/ub0zwxszt/chainlink.jpeg?updatedAt=1702227083852

//0x000000000000000000000000000000000000000000000000adecc60412ce25a50000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000014f75af344cb395959f880fed2b8cb418e644a9e0000000000000000000000002dff2b2ee0daca513044ccd71ecefaa07f3e3e7d000000000000000000000000fd57b4ddbf88a4e07ff4e34c487b99af2fe82a050000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000004768747470733a2f2f696b2e696d6167656b69742e696f2f7562307a7778737a742f636861696e6c696e6b2e6a7065673f7570646174656441743d3137303232323730383338353200000000000000000000000000000000000000000000000000
//0x50cbc7c8000000000000000000000000000000000000000000000000adecc60412ce25a50000000000000000000000000000000000000000000000000000000000000005000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000000000000000000000000000000000000000000200000000000000000000000014f75af344cb395959f880fed2b8cb418e644a9e0000000000000000000000002dff2b2ee0daca513044ccd71ecefaa07f3e3e7d000000000000000000000000fd57b4ddbf88a4e07ff4e34c487b99af2fe82a050000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000004768747470733a2f2f696b2e696d6167656b69742e696f2f7562307a7778737a742f636861696e6c696e6b2e6a7065673f7570646174656441743d3137303232323730383338353200000000000000000000000000000000000000000000000000