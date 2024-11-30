import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "./game.tact";

contract Balance with Deployable, Ownable {
    
    owner: Address;
    isLocked: Bool;
    lockerAddress: Address?;
    lockTime: Int?;

    init(owner: Address) {
        self.owner = owner;
        self.isLocked = false;
    }

    receive(msg: TopUp) {
        self.unlockBalance();
    }

    receive(msg: CheckBalance) {
        self.unlockBalance();
        let ctx: Context = context();
        require(ctx.value >= GAS_CONSUMPTION + ctx.readForwardFee(), "Invalid TON amount");

        let game: Address = contractAddress(initOf Game(msg.game_owner, msg.player1, msg.player2, msg.balance1, msg.balance2, msg.amount, msg.id, msg.royalty_percent, msg.royalty_destination));
        require(sender() == game, "Not valid sender");

        let isSufficientBalance: Bool = (myBalance() - msg.available_amount - MIN_BALANCE) >= 0;

        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: BalanceVerification{
                balance_owner: self.owner,
                is_sufficient_balance: isSufficientBalance && self.isLocked == false
            }.toCell()
        });

        if (isSufficientBalance && self.isLocked == false) {
            self.isLocked = true;
            self.lockerAddress = game;
            self.lockTime = now();
        }
    }

    receive(msg: PayDefeat) {
        let ctx: Context = context();
        require(ctx.value >= GAS_CONSUMPTION + ctx.readForwardFee(), "Invalid TON amount");
        require(myBalance() >= MIN_BALANCE + msg.amount, "Not sufficient balance");
        require((self.owner == msg.player1 || self.owner == msg.player2) && self.owner != msg.winner, "Not correct balance");

        let game: Address = contractAddress(initOf Game(msg.game_owner, msg.player1, msg.player2, msg.balance1, msg.balance2, msg.amount, msg.id, msg.royalty_percent, msg.royalty_destination));

        require(self.lockerAddress == game, "Balance locked another game");

        require(sender() == game, "Invalid sender");

        let royaltyAmount: Int = min(msg.amount, (msg.amount * msg.royalty_percent) / 100);
        let winnerAmount: Int = msg.amount - royaltyAmount;

        send(SendParameters{
            to: msg.winner,
            value: winnerAmount,
            mode: SendIgnoreErrors,
            body: TopUp{
                query_id: 0
            }.toCell()
        });

        send(SendParameters{
            to: msg.royalty_destination,
            value: royaltyAmount,
            mode: SendIgnoreErrors
        });

        self.isLocked = false;
        self.lockerAddress = null;
        self.lockTime = null;
    }

    receive(msg: Withdraw) {
        self.requireOwner();
        self.unlockBalance();
        let ctx: Context = context();
        require(ctx.value >= ctx.readForwardFee() - GAS_CONSUMPTION, "Amount of TON invalid");
        require(msg.amount <= myBalance() - MIN_BALANCE, "Not enough funds");

        send(SendParameters{
            to: self.owner,
            value: msg.amount,
            mode: SendIgnoreErrors,
            body: "Withdrawing funds from the Flip Out game".asComment()
        });
    }

    fun unlockBalance() {
        if (self.isLocked && self.lockTime != null && now() - self.lockTime!! >= 30 * 60) {
            self.isLocked = false;
            self.lockerAddress = null;
            self.lockTime = null;
        }
    }

    get fun balance(): Int {
        return myBalance();
    }
}
