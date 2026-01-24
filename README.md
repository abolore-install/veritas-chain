# VeritasChain - Digital Content Provenance Protocol

## Overview

**VeritasChain** is a digital content provenance protocol built on the **Stacks blockchain**, leveraging Bitcoin’s security as its settlement layer. It provides creators with a tamper-proof, immutable registry for their digital works, enabling them to establish authorship, prove authenticity, and maintain an auditable chain of custody for content.

By anchoring digital assets to Bitcoin through Stacks, VeritasChain empowers **artists, journalists, researchers, and developers** to protect intellectual property rights while ensuring transparency and trust across the digital content ecosystem.

---

## Key Features

* **Immutable Content Registry** – Register digital works with cryptographic proofs (SHA-256 hashes).
* **Versioning Support** – Track content updates through linked historical hashes.
* **Chain of Custody** – Each update maintains a verifiable lineage back to the original creator.
* **Licensing Frameworks** – Register standardized license types (e.g., Creative Commons, proprietary) with descriptions and external references.
* **Creator Indexing** – Retrieve all works associated with a given creator.
* **Bitcoin Security** – All provenance records are anchored to Bitcoin via Stacks consensus.

---

## System Overview

At a high level, the protocol consists of three core registries:

1. **Content Registry**

   * Maps content hashes → metadata (creator, title, timestamp, description, license type, versioning).
   * Provides the backbone for proving authenticity and lineage of digital assets.

2. **Creator Index**

   * Maps creators → list of content hashes.
   * Enables efficient querying of all works tied to a given principal.

3. **License Type Registry**

   * Maps license IDs → standardized license metadata.
   * Ensures content can be consistently licensed under transparent, pre-defined frameworks.

---

## Contract Architecture

The smart contract is implemented in **Clarity** and organized into four major layers:

### 1. **Constants & Error Codes**

Predefined error codes ensure consistent error handling:

* `ERR-NOT-AUTHORIZED`, `ERR-ALREADY-REGISTERED`, `ERR-NOT-FOUND`, etc.

### 2. **Data Models**

* **content-registry**: Stores immutable metadata per content hash.
* **creator-contents**: Maintains index of all content registered by a creator.
* **license-types**: Registry of standardized license definitions.

### 3. **Administrative Functions**

* `register-license-type` → Add a new license type (contract owner only).
* `transfer-ownership` → Reassign contract ownership.

### 4. **Content Management**

* `register-content` → First-time content registration.
* `update-content` → Creates a new version linked to prior content.

### 5. **Read-Only Queries**

* `get-content-info` → Retrieve metadata by hash.
* `get-creator-content-list` → Fetch all works by a creator.
* `get-license-details` → Inspect license metadata.
* `content-exists` → Verify whether content is registered.
* `get-content-version` → Return content version number.

---

## Data Flow

The typical lifecycle of a content registration:

1. **License Registration** *(once per license type)*

   * Contract owner registers license definitions via `register-license-type`.

2. **Content Registration**

   * A creator computes the SHA-256 hash of their work.
   * Calls `register-content` with metadata + license ID.
   * Entry is written to `content-registry`.
   * Creator’s content index is updated in `creator-contents`.

3. **Version Update**

   * A new hash is computed for the updated work.
   * Creator calls `update-content` with original hash → links old version to new.
   * Provenance chain is maintained automatically.

4. **Verification**

   * Anyone can query `get-content-info` or `get-previous-version` to verify lineage and authenticity.

---

## Example Use Cases

* **Digital Artists** – Prove originality of NFT artwork or digital designs.
* **Journalists** – Anchor investigative reports to prevent tampering or forgery.
* **Researchers** – Timestamp and version-control academic papers or datasets.
* **Software Developers** – Register code releases and license terms on-chain.

---

## Contract Deployment

The Clarity contract should be deployed on the **Stacks blockchain**.
Recommended flow:

```sh
# Deploy VeritasChain contract
clarinet contract publish contracts/veritas-chain.clar
```

Ensure that the contract owner (deployer) registers initial license frameworks before content creators begin usage.

---

## Security Considerations

* **Ownership Controls** – Only the contract owner can add new license types or transfer ownership.
* **Immutability** – Content once registered cannot be altered, only versioned through new entries.
* **Access Restrictions** – Updates are only permitted by the original creator.
* **Anchoring to Bitcoin** – Through Stacks’ consensus, all state changes are permanently secured by Bitcoin.

---

## Roadmap

* 🔹 Off-chain metadata integration (IPFS/Arweave) for large content storage.
* 🔹 Reputation system for creators and verifiers.
* 🔹 Marketplace integration for licensing and monetization of registered works.
* 🔹 Compliance extensions for enterprise adoption (e.g., DRM support).

---

## License

This protocol is released under the **MIT License**.
