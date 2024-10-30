import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "./game.tact";

contract Balance with Deployable, Ownable {
    
    owner: Address;
    
    init(owner: Address) {
        self.owner = owner;
    }

    receive(msg: TopUp) {
    }

    receive(msg: CheckBalance) {
        let ctx: Context = context();
        require(ctx.value >= GAS_CONSUMPTION + ctx.readForwardFee(), "Invalid TON amount");

        let isSufficientBalance: Bool = (myBalance() - msg.amount - MIN_BALANCE) >= 0;

        send(SendParameters{
            to: sender(),
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: BalanceVerification{
                balance_owner: self.owner,
                is_sufficient_balance: isSufficientBalance
            }.toCell()
        });
    }

    receive(msg: PayDefeat) {
        let ctx: Context = context();
        require(ctx.value >= GAS_CONSUMPTION + ctx.readForwardFee(), "Invalid TON amount");
        require(myBalance() >= MIN_BALANCE + msg.amount, "Not sufficient balance");
        require((self.owner == msg.player1 || self.owner == msg.player2) && self.owner != msg.winner, "Not correct balance");

        let game: Address = contractAddress(initOf Game(msg.game_owner, msg.player1, msg.player2, msg.balance1, msg.balance2, msg.amount, msg.id));
        require(sender() == game, "Invalid sender");

        send(SendParameters{
            to: msg.winner,
            value: msg.amount,
            mode: SendIgnoreErrors,
            body: TopUp{
                query_id: 0
            }.toCell()
        });
    }

    receive(msg: Withdraw) {
        self.requireOwner();
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

    get fun balance(): Int {
        return myBalance();
    }
}
