;; title: Hospitality-Staff-Escrow-Wages

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-insufficient-balance (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-invalid-hours (err u106))
(define-constant err-no-wages (err u107))
(define-constant err-already-claimed (err u108))
(define-constant err-dispute-not-found (err u109))
(define-constant err-already-disputed (err u110))
(define-constant err-already-resolved (err u111))

(define-constant blocks-per-day u144)

(define-data-var next-staff-id uint u1)
(define-data-var next-shift-id uint u1)
(define-data-var next-dispute-id uint u1)

(define-map staff-registry
  uint
  {
    wallet: principal,
    name: (string-ascii 50),
    hourly-rate: uint,
    total-hours: uint,
    total-earned: uint,
    active: bool,
    registered-at: uint
  }
)

(define-map staff-wallet-to-id principal uint)

(define-map shift-logs
  uint
  {
    staff-id: uint,
    hours: uint,
    wages: uint,
    logged-at: uint,
    claimed: bool,
    claimed-at: (optional uint)
  }
)

(define-map staff-shifts
  {staff-id: uint, shift-index: uint}
  uint
)

(define-map staff-shift-count uint uint)

(define-map employer-deposits
  principal
  uint
)

(define-map dispute-logs
  uint
  {
    shift-id: uint,
    staff-id: uint,
    reason: (string-ascii 200),
    filed-at: uint,
    resolved: bool,
    resolution: (optional (string-ascii 200)),
    resolved-at: (optional uint)
  }
)

(define-map shift-disputes uint uint)

(define-read-only (get-staff-by-id (staff-id uint))
  (map-get? staff-registry staff-id)
)

(define-read-only (get-staff-id-by-wallet (wallet principal))
  (map-get? staff-wallet-to-id wallet)
)

(define-read-only (get-shift-log (shift-id uint))
  (map-get? shift-logs shift-id)
)

(define-read-only (get-staff-shift-count (staff-id uint))
  (default-to u0 (map-get? staff-shift-count staff-id))
)

(define-read-only (get-staff-shift-by-index (staff-id uint) (shift-index uint))
  (map-get? staff-shifts {staff-id: staff-id, shift-index: shift-index})
)

(define-read-only (get-employer-balance (employer principal))
  (default-to u0 (map-get? employer-deposits employer))
)

(define-read-only (get-next-staff-id)
  (ok (var-get next-staff-id))
)

(define-read-only (get-next-shift-id)
  (ok (var-get next-shift-id))
)

(define-read-only (get-dispute (dispute-id uint))
  (map-get? dispute-logs dispute-id)
)

(define-read-only (get-shift-dispute (shift-id uint))
  (map-get? shift-disputes shift-id)
)

(define-read-only (get-next-dispute-id)
  (ok (var-get next-dispute-id))
)

(define-read-only (calculate-wages (hourly-rate uint) (hours uint))
  (ok (* hourly-rate hours))
)

(define-read-only (get-unclaimed-wages (staff-id uint))
  (let
    (
      (shift-count (get-staff-shift-count staff-id))
    )
    (ok (fold check-unclaimed-shift (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19) {staff-id: staff-id, total: u0, count: shift-count}))
  )
)

(define-private (check-unclaimed-shift (index uint) (state {staff-id: uint, total: uint, count: uint}))
  (if (< index (get count state))
    (match (get-staff-shift-by-index (get staff-id state) index)
      shift-id
        (match (get-shift-log shift-id)
          shift-data
            (if (not (get claimed shift-data))
              {staff-id: (get staff-id state), total: (+ (get total state) (get wages shift-data)), count: (get count state)}
              state
            )
          state
        )
      state
    )
    state
  )
)

(define-public (register-staff (wallet principal) (name (string-ascii 50)) (hourly-rate uint))
  (let
    (
      (staff-id (var-get next-staff-id))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (is-none (map-get? staff-wallet-to-id wallet)) err-already-exists)
    (asserts! (> hourly-rate u0) err-invalid-amount)
    (map-set staff-registry staff-id {
      wallet: wallet,
      name: name,
      hourly-rate: hourly-rate,
      total-hours: u0,
      total-earned: u0,
      active: true,
      registered-at: current-block
    })
    (map-set staff-wallet-to-id wallet staff-id)
    (map-set staff-shift-count staff-id u0)
    (var-set next-staff-id (+ staff-id u1))
    (ok staff-id)
  )
)

(define-public (update-hourly-rate (staff-id uint) (new-rate uint))
  (let
    (
      (staff-data (unwrap! (map-get? staff-registry staff-id) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (> new-rate u0) err-invalid-amount)
    (map-set staff-registry staff-id (merge staff-data {hourly-rate: new-rate}))
    (ok true)
  )
)

(define-public (deactivate-staff (staff-id uint))
  (let
    (
      (staff-data (unwrap! (map-get? staff-registry staff-id) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set staff-registry staff-id (merge staff-data {active: false}))
    (ok true)
  )
)

(define-public (reactivate-staff (staff-id uint))
  (let
    (
      (staff-data (unwrap! (map-get? staff-registry staff-id) err-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set staff-registry staff-id (merge staff-data {active: true}))
    (ok true)
  )
)

(define-public (deposit-funds)
  (let
    (
      (amount (stx-get-balance tx-sender))
      (current-balance (get-employer-balance tx-sender))
    )
    (asserts! (> amount u0) err-invalid-amount)
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))
    (map-set employer-deposits tx-sender (+ current-balance amount))
    (ok amount)
  )
)

(define-public (log-shift (staff-id uint) (hours uint) (employer principal))
  (let
    (
      (staff-data (unwrap! (map-get? staff-registry staff-id) err-not-found))
      (shift-id (var-get next-shift-id))
      (wages (* (get hourly-rate staff-data) hours))
      (employer-balance (get-employer-balance employer))
      (current-block stacks-block-height)
      (shift-count (get-staff-shift-count staff-id))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (get active staff-data) err-unauthorized)
    (asserts! (> hours u0) err-invalid-hours)
    (asserts! (>= employer-balance wages) err-insufficient-balance)
    (map-set shift-logs shift-id {
      staff-id: staff-id,
      hours: hours,
      wages: wages,
      logged-at: current-block,
      claimed: false,
      claimed-at: none
    })
    (map-set staff-shifts {staff-id: staff-id, shift-index: shift-count} shift-id)
    (map-set staff-shift-count staff-id (+ shift-count u1))
    (map-set staff-registry staff-id (merge staff-data {
      total-hours: (+ (get total-hours staff-data) hours),
      total-earned: (+ (get total-earned staff-data) wages)
    }))
    (map-set employer-deposits employer (- employer-balance wages))
    (var-set next-shift-id (+ shift-id u1))
    (ok shift-id)
  )
)

(define-public (claim-wages (shift-id uint))
  (let
    (
      (shift-data (unwrap! (map-get? shift-logs shift-id) err-not-found))
      (staff-id (get staff-id shift-data))
      (staff-data (unwrap! (map-get? staff-registry staff-id) err-not-found))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq tx-sender (get wallet staff-data)) err-unauthorized)
    (asserts! (not (get claimed shift-data)) err-already-claimed)
    (asserts! (> (get wages shift-data) u0) err-no-wages)
    (try! (as-contract (stx-transfer? (get wages shift-data) tx-sender (get wallet staff-data))))
    (map-set shift-logs shift-id (merge shift-data {
      claimed: true,
      claimed-at: (some current-block)
    }))
    (ok (get wages shift-data))
  )
)

(define-public (claim-all-wages (staff-id uint))
  (let
    (
      (staff-data (unwrap! (map-get? staff-registry staff-id) err-not-found))
      (shift-count (get-staff-shift-count staff-id))
    )
    (asserts! (is-eq tx-sender (get wallet staff-data)) err-unauthorized)
    (ok (fold claim-single-shift (list u0 u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19) {staff-id: staff-id, total: u0, count: shift-count}))
  )
)

(define-private (claim-single-shift (index uint) (state {staff-id: uint, total: uint, count: uint}))
  (if (< index (get count state))
    (match (get-staff-shift-by-index (get staff-id state) index)
      shift-id
        (match (get-shift-log shift-id)
          shift-data
            (if (and (not (get claimed shift-data)) (> (get wages shift-data) u0))
              (match (map-get? staff-registry (get staff-id state))
                staff-data
                  (match (as-contract (stx-transfer? (get wages shift-data) tx-sender (get wallet staff-data)))
                    success
                      (begin
                        (map-set shift-logs shift-id (merge shift-data {claimed: true, claimed-at: (some stacks-block-height)}))
                        {staff-id: (get staff-id state), total: (+ (get total state) (get wages shift-data)), count: (get count state)}
                      )
                    error state
                  )
                state
              )
              state
            )
          state
        )
      state
    )
    state
  )
)

(define-public (file-dispute (shift-id uint) (reason (string-ascii 200)))
  (let
    (
      (shift-data (unwrap! (map-get? shift-logs shift-id) err-not-found))
      (staff-id (get staff-id shift-data))
      (staff-data (unwrap! (map-get? staff-registry staff-id) err-not-found))
      (dispute-id (var-get next-dispute-id))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq tx-sender (get wallet staff-data)) err-unauthorized)
    (asserts! (is-none (map-get? shift-disputes shift-id)) err-already-disputed)
    (map-set dispute-logs dispute-id {
      shift-id: shift-id,
      staff-id: staff-id,
      reason: reason,
      filed-at: current-block,
      resolved: false,
      resolution: none,
      resolved-at: none
    })
    (map-set shift-disputes shift-id dispute-id)
    (var-set next-dispute-id (+ dispute-id u1))
    (ok dispute-id)
  )
)

(define-public (resolve-dispute (dispute-id uint) (resolution (string-ascii 200)))
  (let
    (
      (dispute-data (unwrap! (map-get? dispute-logs dispute-id) err-dispute-not-found))
      (current-block stacks-block-height)
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (not (get resolved dispute-data)) err-already-resolved)
    (map-set dispute-logs dispute-id (merge dispute-data {
      resolved: true,
      resolution: (some resolution),
      resolved-at: (some current-block)
    }))
    (ok true)
  )
)
