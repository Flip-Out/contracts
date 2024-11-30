import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";

struct Player {
    address: Address;
    balance: Address;
    balance_check_status: String;
}

struct Players {
    player1: Player;
    player2: Player;
}

const MIN_BALANCE: Int = ton("0.01");
const GAS_CONSUMPTION: Int = ton("0.01");

contract Game with Deployable, Ownable {
    
    id: String;
    owner: Address;
    player1: Player;
    player2: Player;
    game_bet: Int as coins;
    royalty_percent: Int;
    royalty_destination: Address;

    init(owner: Address, player1: Address, player2: Address, balance1: Address, balance2: Address, game_bet: Int, id: String, royalty_percent: Int, royalty_destination: Address) {
        self.id = id;
        self.owner = owner;
        self.game_bet = game_bet;
        self.royalty_percent = royalty_percent;
        self.royalty_destination = royalty_destination;
        self.player1 = Player{
            address: player1,
            balance: balance1,
            balance_check_status: "NOT_STARTED"
        };
        self.player2 = Player{
            address: player2,
            balance: balance2,
            balance_check_status: "NOT_STARTED"
        };
    }

    receive(msg: EndGame) {
        self.requireOwner();
        let ctx: Context = context();

        require(ctx.value >= ctx.readForwardFee() + GAS_CONSUMPTION + ton("0.005"), "Invalid TON amount");
        require(msg.winner == self.player1.address || msg.winner == self.player2.address, "Winner address invalid");
        require(self.player1.balance_check_status == "SUCCESS" && self.player2.balance_check_status == "SUCCESS", "Not validated players");

        if (self.player1.address == msg.winner) {
            send(SendParameters{
                to: self.player2.balance,
                value: 0,
                mode: SendIgnoreErrors + SendRemainingValue,
                body: PayDefeat{
                    game_owner: self.owner,
                    winner: self.player1.balance,
                    player1: self.player1.address,
                    balance1: self.player1.balance,
                    player2: self.player2.address,
                    balance2: self.player2.balance,
                    amount: self.game_bet,
                    id: self.id,
                    royalty_percent: self.royalty_percent,
                    royalty_destination: self.royalty_destination
                }.toCell()
            });
        } else if (self.player2.address == msg.winner) {
            send(SendParameters{
                to: self.player1.balance,
                value: 0,
                mode: SendIgnoreErrors + SendRemainingValue,
                body: PayDefeat{
                    game_owner: self.owner,
                    winner: self.player2.balance,
                    player1: self.player1.address,
                    balance1: self.player1.balance,
                    player2: self.player2.address,
                    balance2: self.player2.balance,
                    amount: self.game_bet,
                    id: self.id,
                    royalty_percent: self.royalty_percent,
                    royalty_destination: self.royalty_destination
                }.toCell()
            });
        }

        send(SendParameters{
            to: self.owner,
            value: 0,
            mode: SendRemainingBalance + SendDestroyIfZero
        });
    }

    receive(msg: CreateGame) {
        self.requireOwner();
        let ctx: Context = context();
        require(ctx.value >= (2 * GAS_CONSUMPTION) + (2 * ctx.readForwardFee()) + MIN_BALANCE, "Invalid TON amount");
        require(self.player1.balance_check_status != "SUCCESS" && self.player2.balance_check_status != "SUCCESS", "Game already created");

        send(SendParameters{
            to: self.player1.balance,
            value: ton("0.012"),
            body: CheckBalance{
                available_amount: self.game_bet,
                game_owner: self.owner,
                player1: self.player1.address,
                balance1: self.player1.balance,
                player2: self.player2.address,
                balance2: self.player2.balance,
                amount: self.game_bet,
                id: self.id,
                royalty_percent: self.royalty_percent,
                royalty_destination: self.royalty_destination
            }.toCell()
        });

        send(SendParameters{
            to: self.player2.balance,
            value: ton("0.012"),
            body: CheckBalance{
                available_amount: self.game_bet,
                game_owner: self.owner,
                player1: self.player1.address,
                balance1: self.player1.balance,
                player2: self.player2.address,
                balance2: self.player2.balance,
                amount: self.game_bet,
                id: self.id,
                royalty_percent: self.royalty_percent,
                royalty_destination: self.royalty_destination
            }.toCell()
        });

        self.player1 = Player{
            address: self.player1.address,
            balance: self.player1.balance,
            balance_check_status: "IN_PROGRESS"
        };

        self.player2 = Player{
            address: self.player2.address,
            balance: self.player2.balance,
            balance_check_status: "IN_PROGRESS"
        };
    }

    receive(msg: BalanceVerification) {
        require(self.player1.balance == sender() || self.player2.balance == sender(), "Not valid sender");

        let status = msg.is_sufficient_balance ? "SUCCESS" : "FAILED";
        if (self.player1.address == msg.balance_owner) {
            self.player1 = Player{
                address: self.player1.address,
                balance: self.player1.balance,
                balance_check_status: status
            };
        } else if (self.player2.address == msg.balance_owner) {
            self.player2 = Player{
                address: self.player2.address,
                balance: self.player2.balance,
                balance_check_status: status
            };
        }
    }

    get fun verified_players(): Int {
        let verified_players_count: Int = 0;

        if (self.player1.balance_check_status == "SUCCESS") {
            verified_players_count += 1;
        }
        if (self.player2.balance_check_status == "SUCCESS") {
            verified_players_count += 1;
        }

        return verified_players_count;
    }

    get fun players(): Players {
        return Players{
            player1: self.player1,
            player2: self.player2
        };
    }

    get fun id(): String {
        return self.id;
    }

    get fun game_bet(): Int {
        return self.game_bet;
    }

    get fun balance(): Int {
        return myBalance();
    }
}
