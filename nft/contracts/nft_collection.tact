import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "./nft_royalty.tact";
import "./nft_item.tact";

const NFT_COLLECTION_MIN_BALANCE: Int = ton("0.02");
const NFT_COLLECTION_GAS_CONSUMPTION: Int = ton("0.02");

contract NftCollection with Deployable, Ownable, NftRoyalty {

    owner: Address;
    next_item_index: Int as uint256;
    collection_content: Cell;
    royalty_destination: Address;
    numerator: Int as uint16;
    denominator: Int as uint16;

    init(owner: Address, collection_content: Cell, royalty_destination: Address, numerator: Int, denominator: Int) {
        self.next_item_index = 0;
        self.owner = owner;
        self.collection_content = collection_content;
        self.royalty_destination = royalty_destination;
        self.numerator = numerator;
        self.denominator = denominator;
    }

    receive(msg: MintRequest) {
        self.requireOwner();
        
        let ctx: Context = context();
        let msgValue = self.msgValue(ctx.value);

        self.mint(sender(), msg, msgValue);
    }

    fun mint(sender: Address, msg: MintRequest, msgValue: Int) {
        require(self.next_item_index >= 0, "Non-sequential NFT");
        let nft_init: StateInit = initOf NftItem(myAddress(), msg.index);
        let nft_address: Address = contractAddress(nft_init);

        send(SendParameters{
            to: nft_address,
            value: msgValue,
            mode: SendIgnoreErrors,
            bounce: false,
            data: nft_init.data,
            code: nft_init.code,
            body: Mint{
                index: msg.index,
                owner: msg.owner,
                content: msg.content,
                royalty_destination: self.royalty_destination,
                numerator: self.numerator,
                denominator: self.denominator
            }.toCell()
        });

        if (msg.index == self.next_item_index) {
            self.next_item_index += 1;
        }
    }

    get fun get_collection_data(): CollectionData {
        return CollectionData{
            next_item_index: self.next_item_index,
            content: self.collection_content,
            owner: self.owner
        };
    }

    get fun get_nft_address_by_index(item_index: Int): Address {
        return contractAddress(initOf NftItem(myAddress(), item_index));
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        return individual_content;
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = NFT_COLLECTION_MIN_BALANCE - min(tonBalanceBeforeMsg, NFT_COLLECTION_MIN_BALANCE);
        return value - (storageFee + NFT_COLLECTION_GAS_CONSUMPTION);
    }
}
