import { toNano } from '@ton/core';
import { TicketCollection } from '../wrappers/TicketCollection';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const ticketCollection = provider.open(await TicketCollection.fromInit());

    await ticketCollection.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(ticketCollection.address);

    // run methods on `ticketCollection`
}
