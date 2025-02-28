import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Test administrative functions",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet_1 = accounts.get('wallet_1')!;
    
    // Test contract pause
    let block = chain.mineBlock([
      Tx.contractCall('plant-care', 'toggle-contract-pause', [], deployer.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    
    // Try adding plant while paused
    let pausedBlock = chain.mineBlock([
      Tx.contractCall('plant-care', 'add-plant', [
        types.ascii("Monstera"),
        types.ascii("Indoor"),
        types.ascii("Water weekly")
      ], wallet_1.address)
    ]);
    
    pausedBlock.receipts[0].result.expectErr().expectUint(106);
  }
});

// [Previous tests remain unchanged...]
