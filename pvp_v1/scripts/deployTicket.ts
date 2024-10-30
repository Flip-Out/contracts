import { toNano } from '@ton/core';
import { Ticket } from '../wrappers/Ticket';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const ticket = provider.open(await Ticket.fromInit());

    await ticket.send(
        provider.sender(),
        {
            value: toNano('0.05'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(ticket.address);

    // run methods on `ticket`
}
