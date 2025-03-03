;; SproutFlow Plant Care Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-plant (err u101))
(define-constant err-invalid-tip (err u102))
(define-constant err-already-voted (err u103))
(define-constant err-max-plants-reached (err u104))
(define-constant err-invalid-content (err u105))
(define-constant err-contract-paused (err u106))
(define-constant err-invalid-input (err u107))

(define-constant achievement-reward-threshold u5)
(define-constant max-plants-per-user u50)
(define-constant max-achievement-tier u10)

;; Define token for community rewards
(define-fungible-token sprout-token)

;; Contract status
(define-data-var contract-paused bool false)

;; Helper functions
(define-private (is-valid-string (input (string-ascii 500)))
  (not (is-eq input ""))
)

(define-private (distribute-achievement-rewards (user principal))
  (let (
    (achievements (default-to { plants-added: u0, tips-shared: u0, total-votes: u0, achievement-tier: u0 }
      (map-get? user-achievements { user: user })))
    (current-tier (get achievement-tier achievements))
    (new-tier (min max-achievement-tier (/ (get plants-added achievements) achievement-reward-threshold)))
  )
    (if (> new-tier current-tier)
      (begin
        (try! (ft-mint? sprout-token (* (- new-tier current-tier) u5) user))
        (ok true)
      )
      (ok false)
    )
  )
)

;; [Previous data structures remain unchanged...]

;; Plant management functions
(define-public (add-plant (name (string-ascii 50)) (category (string-ascii 20)) (care-schedule (string-ascii 500)))
  (let
    (
      (new-id (+ (var-get last-plant-id) u1))
      (user-plants (default-to { count: u0 } (map-get? user-plant-count {user: tx-sender})))
    )
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (is-valid-string name) err-invalid-input)
    (asserts! (is-valid-string category) err-invalid-input)
    (asserts! (is-valid-string care-schedule) err-invalid-input)
    (asserts! (< (get count user-plants) max-plants-per-user) err-max-plants-reached)
    (try! (map-insert plants
      { plant-id: new-id }
      {
        owner: tx-sender,
        name: name,
        category: category,
        care-schedule: care-schedule,
        created-at: block-height
      }
    ))
    (map-set user-plant-count 
      {user: tx-sender}
      {count: (+ (get count user-plants) u1)}
    )
    (var-set last-plant-id new-id)
    (try! (log-event "plant_added" tx-sender (concat name " added")))
    (try! (update-achievement tx-sender))
    (try! (distribute-achievement-rewards tx-sender))
    (ok new-id)
  )
)

;; Tip management functions
(define-public (add-tip (content (string-ascii 500)))
  (let
    ((new-id (+ (var-get last-tip-id) u1)))
    (asserts! (not (var-get contract-paused)) err-contract-paused)
    (asserts! (is-valid-string content) err-invalid-input)
    (try! (map-insert gardening-tips
      { tip-id: new-id }
      {
        author: tx-sender,
        content: content,
        votes: u0,
        voters: (list),
        created-at: block-height,
        edited: false,
        version: u1
      }
    ))
    (var-set last-tip-id new-id)
    (try! (log-event "tip_added" tx-sender content))
    (ok new-id)
  )
)

;; [Previous functions remain unchanged...]
