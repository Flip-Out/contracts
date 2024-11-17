import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { Game } from '../wrappers/Game';
import '@ton/test-utils';
import { Balance } from '../wrappers/Balance';

describe('Game', () => {
    let blockchain: Blockchain;

    let royalty: SandboxContract<TreasuryContract>;
    let deployer: SandboxContract<TreasuryContract>;
    let player1: SandboxContract<TreasuryContract>;
    let player2: SandboxContract<TreasuryContract>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        royalty = await blockchain.treasury('royalty');
        deployer = await blockchain.treasury('deployer');
        player1 = await blockchain.treasury('player1');
        player2 = await blockchain.treasury('player2');
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and game are ready to use
    });

    it('game', async () => {
        const deployerBalanceBefore = await deployer.getBalance();

        const balance1: SandboxContract<Balance> = blockchain.openContract(await Balance.fromInit(player1.address));
        const balance2: SandboxContract<Balance> = blockchain.openContract(await Balance.fromInit(player2.address));

        const balance1DeployTx = await balance1.send(
            player1.getSender(),
            {
                value: toNano('5')
            },
            {
                $$type: 'TopUp',
                query_id: 0n
            }
        );

        const balance2DeployTx = await balance2.send(
            player1.getSender(),
            {
                value: toNano('7')
            },
            {
                $$type: 'TopUp',
                query_id: 0n
            }
        );

        const amountBalance1 = await balance1.getBalance();
        const amountBalance2 = await balance2.getBalance();

        expect(amountBalance1).toBeGreaterThan(toNano('4.99'));
        expect(amountBalance2).toBeGreaterThan(toNano('6.99'));

        console.log('Player 1 balance before: ', await balance1.getBalance());
        console.log('Player 2 balance before: ', await balance2.getBalance());

        const game: SandboxContract<Game> = blockchain.openContract(
            await Game.fromInit(
                deployer.address,
                player1.address,
                player2.address,
                balance1.address,
                balance2.address,
                toNano('2'),
                '230e33a4-1f1f-484d-bd9d-c5b776e64dec',
                5n,
                royalty.address
            )
        );

        const gameTx = await game.send(
            deployer.getSender(),
            {
                value: toNano('0.06')
            },
            {
                $$type: 'CreateGame',
                query_id: 0n
            }
        );

        const royaltyBefore = await royalty.getBalance();
        console.log('Royalty balance before game: ', royaltyBefore);

        const gameContractBalance = await game.getBalance();
        console.log('Game contract balance', gameContractBalance);
        console.log('Game bet: ', await game.getGameBet());
        console.log('Game data: ', await game.getPlayers());

        const endGameTx = await game.send(
            deployer.getSender(),
            {
                value: toNano('0.028')
            },
            {
                $$type: 'EndGame',
                winner: player2.address
            }
        );

        const deployerBalanceAfter = await deployer.getBalance();
        console.log('Game deployer fee: ', deployerBalanceBefore - deployerBalanceAfter);

        console.log('Player 1 balance after: ', await balance1.getBalance());
        console.log('Player 2 balance after: ', await balance2.getBalance());
        console.log('Royalty balance after game: ', await royalty.getBalance());

        const amountBalance1After = await balance1.getBalance();
        const amountBalance2After = await balance2.getBalance();
        const royaltyAfter = await royalty.getBalance();

        expect(amountBalance1After - amountBalance1).toBeLessThan(toNano('-1.99'));
        expect(amountBalance1After - amountBalance1).toBeGreaterThan(toNano('-2'));
        expect(amountBalance2After - amountBalance2).toBeGreaterThan(toNano('1.89'));
        expect(amountBalance2After - amountBalance2).toBeLessThan(toNano('1.9'));
        expect(royaltyAfter - royaltyBefore).toBeGreaterThan(toNano('0.09'));
        expect(royaltyAfter - royaltyBefore).toBeLessThan(toNano('0.1'));
    });
});
