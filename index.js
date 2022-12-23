const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const fs = require('fs');
const readline = require('readline');
const events = require('events');
const filename = './WLAdd.csv';

let whitelist_addresses = [];
let proof_list = [];

async function main() {
  await readCSVData();
  const leaves = whitelist_addresses.map((address) => keccak256(address));
  const tree = new MerkleTree(leaves, keccak256, { sort: true });
  const root = tree.getHexRoot();
  whitelist_addresses.map((address) => {
    const leaf = keccak256(address);
    const proof = tree.getHexProof(leaf);
    proof_list.push(JSON.stringify({[address] : proof}, null, 2));
  });
  console.log("root : " + root);
  console.log("proof list: " + proof_list);
}

async function readCSVData() {
  const readStream = fs.createReadStream(filename, {
    encoding: 'utf8',
  });

  // Reading line by line
  const reader = readline.createInterface({ input: readStream });
  
  reader.on('line', (line) => {
    whitelist_addresses.push(line);
  });

  readStream.on('error', (err) => {
    console.log(err);
    console.log('error found');
  });

  await events.once(reader, 'close');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => {})
  .catch((error) => {
    console.error(error);
    process.exit(1);
});