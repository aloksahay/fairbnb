const { ethers } = require('ethers');

/**
 * Generate a test wallet for 0G Storage
 */
function generateTestWallet() {
  // Generate a random wallet
  const wallet = ethers.Wallet.createRandom();
  
  console.log('🔑 Test Wallet Generated');
  console.log('========================');
  console.log(`Address: ${wallet.address}`);
  console.log(`Private Key: ${wallet.privateKey}`);
  console.log(`Mnemonic: ${wallet.mnemonic.phrase}`);
  console.log('========================');
  console.log('');
  console.log('⚠️  IMPORTANT NOTES:');
  console.log('- This is a TEST wallet for development only');
  console.log('- Never use this wallet on mainnet');
  console.log('- Fund this wallet with testnet tokens for 0G Storage');
  console.log('- Store the private key securely in your .env file');
  console.log('');
  console.log('📝 Environment Variable:');
  console.log(`ZEROG_PRIVATE_KEY=${wallet.privateKey}`);
  console.log('');
  console.log('🌐 Get testnet tokens:');
  console.log('- 0G Testnet Faucet: https://faucet.0g.ai/');
  console.log('- Add this address to the faucet to get test tokens');
  
  return {
    address: wallet.address,
    privateKey: wallet.privateKey,
    mnemonic: wallet.mnemonic.phrase
  };
}

// Generate and display the wallet
if (require.main === module) {
  generateTestWallet();
}

module.exports = { generateTestWallet }; 