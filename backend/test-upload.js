const { ZgFile, Indexer } = require('@0glabs/0g-ts-sdk');
const { ethers } = require('ethers');
const fs = require('fs');
const path = require('path');

// Configuration
const RPC_URL = 'https://evmrpc-testnet.0g.ai/';
const INDEXER_RPC = 'https://indexer-storage-testnet-turbo.0g.ai';
const PRIVATE_KEY = process.env.ZEROG_PRIVATE_KEY || '';

if (!PRIVATE_KEY) {
  console.error('❌ Please set ZEROG_PRIVATE_KEY environment variable');
  process.exit(1);
}

async function testUpload() {
  let file = null;
  
  try {
    console.log('🚀 Starting 0G Storage Upload Test');
    console.log('📡 RPC URL:', RPC_URL);
    console.log('🔗 Indexer RPC:', INDEXER_RPC);
    
    // Initialize provider and signer
    const provider = new ethers.JsonRpcProvider(RPC_URL);
    const signer = new ethers.Wallet(PRIVATE_KEY, provider);
    
    console.log('💰 Wallet Address:', signer.address);
    
    // Check wallet balance
    const balance = await provider.getBalance(signer.address);
    console.log('💰 Wallet Balance:', ethers.formatEther(balance), 'ETH');
    
    // Initialize indexer
    const indexer = new Indexer(INDEXER_RPC);
    
    // Create a test file
    const testContent = 'Hello 0G Storage! This is a test file.';
    const testFileName = 'test-file.txt';
    const testFilePath = path.join(__dirname, testFileName);
    
    fs.writeFileSync(testFilePath, testContent);
    console.log('📄 Created test file:', testFilePath);
    
    // Create ZgFile from file path
    file = await ZgFile.fromFilePath(testFilePath);
    console.log('📁 ZgFile created successfully');
    
    // Generate merkle tree
    const [tree, treeErr] = await file.merkleTree();
    if (treeErr !== null) {
      throw new Error(`Error generating Merkle tree: ${treeErr}`);
    }
    
    if (!tree) {
      throw new Error('Failed to generate Merkle tree');
    }
    
    const rootHash = tree.rootHash();
    if (!rootHash) {
      throw new Error('Failed to get root hash');
    }
    
    console.log('🌳 Generated root hash:', rootHash);
    
    // Check network status
    const [nodes, nodesErr] = await indexer.selectNodes(4);
    if (nodesErr !== null) {
      console.error('❌ Failed to select nodes:', nodesErr);
      return;
    }
    
    console.log('🌐 Selected', nodes.length, 'storage nodes');
    
    // Get status of first node
    if (nodes.length > 0) {
      try {
        const firstNodeStatus = await nodes[0].getStatus();
        console.log('📊 First node status:', firstNodeStatus);
      } catch (statusError) {
        console.warn('⚠️ Failed to get node status:', statusError);
      }
    }
    
    // Upload file
    console.log('⬆️ Starting upload...');
    const [tx, uploadErr] = await indexer.upload(file, RPC_URL, signer);
    
    if (uploadErr !== null) {
      throw new Error(`Upload error: ${uploadErr}`);
    }
    
    console.log('✅ Upload successful!');
    console.log('📄 Root Hash:', rootHash);
    console.log('🔗 Transaction Hash:', tx);
    
    // Clean up test file
    fs.unlinkSync(testFilePath);
    console.log('🧹 Cleaned up test file');
    
  } catch (error) {
    console.error('❌ Upload test failed:', error);
    process.exit(1);
  } finally {
    // Always close the file handle
    if (file) {
      try {
        await file.close();
        console.log('🔒 File handle closed');
      } catch (closeError) {
        console.warn('⚠️ Failed to close file handle:', closeError);
      }
    }
  }
}

// Run the test
testUpload()
  .then(() => {
    console.log('🎉 Test completed successfully!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('💥 Test failed:', error);
    process.exit(1);
  }); 