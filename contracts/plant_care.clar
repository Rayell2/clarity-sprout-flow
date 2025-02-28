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

(define-constant achievement-reward-threshold u5)
(define-constant max-plants-per-user u50)

;; Define token for community rewards
(define-fungible-token sprout-token)

;; Contract status
(define-data-var contract-paused bool false)

;; Data structures
(define-map plants 
  { plant-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    category: (string-ascii 20),
    care-schedule: (string-ascii 500),
    created-at: uint
  }
)

(define-map user-plant-count
  { user: principal }
  { count: uint }
)

(define-map gardening-tips
  { tip-id: uint }
  {
    author: principal,
    content: (string-ascii 500),
    votes: uint,
    voters: (list 50 principal),
    created-at: uint,
    edited: bool,
    version: uint
  }
)

(define-map user-achievements
  { user: principal }
  {
    plants-added: uint,
    tips-shared: uint,
    total-votes: uint,
    achievement-tier: uint
  }
)

(define-data-var last-plant-id uint u0)
(define-data-var last-tip-id uint u0)

;; Events
(define-data-var last-event-id uint u0)
(define-map events
  { event-id: uint }
  {
    event-type: (string-ascii 20),
    user: principal,
    data: (string-ascii 500),
    block: uint
  }
)

;; Administrative functions
(define-public (toggle-contract-pause)
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (ok (var-set contract-paused (not (var-get contract-paused))))
  )
)

;; Plant management functions
(define-public (add-plant (name (string-ascii 50)) (category (string-ascii 20)) (care-schedule (string-ascii 500)))
  (let
    (
      (new-id (+ (var-get last-plant-id) u1))
      (user-plants (default-to { count: u0 } (map-get? user-plant-count {user: tx-sender})))
    )
    (asserts! (not (var-get contract-paused)) err-contract-paused)
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
    (log-event "plant_added" tx-sender (concat name " added"))
    (update-achievement tx-sender)
    (ok new-id)
  )
)

;; Event logging
(define-private (log-event (event-type (string-ascii 20)) (user principal) (data (string-ascii 500)))
  (let
    ((new-id (+ (var-get last-event-id) u1)))
    (map-set events
      {event-id: new-id}
      {
        event-type: event-type,
        user: user,
        data: data,
        block: block-height
      }
    )
    (var-set last-event-id new-id)
    (ok new-id)
  )
)

;; [Previous functions remain unchanged...]
