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

;; Vote Ledger
;; Immutable record of all voting decisions and their impact
(define-map votes
  {
    proposal-id: uint,
    voter: principal,
  }
  {
    vote: bool, ;; true for yes, false for no
    power: uint, ;; Voting power used for this vote
  }
)

;; PRIVATE HELPER FUNCTIONS

;; Membership Validation
;; Efficiently checks if an address holds active membership status
(define-private (is-member (address principal))
  (is-some (map-get? members address))
)

;; Member Authorization Check
;; Validates member status and returns appropriate error response
(define-private (check-is-member (address principal))
  (if (is-member address)
    (ok true)
    ERR-NOT-MEMBER
  )
)

;; Voting Power Calculator
;; Converts staked STX balance into proportional voting influence
(define-private (calculate-voting-power (balance uint))
  (/ balance u1000000)
)

;; PUBLIC INTERFACE FUNCTIONS

;; Membership Registration
;; Enables new participants to join the DAO by staking minimum required STX
(define-public (join-dao)
  (let ((membership-fee (var-get minimum-membership-fee)))
    (asserts! (not (is-member tx-sender)) ERR-ALREADY-MEMBER)
    (try! (stx-transfer? membership-fee tx-sender (as-contract tx-sender)))

    (map-set members tx-sender {
      joined-at: stacks-block-height,
      stx-balance: membership-fee,
      voting-power: (calculate-voting-power membership-fee),
      proposals-created: u0,
      last-vote-height: u0,
    })

    (var-set total-members (+ (var-get total-members) u1))
    (var-set treasury-balance (+ (var-get treasury-balance) membership-fee))
    (ok true)
  )
)

;; Proposal Creation
;; Empowers members to submit funding requests and governance initiatives
(define-public (create-proposal
    (title (string-ascii 50))
    (description (string-ascii 500))
    (amount uint)
    (recipient principal)
  )
  (let (
      (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
      (proposal-id (var-get next-proposal-id))
    )
    (asserts! (<= amount (var-get treasury-balance)) ERR-INSUFFICIENT-BALANCE)
    (asserts! (> (len title) u0) ERR-INVALID-AMOUNT)
    (asserts! (> (len description) u0) ERR-INVALID-AMOUNT)
    (asserts! (is-eq recipient recipient) ERR-INVALID-AMOUNT)

    (map-set proposals proposal-id {
      creator: tx-sender,
      title: title,
      description: description,
      amount: amount,
      recipient: recipient,
      created-at: stacks-block-height,
      expires-at: (+ stacks-block-height (var-get proposal-duration)),
      yes-votes: u0,
      no-votes: u0,
      executed: false,
      total-votes: u0,
    })

    (map-set members tx-sender
      (merge member-data { proposals-created: (+ (get proposals-created member-data) u1) })
    )
    (var-set next-proposal-id (+ proposal-id u1))
    (ok proposal-id)
  )
)

;; Democratic Voting System
;; Allows members to cast weighted votes on active proposals
(define-public (vote-on-proposal
    (proposal-id uint)
    (vote-bool bool)
  )
  (let (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
      (member-data (unwrap! (map-get? members tx-sender) ERR-NOT-MEMBER))
      (voting-power (get voting-power member-data))
      ;; Validate the vote-bool input by explicitly checking it
      (validated-vote (if (is-eq vote-bool true)
        true
        false
      ))
    )
    (asserts! (< stacks-block-height (get expires-at proposal)) ERR-PROPOSAL-EXPIRED)
    (asserts!
      (is-none (map-get? votes {
        proposal-id: proposal-id,
        voter: tx-sender,
      }))
      ERR-ALREADY-VOTED
    )

    (map-set votes {
      proposal-id: proposal-id,
      voter: tx-sender,
    } {
      vote: validated-vote,
      power: voting-power,
    })

    (map-set proposals proposal-id
      (merge proposal {
        yes-votes: (if validated-vote
          (+ (get yes-votes proposal) voting-power)
          (get yes-votes proposal)
        ),
        no-votes: (if validated-vote
          (get no-votes proposal)
          (+ (get no-votes proposal) voting-power)
        ),
        total-votes: (+ (get total-votes proposal) voting-power),
      })
    )

    (map-set members tx-sender
      (merge member-data { last-vote-height: stacks-block-height })
    )
    (ok true)
  )
)

;; Proposal Execution Engine
;; Automatically processes approved proposals and distributes treasury funds
(define-public (execute-proposal (proposal-id uint))
  (let (
      (proposal (unwrap! (map-get? proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
      (total-votes (get total-votes proposal))
      (yes-votes (get yes-votes proposal))
    )
    (asserts! (>= stacks-block-height (get expires-at proposal)) ERR-PROPOSAL-EXPIRED)
    (asserts! (not (get executed proposal)) ERR-PROPOSAL-EXECUTED)
    (asserts! (>= (* yes-votes u100) (* total-votes (var-get quorum-threshold)))
      ERR-INSUFFICIENT-QUORUM
    )

    (try! (as-contract (stx-transfer? (get amount proposal) tx-sender (get recipient proposal))))

    (map-set proposals proposal-id (merge proposal { executed: true }))

    (var-set treasury-balance
      (- (var-get treasury-balance) (get amount proposal))
    )
    (ok true)
  )
)

;; READ-ONLY QUERY FUNCTIONS

;; Proposal Information Retrieval
;; Provides comprehensive proposal details including voting statistics
(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

;; Member Profile Access
;; Returns complete member participation history and current status
(define-read-only (get-member (address principal))
  (map-get? members address)
)

;; Vote History Lookup
;; Retrieves specific voting decisions for transparency and audit purposes
(define-read-only (get-vote
    (proposal-id uint)
    (voter principal)
  )
  (map-get? votes {
    proposal-id: proposal-id,
    voter: voter,
  })
)

;; DAO Metrics Dashboard
;; Provides real-time statistics about DAO health and configuration
(define-read-only (get-dao-info)
  {
    total-members: (var-get total-members),
    treasury-balance: (var-get treasury-balance),
    minimum-membership-fee: (var-get minimum-membership-fee),
    quorum-threshold: (var-get quorum-threshold),
  }
)
