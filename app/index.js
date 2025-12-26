const express = require('express');
const fetch = require('node-fetch');

const app = express();
const PORT = process.env.PORT || 3000;
const GETH_RPC = process.env.GETH_RPC || 'http://127.0.0.1:8545';
const IPFS_API = process.env.IPFS_API || 'http://127.0.0.1:5001';

app.get('/', async (req, res) => {
  res.send(`
    <h1>DAppNode Demo Container</h1>
    <ul>
      <li><a href="/blockNumber">Current Ethereum block (dev chain)</a></li>
      <li><a href="/ipfs-id">IPFS Node ID</a></li>
      <li><a href="/health">Health</a></li>
    </ul>
  `);
});

app.get('/blockNumber', async (req, res) => {
  try {
    const body = {
      jsonrpc: "2.0",
      id: 1,
      method: "eth_blockNumber",
      params: []
    };
    const r = await fetch(GETH_RPC, {
      method: 'POST',
      body: JSON.stringify(body),
      headers: { 'Content-Type': 'application/json' }
    });
    const json = await r.json();
    const blockHex = json.result || '0x0';
    const blockDec = parseInt(blockHex, 16);
    res.json({ blockHex, blockDec });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/ipfs-id', async (req, res) => {
  try {
    const r = await fetch(`${IPFS_API}/api/v0/id`);
    const json = await r.json();
    res.json(json);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`DAppNode demo app running on ${PORT}`);
});