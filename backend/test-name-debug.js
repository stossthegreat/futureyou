// Quick test script to check what name is stored for a user
const https = require('https');

const BACKEND_URL = 'futureyou-production-7xrs.up.railway.app';
const USER_ID = 'iUuMNoVLeyNpn9eMP9xaBY4howt1'; // The user from logs

// You'll need to get a Firebase token from your Flutter app
// For now, let's just check if we can see what the service returns

const query = `
query GetUserFacts($userId: String!) {
  userFacts(where: {userId: {equals: $userId}}) {
    userId
    json
  }
}
`;

console.log('Testing name resolution for user:', USER_ID);
console.log('\nNeed to test with actual Firebase auth token from Flutter app');
console.log('\nAlternative: Check Railway logs for the debug output after generating a brief');

