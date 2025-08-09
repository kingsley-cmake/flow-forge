;; FlowForge DAO Smart Contract

;; Summary
;; A sophisticated governance protocol that democratizes decision-making through stake-weighted voting,
;; enabling community-driven resource allocation and transparent proposal execution with built-in
;; economic incentives for active participation.

;; Description
;; FlowForge DAO revolutionizes decentralized governance by implementing a robust voting mechanism
;; where community members stake STX tokens to gain proportional influence over treasury management
;; and strategic decisions. The protocol features time-bound proposal lifecycles, automated quorum
;; validation, and seamless fund distribution, creating a self-sustaining ecosystem where stakeholder
;; alignment drives collective value creation and democratic resource stewardship.

;; ERROR CONSTANTS
;; Comprehensive error handling for all contract operations

(define-constant ERR-OWNER-ONLY (err u100)) ;; Operation restricted to contract owner
(define-constant ERR-NOT-MEMBER (err u101)) ;; User is not a DAO member
(define-constant ERR-ALREADY-MEMBER (err u102)) ;; User is already a DAO member
(define-constant ERR-INSUFFICIENT-BALANCE (err u103)) ;; Not enough funds for operation
(define-constant ERR-PROPOSAL-NOT-FOUND (err u104)) ;; Requested proposal doesn't exist
(define-constant ERR-ALREADY-VOTED (err u105)) ;; Member has already voted on this proposal
(define-constant ERR-PROPOSAL-EXPIRED (err u106)) ;; Proposal voting period has ended
(define-constant ERR-INSUFFICIENT-QUORUM (err u107)) ;; Proposal didn't reach required votes
(define-constant ERR-PROPOSAL-NOT-PASSED (err u108)) ;; Proposal didn't get enough yes votes
(define-constant ERR-INVALID-AMOUNT (err u109)) ;; Invalid amount specified
(define-constant ERR-UNAUTHORIZED (err u110)) ;; User not authorized for operation
(define-constant ERR-PROPOSAL-EXECUTED (err u111)) ;; Proposal has already been executed

;; CONFIGURATION VARIABLES
;; Core protocol parameters governing DAO operations

(define-data-var minimum-membership-fee uint u1000000) ;; Minimum STX required to join (in microSTX)
(define-data-var proposal-duration uint u144) ;; Proposal voting window in blocks (~1 day)
(define-data-var quorum-threshold uint u51) ;; Minimum percentage of votes required (51%)
(define-data-var total-members uint u0) ;; Current number of DAO members
(define-data-var treasury-balance uint u0) ;; Total STX held by the DAO
(define-data-var next-proposal-id uint u0) ;; Auto-incrementing proposal counter

;; DATA STRUCTURES

;; Member Registry
;; Comprehensive tracking of member participation and stake metrics
(define-map members
  principal
  {
    joined-at: uint, ;; Block height when member joined
    stx-balance: uint, ;; Member's staked STX balance
    voting-power: uint, ;; Calculated voting power based on stake
    proposals-created: uint, ;; Number of proposals created by member
    last-vote-height: uint, ;; Block height of member's last vote
  }
)

;; Proposal Repository
;; Complete proposal lifecycle management and voting statistics
(define-map proposals
  uint
  {
    creator: principal, ;; Address that created the proposal
    title: (string-ascii 50), ;; Short proposal title
    description: (string-ascii 500), ;; Detailed proposal description
    amount: uint, ;; STX amount requested
    recipient: principal, ;; Recipient of funds if approved
    created-at: uint, ;; Block height at creation
    expires-at: uint, ;; Block height when voting ends
    yes-votes: uint, ;; Total yes votes received
    no-votes: uint, ;; Total no votes received
    executed: bool, ;; Whether proposal has been executed
    total-votes: uint, ;; Total votes cast
  }
)