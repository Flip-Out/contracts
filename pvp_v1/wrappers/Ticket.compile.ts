import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/ticket.tact',
    options: {
        debug: true,
    },
};
