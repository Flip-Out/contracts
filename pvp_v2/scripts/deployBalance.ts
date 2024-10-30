import { toNano } from '@ton/core';
import { Balance } from '../wrappers/Balance';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const balance = provider.open(await Balance.fromInit());

    await balance.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(balance.address);

    // run methods on `balance`
}
