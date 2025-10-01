;; Title: VeritasChain - Digital Content Provenance Protocol
;;
;; Summary:
;; A transparent, immutable system for establishing and verifying digital content 
;; ownership on Bitcoin's Layer 2. VeritasChain creates an unforgeable chain of 
;; custody for digital assets, enabling creators to prove authenticity and track 
;; content lineage through cryptographic verification.
;;
;; Description:
;; Built on Stacks blockchain, VeritasChain leverages Bitcoin's security to provide
;; content creators with a permanent, tamper-proof registry for their digital works.
;; The protocol supports versioning, licensing frameworks, and complete provenance
;; trails - ensuring that every piece of content can be traced back to its original
;; creator. Perfect for artists, journalists, researchers, and developers who need
;; verifiable proof of creation and ownership anchored to Bitcoin's immutable ledger.

;; Constants & Error Codes

(define-constant ERR-NOT-AUTHORIZED u1)
(define-constant ERR-ALREADY-REGISTERED u2)
(define-constant ERR-NOT-FOUND u3)
(define-constant ERR-LICENSE-NOT-FOUND u4)
(define-constant ERR-MAX-CONTENT-REACHED u5)
(define-constant ERR-INVALID-INPUT u6)
(define-constant ERR-INVALID-PRINCIPAL u7)

;; Data Variables

(define-data-var contract-owner principal tx-sender)

;; Data Maps

;; Core content registry mapping content hashes to metadata
(define-map content-registry
  { content-hash: (buff 32) }
  {
    creator: principal,
    title: (string-utf8 256),
    timestamp: uint,
    description: (string-utf8 1024),
    license-type: (string-utf8 64),
    version: uint,
    previous-hash: (optional (buff 32))
  }
)

;; Creator index for efficient content lookup by creator
(define-map creator-contents
  { creator: principal }
  { content-list: (list 100 (buff 32)) }
)

;; License type registry for standardized licensing frameworks
(define-map license-types
  { license-id: (string-utf8 64) }
  { 
    description: (string-utf8 512),
    terms-url: (string-utf8 256)
  }
)

;; Private Helper Functions

;; Validate that a string is not empty
(define-private (is-valid-string (str (string-utf8 256)))
  (> (len str) u0)
)

;; Validate that a long string is not empty
(define-private (is-valid-long-string (str (string-utf8 1024)))
  (> (len str) u0)
)

;; Validate that a medium string is not empty
(define-private (is-valid-medium-string (str (string-utf8 512)))
  (> (len str) u0)
)

;; Validate that a short string is not empty
(define-private (is-valid-short-string (str (string-utf8 64)))
  (> (len str) u0)
)

;; Public Functions - Administrative

;; Register a new license type (contract owner only)
;; @param license-id: Unique identifier for the license
;; @param description: Human-readable license description
;; @param terms-url: URL to full license terms
(define-public (register-license-type 
  (license-id (string-utf8 64)) 
  (description (string-utf8 512)) 
  (terms-url (string-utf8 256)))
  (begin
    ;; Authorization check
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Input validation
    (asserts! (is-valid-short-string license-id) (err ERR-INVALID-INPUT))
    (asserts! (is-valid-medium-string description) (err ERR-INVALID-INPUT))
    (asserts! (is-valid-string terms-url) (err ERR-INVALID-INPUT))
    
    ;; Check if license already exists
    (asserts! (is-none (map-get? license-types { license-id: license-id })) 
              (err ERR-ALREADY-REGISTERED))
    
    ;; Register the license type
    (ok (map-insert license-types 
      { license-id: license-id }
      { 
        description: description,
        terms-url: terms-url
      }
    ))
  )
)

nership to a new principal
;; @param new-owner: Principal address of the new contract owner
(define-public (transfer-ownership (new-owner principal))
  (begin
    ;; Authorization check
    (asserts! (is-eq tx-sender (var-get contract-owner)) (err ERR-NOT-AUTHORIZED))
    
    ;; Validate new owner is different from current owner
    (asserts! (not (is-eq new-owner tx-sender)) (err ERR-INVALID-PRINCIPAL))
    
    ;; Transfer ownership
    (var-set contract-owner new-owner)
    (ok true)
  )
)

;; Public Functions - Content Management

;; Register new content on the blockchain
;; @param content-hash: SHA-256 hash of the content
;; @param title: Content title
;; @param description: Detailed content description
;; @param license-type: License identifier (must be pre-registered)
;; @param previous-hash: Optional hash of previous version for versioning
(define-public (register-content 
  (content-hash (buff 32))
  (title (string-utf8 256))
  (description (string-utf8 1024))
  (license-type (string-utf8 64))
  (previous-hash (optional (buff 32))))
  
  (let
    (
      (creator tx-sender)
      (timestamp stacks-block-height)
      (contents-list (default-to (list) (get content-list (map-get? creator-contents { creator: creator }))))
    )
    
    ;; Input validation
    (asserts! (is-valid-string title) (err ERR-INVALID-INPUT))
    (asserts! (is-valid-long-string description) (err ERR-INVALID-INPUT))
    (asserts! (is-valid-short-string license-type) (err ERR-INVALID-INPUT))
    
    ;; Verify the content isn't already registered
    (asserts! (is-none (map-get? content-registry { content-hash: content-hash })) 
              (err ERR-ALREADY-REGISTERED))
    
    ;; Verify license type exists
    (asserts! (is-some (map-get? license-types { license-id: license-type })) 
              (err ERR-LICENSE-NOT-FOUND))
    
    ;; If previous-hash is provided, verify it exists
    (asserts! 
      (match previous-hash
        prev-hash (is-some (map-get? content-registry { content-hash: prev-hash }))
        true
      )
      (err ERR-NOT-FOUND)
    )
    
    ;; Register the content
    (map-set content-registry
      { content-hash: content-hash }
      {
        creator: creator,
        title: title,
        timestamp: timestamp,
        description: description,
        license-type: license-type,
        version: u1,
        previous-hash: previous-hash
      }
    )
    
    ;; Update creator's content list with proper error handling
    (map-set creator-contents
      { creator: creator }
      { content-list: (unwrap! (as-max-len? (append contents-list content-hash) u100)
                               (err ERR-MAX-CONTENT-REACHED)) }
    )
    
    (ok true)
  )
)

;; Update existing content by creating a new version
;; @param original-hash: Hash of the original content
;; @param new-hash: Hash of the updated content
;; @param title: Updated title
;; @param description: Updated description
;; @param license-type: License identifier
(define-public (update-content 
  (original-hash (buff 32))
  (new-hash (buff 32)) 
  (title (string-utf8 256))
  (description (string-utf8 1024))
  (license-type (string-utf8 64)))
  
  (let
    (
      (content (map-get? content-registry { content-hash: original-hash }))
      (creator tx-sender)
      (timestamp stacks-block-height)
      (contents-list (default-to (list) (get content-list (map-get? creator-contents { creator: creator }))))
    )
    
    ;; Input validation
    (asserts! (is-valid-string title) (err ERR-INVALID-INPUT))
    (asserts! (is-valid-long-string description) (err ERR-INVALID-INPUT))
    (asserts! (is-valid-short-string license-type) (err ERR-INVALID-INPUT))
    
    ;; Verify original content exists
    (asserts! (is-some content) (err ERR-NOT-FOUND))
    
    ;; Verify sender is the original creator
    (asserts! (is-eq creator (get creator (unwrap-panic content))) 
              (err ERR-NOT-AUTHORIZED))
    
    ;; Verify license type exists
    (asserts! (is-some (map-get? license-types { license-id: license-type })) 
              (err ERR-LICENSE-NOT-FOUND))
    
    ;; Verify the new hash isn't already registered
    (asserts! (is-none (map-get? content-registry { content-hash: new-hash })) 
              (err ERR-ALREADY-REGISTERED))
    
    ;; Register the new version
    (map-set content-registry
      { content-hash: new-hash }
      {
        creator: creator,
        title: title,
        timestamp: timestamp,
        description: description,
        license-type: license-type,
        version: (+ u1 (get version (unwrap-panic content))),
        previous-hash: (some original-hash)
      }
    )
    
    ;; Update creator's content list with proper error handling
    (map-set creator-contents
      { creator: creator }
      { content-list: (unwrap! (as-max-len? (append contents-list new-hash) u100)
                               (err ERR-MAX-CONTENT-REACHED)) }
    )
    
    (ok true)
  )
)

;; Read-Only Functions

;; Get complete content information by hash
;; @param content-hash: SHA-256 hash of the content
;; @returns: Content metadata or none if not found
(define-read-only (get-content-info (content-hash (buff 32)))
  (map-get? content-registry { content-hash: content-hash })
)

;; Get all content registered by a specific creator
;; @param creator: Principal address of the creator
;; @returns: List of content hashes or none if creator has no content
(define-read-only (get-creator-content-list (creator principal))
  (map-get? creator-contents { creator: creator })
)

;; Get license type details
;; @param license-id: License identifier
;; @returns: License metadata or none if not found
(define-read-only (get-license-details (license-id (string-utf8 64)))
  (map-get? license-types { license-id: license-id })
)

;; Get current contract owner
;; @returns: Principal address of contract owner
(define-read-only (get-contract-owner)
  (var-get contract-owner)
)

;; Get the previous version hash of content
;; @param content-hash: SHA-256 hash of the content
;; @returns: Optional hash of previous version or error if content not found
(define-read-only (get-previous-version (content-hash (buff 32)))
  (match (map-get? content-registry { content-hash: content-hash })
    content-data (ok (get previous-hash content-data))
    (err ERR-NOT-FOUND)
  )
)

;; Check if content exists in the registry
;; @param content-hash: SHA-256 hash of the content
;; @returns: True if content exists, false otherwise
(define-read-only (content-exists (content-hash (buff 32)))
  (is-some (map-get? content-registry { content-hash: content-hash }))
)

;; Get content version number
;; @param content-hash: SHA-256 hash of the content
;; @returns: Version number or error if content not found
(define-read-only (get-content-version (content-hash (buff 32)))
  (match (map-get? content-registry { content-hash: content-hash })
    content-data (ok (get version content-data))
    (err ERR-NOT-FOUND)
  )
)