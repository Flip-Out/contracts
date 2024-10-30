import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { beginCell, Cell, Dictionary, toNano } from '@ton/core';
import '@ton/test-utils';
import { PvpRewardingPool } from '../wrappers/PvpRewardingPool';
import { TicketCollection } from '../wrappers/TicketCollection';
import { sha256_sync } from 'ton-crypto';
import { Ticket } from '../wrappers/Ticket';
import { PvpGame } from '../wrappers/PvpGame';

describe('PvpGame', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let player1: SandboxContract<TreasuryContract>;
    let player2: SandboxContract<TreasuryContract>;

    let pvpRewardingPool: SandboxContract<PvpRewardingPool>;
    let ticketCollection: SandboxContract<TicketCollection>;
    let pvpGame: SandboxContract<PvpGame>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();
        deployer = await blockchain.treasury('deployer');
        player1 = await blockchain.treasury('player1');
        player2 = await blockchain.treasury('player2');

        pvpRewardingPool = blockchain.openContract(await PvpRewardingPool.fromInit(deployer.address));

        ticketCollection = blockchain.openContract(
            await TicketCollection.fromInit(
                deployer.address,
                setItemContentCell({
                    name: 'Ticket collection',
                    description: 'Ticket collection description',
                    image: 'https://images.squarespace-cdn.com/content/v1/5336f9ebe4b00209e20806c1/1604069548152-VXQI49220L29NBADWQGM/logo.jpg',
                }),
                deployer.address,
                5n,
                100n,
                toNano('3'),
                pvpRewardingPool.address,
            ),
        );

        pvpGame = blockchain.openContract(
            await PvpGame.fromInit(
                deployer.address,
                toNano('3'),
                '52c28e2a-d34b-47cc-a056-b66de0aaf230',
                pvpRewardingPool.address,
            ),
        );

        const ticketCollectionDeployResult = await ticketCollection.send(
            deployer.getSender(),
            {
                value: toNano('0.02'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        await ticketCollection.send(
            deployer.getSender(),
            {
                value: toNano('0.04'),
            },
            {
                $$type: 'TopUpCollection',
                query_id: 0n,
            },
        );

        const pvpRewardingPoolDeployResult = await pvpRewardingPool.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        await pvpRewardingPool.send(
            deployer.getSender(),
            {
                value: toNano('100'),
            },
            {
                $$type: 'PvpRewardingPoolTopUp',
                query_id: 0n,
            },
        );

        const pvpGameDeployResult = await pvpGame.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            },
        );

        expect(ticketCollectionDeployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: ticketCollection.address,
            deploy: true,
            success: true,
        });

        expect(pvpRewardingPoolDeployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: pvpRewardingPool.address,
            deploy: true,
            success: true,
        });

        const balance = await pvpRewardingPool.getBalance();
        expect(balance).toBeGreaterThanOrEqual(toNano('99'));

        expect(pvpGameDeployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: pvpGame.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and pvpGame are ready to use
    });

    it('mint ticket', async () => {
        const nextItemIndexBefore = await ticketCollection.getGetNextItemIndex();
        expect(nextItemIndexBefore).toEqual(1n);

        const ticket1Res = await ticketCollection.send(
            deployer.getSender(),
            {
                value: toNano('0.068'),
            },
            {
                $$type: 'MintRequest',
                index: 1n,
                owner: player1.address,
                content: setItemContentCell({
                    name: 'NFT Flip Out Ticket Collection 1',
                    description: 'NFT Flip Out Ticket Collection Description 1',
                    image: 'https://img-cdn.pixlr.com/image-generator/history/65bb506dcb310754719cf81f/ede935de-1138-4f66-8ed7-44bd16efc709/medium.webp',
                }),
                game_bet: toNano('3.0'),
            },
        );

        const ticket2Res = await ticketCollection.send(
            deployer.getSender(),
            {
                value: toNano('0.068'),
            },
            {
                $$type: 'MintRequest',
                index: 2n,
                owner: player2.address,
                content: setItemContentCell({
                    name: 'NFT Flip Out Ticket Collection 2',
                    description: 'NFT Flip Out Ticket Collection Description 2',
                    image: 'https://img-cdn.pixlr.com/image-generator/history/65bb506dcb310754719cf81f/ede935de-1138-4f66-8ed7-44bd16efc709/medium.webp',
                }),
                game_bet: toNano('3.0'),
            },
        );

        const nextItemIndexAfter = await ticketCollection.getGetNextItemIndex();
        console.log(nextItemIndexAfter);
        expect(nextItemIndexAfter).toEqual(3n);

        let ticket1: SandboxContract<Ticket> = blockchain.openContract(
            Ticket.fromAddress(await ticketCollection.getGetNftAddressByIndex(1n)),
        );

        let ticket2: SandboxContract<Ticket> = blockchain.openContract(
            Ticket.fromAddress(await ticketCollection.getGetNftAddressByIndex(2n)),
        );

        const ticketData1 = await ticket1.getGetNftData();
        expect(parseCellV2(ticketData1.content)).toEqual({
            image: 'https://img-cdn.pixlr.com/image-generator/history/65bb506dcb310754719cf81f/ede935de-1138-4f66-8ed7-44bd16efc709/medium.webp',
            name: 'NFT Flip Out Ticket Collection 1',
            description: 'NFT Flip Out Ticket Collection Description 1',
        });

        const ticketData2 = await ticket2.getGetNftData();
        expect(parseCellV2(ticketData2.content)).toEqual({
            image: 'https://img-cdn.pixlr.com/image-generator/history/65bb506dcb310754719cf81f/ede935de-1138-4f66-8ed7-44bd16efc709/medium.webp',
            name: 'NFT Flip Out Ticket Collection 2',
            description: 'NFT Flip Out Ticket Collection Description 2',
        });

        const ticket1Owner = await ticket1.getOwner();
        expect(ticket1Owner.toString()).toEqual(player1.address.toString());

        const ticket2Owner = await ticket2.getOwner();
        console.log('Ticket 2 owner before: ', ticket1Owner);
        expect(ticket2Owner.toString()).toEqual(player2.address.toString());

        const pvpGameCreateRes = await pvpGame.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'CreateGame',
                player1: player1.address,
                player2: player2.address,
                player1Ticket: ticket1.address,
                player2Ticket: ticket2.address,
            },
        );

        const verificationResult = await pvpGame.getGetVerificationResult();
        console.log('Players verification result: ', verificationResult);

        const verifiedPlayers = await pvpGame.getGetVerifiedPlayers();
        expect(verifiedPlayers).toEqual(2n);

        // Win player 1

        const balanceBefore = await player1.getBalance();
        console.log('Winner balance before reward: ', balanceBefore);

        const pvpGameDoneRes = await pvpGame.send(
            deployer.getSender(),
            {
                value: toNano('0.023'),
            },
            {
                $$type: 'GameResult',
                winner_address: player1.address,
            },
        );

        const balanceAfter = await player1.getBalance();
        expect(balanceBefore).toBeLessThan(balanceAfter);
        console.log('Winner balance after reward: ', balanceAfter);
        console.log('Reward value: ', balanceAfter - balanceBefore);

        expect(ticket2.address.toString()).toEqual((await ticket2.getOwner()).toString());
    });

    function fromTextCell(cell: Cell): string {
        try {
            const parser = cell.beginParse();
            parser.loadUint(8);

            return parser.loadStringTail();
        } catch (e) {
            console.error('Failed to parse text from cell:', e);
            return '';
        }
    }

    function parseCellV1(cell: Cell): { name: string; description: string; image: string } {
        const parser = cell.beginParse();
        parser.loadUint(8);

        const dict = parser.loadDict(Dictionary.Keys.BigUint(256), Dictionary.Values.Cell());
        if (!dict) {
            console.error('Failed to load dictionary from cell.');
            return { name: '', description: '', image: '' };
        }

        const nameCell = dict.get(toSha256('name'));
        const descriptionCell = dict.get(toSha256('description'));
        const imageCell = dict.get(toSha256('image'));

        const name = nameCell ? fromTextCell(nameCell) : '';
        const description = descriptionCell ? fromTextCell(descriptionCell) : '';
        const image = imageCell ? fromTextCell(imageCell) : '';

        return { name, description, image };
    }

    function setItemContentCell(content: { name: string; description: string; image: string }): Cell {
        const itemContentDict = Dictionary.empty(Dictionary.Keys.BigUint(256), Dictionary.Values.Cell())
            .set(toSha256('name'), toTextCell(content.name))
            .set(toSha256('description'), toTextCell(content.description))
            .set(toSha256('image'), toTextCell(content.image));
        return beginCell().storeUint(0, 8).storeDict(itemContentDict).endCell();
    }

    function toSha256(s: string): bigint {
        return BigInt('0x' + sha256_sync(s).toString('hex'));
    }

    function toTextCell(s: string): Cell {
        return beginCell().storeUint(0, 8).storeStringTail(s).endCell();
    }

    function decodeOnChainCell(cell: Cell): string | Buffer {
        let parser = cell.beginParse();

        if (parser.remainingBits < 8 || parser.preloadUint(8) !== 0x00) {
            throw new Error('Invalid content data format');
        }

        parser.loadUint(8);

        let resultBuffer: Buffer = Buffer.alloc(0);
        while (true) {
            if (parser.remainingBits >= 8) {
                let dataChunk = parser.loadBuffer(parser.remainingBits >> 3);
                resultBuffer = Buffer.concat([resultBuffer, dataChunk]);
            }

            if (parser.remainingRefs > 0) {
                parser = parser.loadRef().beginParse();
            } else {
                break;
            }
        }

        try {
            let utf8String = resultBuffer.toString('utf-8');
            let isValidUtf8 = Buffer.from(utf8String, 'utf-8').compare(resultBuffer) === 0;
            let hasNoInvalidChars =
                resultBuffer.find((byte) => byte < 32 && byte !== 10 && byte !== 13 && byte !== 9) === undefined;

            if (isValidUtf8 && hasNoInvalidChars) {
                return utf8String;
            }
        } catch (err: any) {
            console.error(`Failed to parse the cell content: ${err.message}`);
            throw new Error('Failed to parse the cell content');
        }

        return resultBuffer;
    }

    function addHashedKeysToMap(map: Map<bigint, string>, keys?: string[]): Map<bigint, string> {
        if (keys && keys.length > 0) {
            let existingKeys = Array.from(map.values());
            keys.forEach((key) => {
                if (!existingKeys.includes(key)) {
                    map.set(toSha256(key), key);
                }
            });
        }
        return map;
    }

    let globalSupportedKeys = addHashedKeysToMap(new Map(), [
        'uri',
        'name',
        'description',
        'image',
        'image_data',
        'symbol',
        'decimals',
        'content_url',
        'attributes',
        'amount_style',
        'render_type',
        'currency',
        'game',
    ]);

    function parseCellV2(contentCell: Cell, extraSupportedFields?: string[]): { [key: string]: string | Buffer } {
        let decodedContent: { [key: string]: string | Buffer } = {};

        let keyHashToFieldMap = addHashedKeysToMap(globalSupportedKeys, extraSupportedFields);

        let parser = contentCell.beginParse();
        if (parser.remainingBits < 8 || parser.preloadUint(8) !== 0x00) {
            throw new Error('Invalid on-chain content prefix');
        }
        parser.loadUint(8);

        const keyParser = Dictionary.Keys.BigUint(256);
        const valueParser = Dictionary.Values.Cell();
        let dataDictionary = parser.loadDict(keyParser, valueParser);

        dataDictionary.keys().forEach((key) => {
            let fieldName = keyHashToFieldMap.get(key);
            if (fieldName === undefined) {
                fieldName = 'hash_' + key.toString(16);
            }

            let valueCell = dataDictionary.get(key);
            if (valueCell !== undefined) {
                decodedContent[fieldName] = decodeOnChainCell(valueCell);
            }
        });

        return decodedContent;
    }
});
