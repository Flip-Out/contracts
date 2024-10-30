import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/ticket_collection.tact',
    options: {
        debug: true,
    },
};
