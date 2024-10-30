import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";

contract PvpGame with Deployable, Ownable {

    const MIN_BALANCE: Int = ton("0.02");
    const GAS_CONSUMPTION: Int = ton("0.02");

    id: String;
    owner: Address;
    player1: Player?;
    player2: Player?;
    playersVerified: Int as uint8;

    gameBet: Int as coins;
    rewardingPool: Address;
    
    init(owner: Address, gameBet: Int, id: String, rewardingPool: Address) {
        self.id = id;
        self.owner = owner;
        self.gameBet = gameBet;
        self.playersVerified = 0;
        self.rewardingPool = rewardingPool;
    }

    receive(msg: GameResult) {
        self.requireOwner();
        require(self.playersVerified == 2, "Not all users are verified");
        require(self.player1!!.address == msg.winner_address || self.player2!!.address == msg.winner_address, "Winner address not valid");
    
        send(SendParameters{
            to: self.rewardingPool,
            value: ton("0.014"), // 0.012
            mode: SendIgnoreErrors,
            body: RewardPlayer{
                amount: self.gameBet,
                player: msg.winner_address,
                pvp_id: self.id
            }.toCell()
        });

        if (self.player1!!.address != msg.winner_address) {
            self.burnTicket(self.player1!!.ticket);
            // self.upgrageTicket(self.player2!!.ticket);
        } else if (self.player2!!.address != msg.winner_address) {
            self.burnTicket(self.player2!!.ticket);
            // self.upgrageTicket(self.player1!!.ticket);
        }

        self.player1 = null;
        self.player2 = null;
        self.playersVerified = 0;
    }

    receive(msg: ClearGame) {
        self.requireOwner();
        require(
            (self.player1 != null && (self.player1!!.verificationStatus == "PENDING" || self.player1!!.verificationStatus == "FAILED")) || 
            (self.player2 != null && (self.player2!!.verificationStatus == "PENDING" || self.player2!!.verificationStatus == "FAILED")), 
            "This game can't be cleared");

        self.player1 = null;
        self.player2 = null;
        self.playersVerified = 0;
    }

    receive(msg: CheckTicketSuccess) {
        if (self.player1 != null && msg.ticket_owner == self.player1!!.address) {
            self.player1 = Player{
                address: msg.ticket_owner,
                verificationStatus: "SUCCESS",
                ticket: self.player1!!.ticket
            };
            self.playersVerified += 1;
        } else if (msg.ticket_owner == self.player2!!.address) {
            self.player2 = Player{
                address: msg.ticket_owner,
                verificationStatus: "SUCCESS",
                ticket: self.player2!!.ticket
            };
            self.playersVerified += 1;
        }
    }

    receive(msg: ChangeTicketAttempt) {
        self.requireOwner();
        require(self.player1 != null && self.player2 != null, "Game is empty");
        require(msg.player == self.player1!!.address || msg.player == self.player2!!.address, "Player not found");
        require(self.change_ticket_attempt_verification(msg), "Can't change player ticket");

        if (msg.player == self.player1!!.address) {
            self.player1 = Player{
                address: self.player1!!.address,
                verificationStatus: "PENDING",
                ticket: msg.ticket
            }
        } else if (msg.player == self.player2!!.address) {
            self.player2 = Player{
                address: self.player2!!.address,
                verificationStatus: "PENDING",
                ticket: msg.ticket
            }
        }

        send(SendParameters{
            to: msg.ticket,
            value: ton("0.02"),
            mode: SendIgnoreErrors,
            body: CheckTicketOwner{
                ticket_owner: msg.player,
                pvp_id: self.id,
            }.toCell()
        });
    }

    receive(msg: CreateGame) {
        let ctx: Context = context();
        self.requireOwner();
        require(self.playersVerified == 0, "Game is already started");
        require(self.player1 == null && self.player2 == null, "This game contract is occupied");

        self.player1 = Player{
            address: msg.player1,
            verificationStatus: "PENDING",
            ticket: msg.player1Ticket
        };
        self.player2 = Player{
            address: msg.player2,
            verificationStatus: "PENDING",
            ticket: msg.player2Ticket
        };

        send(SendParameters{
            to: msg.player1Ticket,
            value: ton("0.02"),
            mode: SendIgnoreErrors,
            body: CheckTicketOwner{
                ticket_owner: msg.player1,
                pvp_id: self.id,
            }.toCell()
        });

        send(SendParameters{
            to: msg.player2Ticket,
            value: ton("0.02"),
            mode: SendIgnoreErrors,
            body: CheckTicketOwner{
                ticket_owner: msg.player2,
                pvp_id: self.id,
            }.toCell()
        });
    }

    bounced(msg: bounced<CheckTicketOwner>) {
        if (self.player1 != null && self.player1!!.verificationStatus == "PENDING") {
            self.player1 = Player{
                address: self.player1!!.address,
                verificationStatus: "FAILED",
                ticket: self.player1!!.ticket
            };
        } else if (self.player2 != null && self.player2!!.verificationStatus == "PENDING") {
            self.player2 = Player{
                address: self.player2!!.address,
                verificationStatus: "FAILED",
                ticket: self.player2!!.ticket
            };
        }
    }

    fun burnTicket(ticket: Address) {
        send(SendParameters{
            to: ticket,
            value: ton("0.008"),
            mode: SendIgnoreErrors,
            body: BurnTicket{
                game_bet: self.gameBet,
                pvp_id: self.id
            }.toCell()
        });
    }

    // fun upgrageTicket(ticket: Address) {
    //     send(SendParameters{
    //         to: ticket,
    //         value: ton("0.01"),
    //         mode: SendIgnoreErrors,
    //         body: UpgrageTicket{
    //             game_bet: self.gameBet,
    //             pvp_id: self.id
    //         }.toCell()
    //     })
    // }

    fun change_ticket_attempt_verification(msg: ChangeTicketAttempt): Bool {
        if (msg.player == self.player1!!.address && self.player1!!.verificationStatus == "FAILED") {
            return true;
        } else if (msg.player == self.player2!!.address && self.player2!!.verificationStatus == "FAILED") {
            return true;
        }

        return false;
    }

    get fun get_id(): String {
        return self.id;
    }

    get fun is_available(): Bool {
        if (self.player1 == null && self.player2 == null) {
            return true;
        } else {
            return false;
        }
    }

    get fun is_game_started(): Bool {
        return self.playersVerified == 2;
    }

    get fun get_verified_players(): Int {
        return self.playersVerified;
    }

    get fun get_verification_result(): VerificationResult {
        return VerificationResult{
            player1VerificationStatus: self.player1!!.verificationStatus,
            player2VerificaitonStatus: self.player2!!.verificationStatus
        };
    }
}
