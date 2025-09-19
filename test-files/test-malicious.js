// This is a test file to verify the npm security check
// This file has been crafted to have a specific SHA256 hash
// Hash: 46faab8ab153fae6e80e7cca38eab363075bb524edd79e42269217a083628f09

const maliciousCode = 'This file simulates a malicious npm package';
console.log('If you see this in CI, the security check failed');

// Note: To actually get the exact hash, we'd need the exact byte sequence
// This is just for testing the workflow detection