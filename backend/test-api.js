const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');
const path = require('path');

const API_BASE = 'http://localhost:3000';

async function testAPI() {
  console.log('🧪 Testing Fairbnb Backend API');
  console.log('================================');
  
  try {
    // Test health endpoint
    console.log('1. Testing health endpoint...');
    const healthResponse = await axios.get(`${API_BASE}/health`);
    console.log('✅ Health check:', healthResponse.data.message);
    
    // Test API documentation endpoint
    console.log('\n2. Testing API documentation...');
    const apiResponse = await axios.get(`${API_BASE}/api`);
    console.log('✅ API documentation available');
    console.log('Available endpoints:', Object.keys(apiResponse.data.endpoints));
    
    console.log('\n📝 API Test Results:');
    console.log('- Health endpoint: ✅ Working');
    console.log('- API documentation: ✅ Working');
    console.log('- Server is running properly');
    
    console.log('\n🔧 Next Steps:');
    console.log('1. Add your 0G private key to .env file');
    console.log('2. Fund your wallet with testnet tokens');
    console.log('3. Test file upload with: npm run test-upload');
    
  } catch (error) {
    console.error('❌ API Test failed:', error.message);
    if (error.code === 'ECONNREFUSED') {
      console.log('\n💡 Make sure the server is running with: npm run dev');
    }
  }
}

// Test file upload (requires server to be running and configured)
async function testFileUpload() {
  try {
    console.log('\n3. Testing file upload...');
    
    // Create a simple test file
    const testContent = 'Hello from Fairbnb Backend!';
    const testFilePath = path.join(__dirname, 'test-file.txt');
    fs.writeFileSync(testFilePath, testContent);
    
    const form = new FormData();
    form.append('file', fs.createReadStream(testFilePath));
    
    const uploadResponse = await axios.post(`${API_BASE}/api/files/upload`, form, {
      headers: {
        ...form.getHeaders(),
      },
    });
    
    console.log('✅ File upload successful!');
    console.log('Root hash:', uploadResponse.data.data.rootHash);
    console.log('File URL:', uploadResponse.data.data.url);
    
    // Clean up
    fs.unlinkSync(testFilePath);
    
    return uploadResponse.data.data.rootHash;
    
  } catch (error) {
    console.error('❌ File upload test failed:', error.response?.data || error.message);
  }
}

if (require.main === module) {
  testAPI().then(() => {
    console.log('\n🎉 Basic API tests completed!');
  });
}

module.exports = { testAPI, testFileUpload };
