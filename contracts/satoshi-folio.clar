;; Title: SatoshiFolio - Autonomous Bitcoin Portfolio Management Protocol
;;
;; Summary:
;; A next-generation DeFi protocol that brings institutional-grade portfolio management
;; to Bitcoin through Stacks smart contracts. SatoshiFolio empowers users to create
;; self-executing investment strategies with automated rebalancing and multi-asset
;; diversification, all while maintaining full custody of their digital assets.
;;
;; Description:
;; SatoshiFolio represents the evolution of Bitcoin-native wealth management, combining
;; the security of Bitcoin's base layer with the programmability of Stacks. Our protocol
;; enables sophisticated investors to deploy automated strategies across the growing
;; Bitcoin ecosystem without sacrificing self-sovereignty.
;;
;; Key Features:
;; - Autonomous Portfolio Execution - Set-and-forget strategies with 24-hour rebalancing cycles
;; - Multi-Asset Intelligence - Support for up to 10 Bitcoin-native and Stacks tokens
;; - Precision Allocation - Fine-tuned percentage control down to 0.01% granularity
;; - Non-Custodial Architecture - Users maintain complete control over their assets
;; - Institutional Security - Multi-signature compatibility with SECP256k1 compliance
;; - Transparent Economics - Clear 0.25% protocol fee structure
;; - Audit-Ready Design - Clarity's inherent verifiability ensures trust through code
;;
;; Built for the Bitcoin standard, SatoshiFolio bridges traditional portfolio theory
;; with decentralized execution, enabling wealth preservation and growth strategies
;; that honor Bitcoin's principles of self-sovereignty and financial autonomy.

;; PROTOCOL CONSTANTS & CONFIGURATION

;; Error Response Codes
(define-constant ERR-UNAUTHORIZED-ACCESS (err u100))
(define-constant ERR-PORTFOLIO-NOT-FOUND (err u101))
(define-constant ERR-INSUFFICIENT-BALANCE (err u102))
(define-constant ERR-INVALID-TOKEN-CONTRACT (err u103))
(define-constant ERR-REBALANCING-FAILED (err u104))
(define-constant ERR-PORTFOLIO-ALREADY-EXISTS (err u105))
(define-constant ERR-INVALID-ALLOCATION (err u106))
(define-constant ERR-TOKEN-LIMIT-EXCEEDED (err u107))
(define-constant ERR-MISMATCHED-ARRAYS (err u108))
(define-constant ERR-USER-REGISTRY-FAILED (err u109))
(define-constant ERR-TOKEN-INDEX-INVALID (err u110))

;; Protocol Configuration
(define-constant MAX-PORTFOLIO-ASSETS u10)
(define-constant PERCENTAGE-BASIS u10000) ;; 100.00% = 10,000 basis points
(define-constant REBALANCE-COOLDOWN u144) ;; ~24 hours in Stacks blocks
(define-constant MAX-USER-PORTFOLIOS u20)

;; PROTOCOL STATE VARIABLES

(define-data-var protocol-administrator principal tx-sender)
(define-data-var next-portfolio-id uint u1)
(define-data-var management-fee-bps uint u25) ;; 0.25% management fee

;; DATA STRUCTURES

;; Core Portfolio Registry
(define-map PortfolioRegistry
  uint ;; portfolio-id
  {
    owner: principal,
    creation-block: uint,
    last-rebalance-block: uint,
    total-portfolio-value: uint,
    is-active: bool,
    asset-count: uint,
  }
)

;; Asset Allocation Configuration
(define-map AssetAllocations
  {
    portfolio-id: uint,
    asset-index: uint,
  }
  {
    target-allocation-bps: uint,
    current-balance: uint,
    token-contract: principal,
  }
)

;; User Portfolio Ownership Tracking
(define-map UserPortfolioIndex
  principal
  (list 20 uint)
)

;; READ-ONLY FUNCTIONS - PORTFOLIO QUERIES

(define-read-only (get-portfolio-details (portfolio-id uint))
  (map-get? PortfolioRegistry portfolio-id)
)

(define-read-only (get-asset-allocation
    (portfolio-id uint)
    (asset-index uint)
  )
  (map-get? AssetAllocations {
    portfolio-id: portfolio-id,
    asset-index: asset-index,
  })
)

(define-read-only (get-user-portfolio-list (user principal))
  (default-to (list) (map-get? UserPortfolioIndex user))
)

(define-read-only (calculate-portfolio-health (portfolio-id uint))
  (let (
      (portfolio (unwrap! (get-portfolio-details portfolio-id) ERR-PORTFOLIO-NOT-FOUND))
      (blocks-since-rebalance (- stacks-block-height (get last-rebalance-block portfolio)))
      (total-value (get total-portfolio-value portfolio))
    )
    (ok {
      portfolio-id: portfolio-id,
      current-value: total-value,
      requires-rebalancing: (>= blocks-since-rebalance REBALANCE-COOLDOWN),
      blocks-until-next-rebalance: (if (>= blocks-since-rebalance REBALANCE-COOLDOWN)
        u0
        (- REBALANCE-COOLDOWN blocks-since-rebalance)
      ),
    })
  )
)

(define-read-only (get-protocol-stats)
  {
    total-portfolios: (var-get next-portfolio-id),
    management-fee-bps: (var-get management-fee-bps),
    max-assets-per-portfolio: MAX-PORTFOLIO-ASSETS,
    rebalance-frequency-blocks: REBALANCE-COOLDOWN,
  }
)

;; PRIVATE UTILITY FUNCTIONS

(define-private (validate-asset-index
    (portfolio-id uint)
    (asset-index uint)
  )
  (let (
      (portfolio (unwrap! (get-portfolio-details portfolio-id) false))
      (asset-count (get asset-count portfolio))
    )
    (and
      (< asset-index MAX-PORTFOLIO-ASSETS)
      (< asset-index asset-count)
    )
  )
)

(define-private (validate-allocation-percentage (percentage uint))
  (and (>= percentage u0) (<= percentage PERCENTAGE-BASIS))
)

(define-private (validate-total-allocation (allocations (list 10 uint)))
  (is-eq (fold + allocations u0) PERCENTAGE-BASIS)
)

(define-private (register-user-portfolio
    (user principal)
    (portfolio-id uint)
  )
  (let (
      (existing-portfolios (get-user-portfolio-list user))
      (updated-portfolios (unwrap! (as-max-len? (append existing-portfolios portfolio-id) u20)
        ERR-USER-REGISTRY-FAILED
      ))
    )
    (map-set UserPortfolioIndex user updated-portfolios)
    (ok true)
  )
)