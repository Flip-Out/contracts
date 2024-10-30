message MintRequest {
    index: Int as uint256;
    owner: Address;
    content: Cell;
}

message Mint {
    index: Int as uint256;
    owner: Address;
    content: Cell;
    royalty_destination: Address;
    numerator: Int as uint16;
    denominator: Int as uint16;
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