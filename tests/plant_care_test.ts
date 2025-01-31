import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test plant addition",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('plant-care', 'add-plant', [
                types.ascii("Monstera"),
                types.ascii("Water weekly, bright indirect light")
            ], wallet_1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let getPlant = chain.mineBlock([
            Tx.contractCall('plant-care', 'get-plant', [
                types.uint(1)
            ], wallet_1.address)
        ]);
        
        const plant = getPlant.receipts[0].result.expectOk().expectSome();
        assertEquals(plant['name'], "Monstera");
    }
});

Clarinet.test({
    name: "Test gardening tip submission and voting",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        const wallet_2 = accounts.get('wallet_2')!;
        
        let block = chain.mineBlock([
            Tx.contractCall('plant-care', 'submit-tip', [
                types.ascii("Always check soil moisture before watering")
            ], wallet_1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(1);
        
        let voteBlock = chain.mineBlock([
            Tx.contractCall('plant-care', 'vote-for-tip', [
                types.uint(1)
            ], wallet_2.address)
        ]);
        
        voteBlock.receipts[0].result.expectOk().expectBool(true);
        
        // Try voting again with same user - should fail
        let duplicateVote = chain.mineBlock([
            Tx.contractCall('plant-care', 'vote-for-tip', [
                types.uint(1)
            ], wallet_2.address)
        ]);
        
        duplicateVote.receipts[0].result.expectErr().expectUint(103);
        
        let getTip = chain.mineBlock([
            Tx.contractCall('plant-care', 'get-tip', [
                types.uint(1)
            ], wallet_1.address)
        ]);
        
        const tip = getTip.receipts[0].result.expectOk().expectSome();
        assertEquals(tip['votes'], types.uint(1));
    }
});

Clarinet.test({
    name: "Test achievement tracking",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const wallet_1 = accounts.get('wallet_1')!;
        
        // Add a plant to trigger achievement update
        chain.mineBlock([
            Tx.contractCall('plant-care', 'add-plant', [
                types.ascii("Pothos"),
                types.ascii("Low maintenance, water when dry")
            ], wallet_1.address)
        ]);
        
        let achievementBlock = chain.mineBlock([
            Tx.contractCall('plant-care', 'get-user-achievements', [
                types.principal(wallet_1.address)
            ], wallet_1.address)
        ]);
        
        const achievements = achievementBlock.receipts[0].result.expectOk().expectSome();
        assertEquals(achievements['plants-added'], types.uint(1));
    }
});
