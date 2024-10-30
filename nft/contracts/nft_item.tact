import "@stdlib/deploy";
import "@stdlib/ownable";

const NFT_ITEM_MIN_BALANCE: Int = ton("0.05");
const NFT_ITEM_GAS_CONSUMPTION: Int = ton("0.02");

contract NftItem with Deployable, Ownable {
  is_initialized: Bool;
  owner: Address;
  collection: Address;
  index: Int as uint256;
  individual_content: Cell;
  royalty_destination: Address;
  numerator: Int as uint16;
  denominator: Int as uint16;

  init(collection: Address, index: Int) {
    require(sender() == collection, "Invalid Deployer");

    self.collection = collection;
    self.index = index;
    self.owner = self.collection;
    self.individual_content = emptyCell();
    self.royalty_destination = self.collection;
    self.numerator = 0;
    self.denominator = 1;
    self.is_initialized = false;
  }

  receive(msg: NftTransfer) {
    let ctx: Context = context();
    require(self.is_initialized, "Not Deployed");
    require(ctx.sender == self.owner, "Invalid Onwer");

    let tonBalanceBeforeMsg: Int = myBalance() - ctx.value;
    let storageFee: Int = NFT_ITEM_MIN_BALANCE - min(tonBalanceBeforeMsg, NFT_ITEM_MIN_BALANCE);
    let required: Int = storageFee + NFT_ITEM_GAS_CONSUMPTION + msg.forward_amount;
    if (msg.forward_amount != 0) {
      required += ctx.readForwardFee();
    }
    
    require(ctx.value >= required, "Invalid Amount");

    let cashback: Int = ctx.value - NFT_ITEM_GAS_CONSUMPTION - msg.forward_amount - storageFee;

    if (msg.forward_amount != 0) {
      cashback -= ctx.readForwardFee();
      send(SendParameters{
        to: msg.new_owner,
        value: msg.forward_amount,
        mode: SendPayGasSeparately,
        body: NftOwnershipAssigned{
          query_id: msg.query_id,
          prev_owner: self.owner,
          forward_payload: msg.forward_payload
        }.toCell()
      });
    }

    self.owner = msg.new_owner;
  
    if (cashback > 0) {
      send(SendParameters{
        to: msg.response_destination,
        value: cashback,
        body: NftExcesses{
          query_id: msg.query_id
        }.toCell()
      });
    }
  }

  receive(msg: Mint) {
    require(sender() == self.collection, "Invalid Sender");
    require(self.index == msg.index, "Invalid Index");
    require(!self.is_initialized, "Already Deployed");

    self.owner = msg.owner;
    self.individual_content = msg.content;
    self.is_initialized = true;
    self.royalty_destination = msg.royalty_destination;
    self.numerator = msg.numerator;
    self.denominator = msg.denominator;
  }

  receive(msg: NftDestroy) {
    require(sender() == self.owner || sender() == self.collection, "Invalid Destroyer");
    self.owner = myAddress();
    
    send(SendParameters{
      to: sender(),
      value: 0,
      mode: SendRemainingValue,
      body: NftExcesses{
        query_id: msg.query_id
      }.toCell()
    });
  }

  receive(msg: NftGetStaticData) {
    send(SendParameters{
      to: sender(),
      value: 0,
      mode: SendRemainingValue,
      body: NftStaticParams{
        query_id: msg.query_id,
        index: self.index,
        collection: self.collection
      }.toCell()
    });
  }

  get fun get_nft_data(): NftData {
    return NftData{
      is_initialized: self.is_initialized,
      index: self.index,
      collection: self.collection,
      owner: self.owner,
      content: self.individual_content
    };
  }
}