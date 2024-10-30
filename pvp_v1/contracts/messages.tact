struct Player {
    address: Address;
    verificationStatus: String;
    ticket: Address;
}

struct VerificationResult {
    player1VerificationStatus: String;
    player2VerificaitonStatus: String;
}

message BurnTicket {
  game_bet: Int as coins;
  pvp_id: String;
}

message UpgrageTicket{
  game_bet: Int as coins;
  pvp_id: String;
}

message WithdrawRoyalty {
  query_id: Int as uint64;
}

message ChangeRewardingPoolRoyalty {
  royalty_percents: Int as uint8;
}

message CreateGame {
  player1: Address;
  player2: Address;
  player1Ticket: Address;
  player2Ticket: Address;
}

message CheckTicketOwner {
  ticket_owner: Address;
  pvp_id: String;
}

message CheckTicketSuccess {
  ticket_owner: Address;
}

message ChangeTicketAttempt {
  player: Address;
  ticket: Address;
}

message ClearGame {
  query_id: Int as uint64;
}

message GameResult {
  winner_address: Address;
}

message RewardPlayer {
  amount: Int as coins;
  player: Address;
  pvp_id: String;
}

message PvpRewardingPoolTopUp {
  query_id: Int as uint256;
}

// NFT Tickets

message MintRequest {
    index: Int as uint256;
    owner: Address;
    content: Cell;
    game_bet: Int as coins;
}

message Mint {
    index: Int as uint256;
    owner: Address;
    content: Cell;
    royalty_destination: Address;
    numerator: Int as uint16;
    denominator: Int as uint16;
    game_bet: Int as coins;
    rewarding_pool: Address;
    original_owner: Address;
}

message(0x1f04537a) NftDestroy {
    query_id: Int as uint64;
}

message(0x6f89f5e3) NftExcesses {
    query_id: Int as uint64;
}

message(0x2fcb26a2) NftGetStaticData {
    query_id: Int as uint64;
}

message(0x8b771735) NftStaticParams {
    query_id: Int as uint64;
    index: Int as uint256;
    collection: Address;
}

message(0x5fcc3d14) NftTransfer {
    query_id: Int as uint64;
    new_owner: Address;
    response_destination: Address;
    custom_payload: Cell?;
    forward_amount: Int as coins;
    forward_payload: Slice as remaining;
}

message(0x05138d91) NftOwnershipAssigned {
    query_id: Int as uint64;
    prev_owner: Address;
    forward_payload: Slice as remaining;
}

struct CollectionData {
    next_item_index: Int as uint256;
    content: Cell;
    owner: Address;
}

struct NftData {
    is_initialized: Bool;
    index: Int;
    collection: Address;
    owner: Address;
    content: Cell;
}

// Royalty

struct NftRoyaltyParams {
    numerator: Int;
    denominator: Int;
    royalty_destination: Address;
}

message(0x693d3950) GetRoyaltyRequest {
    query_id: Int as uint64;
}

message(0xa8cb00ad) NftReportRoyaltyParams {
    query_id: Int as uint64;
    numerator: Int as uint16;
    denominator: Int as uint16;
    destination: Address;
}

message TopUpCollection {
  query_id: Int as uint256;
}
