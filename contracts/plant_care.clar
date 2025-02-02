;; SproutFlow Plant Care Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-invalid-plant (err u101)) 
(define-constant err-invalid-tip (err u102))
(define-constant err-already-voted (err u103))
(define-constant achievement-reward-threshold u5)

;; Define token for community rewards
(define-fungible-token sprout-token)

;; Data structures
(define-map plants 
  { plant-id: uint }
  {
    owner: principal,
    name: (string-ascii 50),
    care-schedule: (string-ascii 500),
    created-at: uint
  }
)

(define-map gardening-tips
  { tip-id: uint }
  {
    author: principal,
    content: (string-ascii 500),
    votes: uint,
    voters: (list 50 principal),
    created-at: uint
  }
)

(define-map user-achievements
  { user: principal }
  {
    plants-added: uint,
    tips-shared: uint,
    total-votes: uint
  }
)

(define-data-var last-plant-id uint u0)
(define-data-var last-tip-id uint u0)

;; Plant management functions
(define-public (add-plant (name (string-ascii 50)) (care-schedule (string-ascii 500)))
    (let
        (
            (new-id (+ (var-get last-plant-id) u1))
        )
        (try! (map-insert plants
            { plant-id: new-id }
            {
                owner: tx-sender,
                name: name,
                care-schedule: care-schedule,
                created-at: block-height
            }
        ))
        (var-set last-plant-id new-id)
        (update-achievement tx-sender)
        (ok new-id)
    )
)

;; Community tips functions
(define-public (submit-tip (content (string-ascii 500)))
    (let
        (
            (new-id (+ (var-get last-tip-id) u1))
        )
        (try! (map-insert gardening-tips
            { tip-id: new-id }
            {
                author: tx-sender,
                content: content,
                votes: u0,
                voters: (list),
                created-at: block-height
            }
        ))
        (var-set last-tip-id new-id)
        (ok new-id)
    )
)

(define-public (vote-for-tip (tip-id uint))
    (let
        (
            (tip (unwrap! (map-get? gardening-tips {tip-id: tip-id}) err-invalid-tip))
            (current-votes (get votes tip))
            (voters (get voters tip))
        )
        (asserts! (is-none (index-of voters tx-sender)) err-already-voted)
        (map-set gardening-tips
            {tip-id: tip-id}
            (merge tip {
              votes: (+ current-votes u1),
              voters: (unwrap! (as-max-len? (append voters tx-sender) u50) err-invalid-tip)
            })
        )
        ;; Reward tip author
        (try! (ft-mint? sprout-token u1 (get author tip)))
        (ok true)
    )
)

;; Achievement tracking with rewards
(define-private (update-achievement (user principal))
    (let
        (
            (current-achievements (default-to
                {plants-added: u0, tips-shared: u0, total-votes: u0}
                (map-get? user-achievements {user: user})
            ))
            (new-plants-added (+ (get plants-added current-achievements) u1))
        )
        (map-set user-achievements
            {user: user}
            (merge current-achievements {plants-added: new-plants-added})
        )
        ;; Reward users for reaching achievement milestones
        (if (and 
            (> new-plants-added u0)
            (is-eq (mod new-plants-added achievement-reward-threshold) u0))
            (try! (ft-mint? sprout-token u5 user))
            (ok true)
        )
    )
)

;; Read only functions
(define-read-only (get-plant (plant-id uint))
    (ok (map-get? plants {plant-id: plant-id}))
)

(define-read-only (get-tip (tip-id uint))
    (ok (map-get? gardening-tips {tip-id: tip-id}))
)

(define-read-only (get-user-achievements (user principal))
    (ok (map-get? user-achievements {user: user}))
)
