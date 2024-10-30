import { toNano } from '@ton/core';
import { PvpRewardingPool } from '../wrappers/PvpRewardingPool';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const pvpRewardingPool = provider.open(await PvpRewardingPool.fromInit());

    await pvpRewardingPool.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(pvpRewardingPool.address);

    // run methods on `pvpRewardingPool`
}
