import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "./ticket_royalty.tact";
import "./ticket.tact";

contract TicketCollection with Deployable, Ownable, TicketRoyalty {

    const MIN_BALANCE: Int = ton("0.02");
    const GAS_CONSUMPTION: Int = ton("0.02");

    owner: Address;
    next_item_index: Int as uint256;
    collection_content: Cell;
    royalty_destination: Address;
    numerator: Int as uint16;
    denominator: Int as uint16;

    game_bet: Int as coins;
    rewarding_pool: Address;

    init(owner: Address, collection_content: Cell, royalty_destination: Address, 
         numerator: Int, denominator: Int, game_bet: Int, rewarding_pool: Address) {
        self.next_item_index = 1;
        self.owner = owner;
        self.collection_content = collection_content;
        self.royalty_destination = royalty_destination;
        self.numerator = numerator;
        self.denominator = denominator;
        self.game_bet = game_bet;
        self.rewarding_pool = rewarding_pool;
    }

    receive(msg: TopUpCollection) {
    }

    receive(msg: MintRequest) {
        self.requireOwner();
        
        let ctx: Context = context();
        let msgValue = self.msgValue(ctx.value);

        self.mint(sender(), msg, msgValue);
    }

    fun mint(sender: Address, msg: MintRequest, msgValue: Int) {
        require(self.next_item_index >= 0, "Non-sequential NFT Ticket");
        let nft_init: StateInit = initOf Ticket(myAddress(), msg.index, self.owner, self.game_bet, self.rewarding_pool);
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
                denominator: self.denominator,
                rewarding_pool: self.rewarding_pool,
                game_bet: self.game_bet,
                original_owner: self.owner
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
        return contractAddress(initOf Ticket(myAddress(), item_index, self.owner, self.game_bet, self.rewarding_pool));
    }

    get fun get_nft_content(index: Int, individual_content: Cell): Cell {
        return individual_content;
    }

    get fun get_next_item_index(): Int {
        return self.next_item_index;
    }

    fun msgValue(value: Int): Int {
        let tonBalanceBeforeMsg: Int = myBalance() - value;
        let storageFee: Int = self.MIN_BALANCE - min(tonBalanceBeforeMsg, self.MIN_BALANCE);
        
        return value - (storageFee + self.GAS_CONSUMPTION);
    }
}
