import "@stdlib/deploy";
import "@stdlib/ownable";
import "./messages.tact";
import "./pvp_game.tact";

contract PvpRewardingPool with Deployable, Ownable {

    const MIN_BALANCE: Int = ton("0.02");
    const GAS_CONSUMPTION: Int = ton("0.02");
   
    owner: Address;
    notRewardedPlayers: map<Address, Int as coins>;
    royaltyPercents: Int? as coins;
    accumulatedRoyalty: Int;
   
    init(owner: Address) {
        self.owner = owner;
        self.accumulatedRoyalty = 0;
    }

    receive(msg: WithdrawRoyalty) {
        self.requireOwner();
        require(myBalance() - self.MIN_BALANCE >= self.accumulatedRoyalty, "Little Balance");

        send(SendParameters{
            to: sender(),
            value: self.accumulatedRoyalty,
            mode: SendIgnoreErrors,
            body: "Withdraw Pool Royalty".asComment()
        });
    }

    receive(msg: ChangeRewardingPoolRoyalty) {
        self.requireOwner();
        self.royaltyPercents = msg.royalty_percents;
    }

    receive(msg: PvpRewardingPoolTopUp) {
        let ctx: Context = context();
        
        let msgValue: Int = ctx.value;
        foreach (key, value in self.notRewardedPlayers) {
            msgValue -= value;
            if (msgValue <= 0) {
                return;
            }

            let royaltyAmount: Int = self.royaltyPercents != null && self.royaltyPercents!! > 0
                ? (value * self.royaltyPercents!!) / 100
                : 0;
            let rewardAmount: Int = value - royaltyAmount;

            self.accumulatedRoyalty += royaltyAmount;

            send(SendParameters{
                to: key,
                value: rewardAmount,
                mode: SendIgnoreErrors,
                body: "Reward for winning the Flip Out game".asComment()
            });

            self.notRewardedPlayers.del(key);
        }
    }

    receive(msg: RewardPlayer) {
        let pvpGame = contractAddress(initOf PvpGame(self.owner, msg.amount, msg.pvp_id, myAddress()));
        require(pvpGame == sender(), "This sender don't have access to request rewards");

        let isWillBeRewarded = msg.amount <= myBalance() - self.MIN_BALANCE + self.GAS_CONSUMPTION;
        if (isWillBeRewarded == false) {
            self.notRewardedPlayers.set(msg.player, msg.amount);
        }        
        require(isWillBeRewarded, "Not enought funds");

        let royaltyAmount: Int = self.royaltyPercents != null && self.royaltyPercents!! > 0 ? (msg.amount * self.royaltyPercents!!) / 100 : 0;
        let rewardAmount: Int = msg.amount - royaltyAmount;
        self.accumulatedRoyalty += royaltyAmount;

        let rewardAmountString: String = rewardAmount.toString();

        send(SendParameters{
            to: msg.player,
            bounce: true,
            value: msg.amount,
            mode: SendIgnoreErrors,
            body: "Reward for winning the Flip Out game".asComment() // If remove comment body, we can reduce commission
        });
    }

    get fun get_not_rewarded_players(): map<Address, Int as coins> {
        return self.notRewardedPlayers;
    }

    get fun balance(): Int {
        return myBalance();
    }
}
