import { toNano } from '@ton/core';
import { PvpGame } from '../wrappers/PvpGame';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const pvpGame = provider.open(await PvpGame.fromInit());

    await pvpGame.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(pvpGame.address);

    // run methods on `pvpGame`
}
