// Game

message CreateGame {
  query_id: Int as uint64;
}

message EndGame {
  winner: Address;
}

message BalanceVerification {
  balance_owner: Address;
  is_sufficient_balance: Bool;
}

// Balance

message TopUp {
  query_id: Int as uint64;
}

message CheckBalance {
  amount: Int as coins;
}

message PayDefeat {
  winner: Address;
  game_owner: Address;
  player1: Address;
  balance1: Address;
  player2: Address;
  balance2: Address;
  amount: Int as coins;
  id: String;
}

message Withdraw {
  amount: Int as coins;
}