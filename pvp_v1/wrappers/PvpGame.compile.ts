import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/pvp_game.tact',
    options: {
        debug: true,
    },
};
