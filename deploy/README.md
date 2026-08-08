# CardFi Preprod Deployment Manifest

`preprod.manifest.json` is deterministically generated from the committed CIP-57 blueprint. It records the network, blueprint SHA-256, unique validator hashes, compiled sizes and every required parameter slot.

```powershell
npm.cmd run contracts:build
npm.cmd run deploy:manifest
npm.cmd run deploy:manifest:check
```

Before deployment, replace every `<..._CBOR>` slot with canonical CBOR for the intended policy ID, asset name or verification key hash. Parameterize scripts in the listed order, mint the identity NFTs, create the Governance and Oracle state UTxOs, then initialize market shards and positions. Record resulting script addresses, transaction IDs and output indexes in a separate environment-specific release record; never overwrite this generated source manifest with unverified addresses.

The current manifest is a reproducible parameterization artifact, not evidence of a submitted Preprod transaction.
