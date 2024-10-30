import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/pvp_rewarding_pool.tact',
    options: {
        debug: true,
    },
};
