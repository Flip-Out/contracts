import { toNano } from '@ton/core';
import { Game } from '../wrappers/Game';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const game = provider.open(await Game.fromInit());

    await game.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(game.address);

    // run methods on `game`
}
