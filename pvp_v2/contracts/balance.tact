import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "./game.tact";

const JETTON_TRANSFER_GAS_CONSUMPTION: Int = ton("0.04");

contract Balance with Deployable, Ownable {
    
    owner: Address;
    isLocked: Bool;
    lockerAddress: Address?;
    lockTime: Int?;
    jetton_balances: map<Address, Int>;

    init(owner: Address) {
        self.owner = owner;
        self.isLocked = false;
    }

    receive(msg: TopUp) {
        self.unlockBalance();
    }

    receive(msg: MakeBet) {
        self.requireOwner();
        let ctx: Context = context();
        require(ctx.value >= JETTON_TRANSFER_GAS_CONSUMPTION + ctx.readForwardFee(), "Invalid TON amount");

        let available_balance = self.available_jetton_balance(msg.jetton_address);
        require(available_balance >= msg.amount, "Not enough available jetton balance");

        send(SendParameters{
        to: msg.jetton_address,
        value: JETTON_TRANSFER_GAS_CONSUMPTION,
        mode: 0,
        body: beginCell()
            .storeUint(0xf8a7ea5, 32)
            .storeUint(msg.query_id, 64)
            .storeCoins(msg.amount)
            .storeAddress(msg.game_wallet_address)
            .storeAddress(myAddress())
            .storeCoins(1)
            .storeUint(0, 1)
            .endCell()
        });

        self.jetton_balances.set(msg.jetton_address, available_balance - msg.amount);
    }

    receive(msg: JettonNotify) {
        let current_balance: Int? = 0;
        if (self.jetton_balances.exists(msg.sender)) {
            current_balance = self.jetton_balances.get(msg.sender);
        }
        self.jetton_balances.set(msg.sender, current_balance!! + msg.amount);
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

    receive(msg: WithdrawJetton) {
        self.requireOwner();
        let ctx: Context = context();
        require(ctx.value >= JETTON_TRANSFER_GAS_CONSUMPTION + GAS_CONSUMPTION + ctx.readForwardFee(), "Invalid TON amount");

        let available_balance = self.available_jetton_balance(msg.jetton_address);
        require(available_balance >= msg.amount, "Not enough available jetton balance");

        send(SendParameters{
        to: msg.jetton_address,
        value: JETTON_TRANSFER_GAS_CONSUMPTION,
        mode: 0,
        body: beginCell()
            .storeUint(0xf8a7ea5, 32)
            .storeUint(msg.query_id, 64)
            .storeCoins(msg.amount)
            .storeAddress(self.owner)
            .storeAddress(myAddress())
            .storeCoins(1)
            .storeUint(0, 1)
            .endCell()
        });

        self.jetton_balances.set(msg.jetton_address, available_balance - msg.amount);
    }

    fun unlockBalance() {
        if (self.isLocked && self.lockTime != null && now() - self.lockTime!! >= HALF_HOUR) {
            self.isLocked = false;
            self.lockerAddress = null;
            self.lockTime = null;
        }
    }

    fun available_jetton_balance(jetton_wallet: Address): Int {
        let current_balance: Int? = 0;
        if (self.jetton_balances.exists(jetton_wallet)) {
            current_balance = self.jetton_balances.get(jetton_wallet);
        }
        return current_balance!!;
    }

    get fun balance(): Int {
        return myBalance();
    }

    get fun jetton_balance(jetton_wallet: Address): Int {
        let current_balance: Int? = 0;
        if (self.jetton_balances.exists(jetton_wallet)) {
            current_balance = self.jetton_balances.get(jetton_wallet);
        }
        return current_balance!!;
    }
}
