;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname nbullets) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
(require 2htdp/universe)
(require 2htdp/image)

(define STARTING-BULLETS 10)

(define WIDTH 800)
(define HEIGHT 500)
(define SHIP-SPEED 4)
(define BULLET-SPEED 7)
(define TIME-LIMIT (* 28 180)); the 28 is the rate of ticks per second
(define SPAWN-INTERVAL (* 28 1)) ; between 1 and 3 ships spawn at the start of each interval
(define SHIP-COLOR "dark gray")
(define BULLET-COLOR "red")
(define SHIP-RADIUS 20)
(define GEN-0-BULLET-RADIUS 10)
(define BULLET-STEP 2) ; bullets are this step smaller than the bullet whose collision created them
(define MIN-BULLET-RADIUS 2) ; bullets will never be smaller than this, regardless of generation
(define MAX-BULLET-GENERATION (/ (- GEN-0-BULLET-RADIUS MIN-BULLET-RADIUS) BULLET-STEP))
; both the max-bullet-generation and min-bullet-radius are enforced,
; even though only one technically needs to be
(define PADDING 5) ; for the text
(define BG-COLOR "light blue")
(define FONT-SIZE 14)

(define CANNON
  (place-image
   (underlay
    (rectangle (* 2 GEN-0-BULLET-RADIUS) (/ HEIGHT 4) "solid" "red")
    (regular-polygon (/ HEIGHT 9) 6 "solid" "black"))
   (/ WIDTH 2) HEIGHT
   (empty-scene WIDTH HEIGHT "transparent")))

; A Posn is a (make-posn [x y])
(define POSN-ORIGIN (make-posn 0 0))
(define POSN-1 (make-posn 0 20))
(define POSN-2 (make-posn 10 50))
(define POSN-3 (make-posn 30 20))
(define POSN-4 (make-posn 100 50))
(define POSN-OFFSCREEN-LEFT (make-posn -100 50))
(define POSN-OFFSCREEN-RIGHT (make-posn (+ 50 WIDTH) 10))
(define POSN-OFFSCREEN-TOP (make-posn 30 -50))
(define POSN-OFFSCREEN-BOTTOM (make-posn 200 (+ 91 HEIGHT)))
(define (posn-temp p)
  ( ... (posn-x p) ... (posn-y p) ...))

(define-struct ship [loc angle])
; A Ship is a (make-ship Posn Number)
; Represents a ship (target) with
; -- loc: its center
; -- angle: the direction the ship is moving
(define SHIP-0 (make-ship POSN-ORIGIN 0))
(define SHIP-1 (make-ship POSN-1 180))
(define SHIP-1-MOVED (make-ship (make-posn (- 0 SHIP-SPEED) 20) 180))
(define SHIP-2 (make-ship POSN-2 0))
(define SHIP-2-MOVED (make-ship (make-posn (+ 10 SHIP-SPEED) 50) 0))
(define SHIP-3 (make-ship POSN-3 180))
(define (ship-temp s)
  (... (posn-temp (ship-loc s)) ... (ship-angle s) ... ))

(define-struct bullet [loc angle generation])
; A Bullet is a (make-bullet Posn Number Number)
; Represents a bullet, either one fired from the gun or
; created from a collision with a ship
; -- loc: its location
; -- angle: the angle relative to due right in degrees
; -- generation: gen 0 is fired from the gun,
;        gen 1 is from the collision of a ship and a gen 0 bullet,
;        gen 2 is from the collision with a gen 1 bullet
(define BULLET-0 (make-bullet POSN-ORIGIN 90 0))
(define BULLET-1 (make-bullet POSN-1 0 1))
(define BULLET-2 (make-bullet POSN-2 60 2))
(define (bullet-temp b)
  (... (posn-temp (bullet-loc b)) ...
       (bullet-angle b) ...
       (bullet-generation b) ...))

(define-struct game [bullets ships time score bullet-count])
; A Game is a (make-game [[List-of Bullet] [List-of Bullet] Nat Nat Nat])
; Represents a World with
; -- bullets : bullets on screen
; -- ships:  ships on screen
; -- time: the time remaining in ticks
; -- score: the score
; -- bullet-count: The amount of bullets remaining to be fired
(define GAME-0 (make-game '() '() TIME-LIMIT 0 STARTING-BULLETS))
(define GAME-1 (make-game (list BULLET-0 BULLET-1 BULLET-2) (list SHIP-0 SHIP-1) 50 3 4))
(define (game-temp g)
  (... (lo-bullet-temp (bullets g)) ...
       (lo-ship-temp (ships g)) ...
       (game-time g) ...
       (game-score g) ...
       (game-bullet-count g) ...))

; draw-world: Game -> Image
; draws a Game to the screen
(define (draw-world g)
  (underlay/align/offset
   "right" "top"
   (underlay/align/offset
    "center" "top"
    (underlay/align/offset
     "left" "top"
     (overlay
      CANNON
      (draw-bullets (game-bullets g))
      (draw-ships (game-ships g))
      (empty-scene WIDTH HEIGHT BG-COLOR))
     PADDING PADDING
     (draw-bullet-count (game-bullet-count g)))
    0 PADDING
    (draw-score (game-score g)))
   (- PADDING) PADDING
   (draw-time (game-time g))))

; draw-bullets: [List-of Bullet] -> Image
; Draws a list of bullets to a transparent empty scene
(check-expect (draw-bullets '())
              (empty-scene WIDTH HEIGHT "transparent"))
(check-expect (draw-bullets (list BULLET-1))
              (place-image
               (circle (bullet-radius 1) "solid" BULLET-COLOR)
               0 20
               (empty-scene WIDTH HEIGHT "transparent")))
(check-expect (draw-bullets (list BULLET-1 BULLET-0 BULLET-2))
              (overlay
               (place-image
                (circle (bullet-radius 1) "solid" BULLET-COLOR)
                0 20
                (empty-scene WIDTH HEIGHT "transparent"))
               (place-image
                (circle (bullet-radius 0) "solid" BULLET-COLOR )
                0 0
                (empty-scene WIDTH HEIGHT "transparent"))
               (place-image
                (circle (bullet-radius 2) "solid" BULLET-COLOR)
                10 50
                (empty-scene WIDTH HEIGHT "transparent"))))
(define (draw-bullets lob)
  (cond
    [(empty? lob) (empty-scene WIDTH HEIGHT "transparent")]
    [(cons? lob) (overlay (draw-bullet (first lob))
                          (draw-bullets (rest lob)))]))

; draw-bullet: Bullet -> Image
; Draws a bullet to a transparent empty scene
(check-expect (draw-bullet BULLET-1)
              (place-image
               (circle (bullet-radius 1) "solid" BULLET-COLOR)
               0 20
               (empty-scene WIDTH HEIGHT "transparent")))
(define (draw-bullet b)
  (place-image (circle
                (bullet-radius (bullet-generation b))
                "solid"
                BULLET-COLOR)
               (posn-x (bullet-loc b))
               (posn-y (bullet-loc b))
               (empty-scene WIDTH HEIGHT "transparent")))

; bullet-radius : Nat -> Nat
; Returns the bullet radius given a generation
(check-expect (bullet-radius 0) GEN-0-BULLET-RADIUS)
(check-expect (bullet-radius 2000) MIN-BULLET-RADIUS)
(check-expect (bullet-radius 1) (- GEN-0-BULLET-RADIUS BULLET-STEP))
(check-expect (bullet-radius 2) (- GEN-0-BULLET-RADIUS (* 2 BULLET-STEP)))
(define (bullet-radius gen)
  (max MIN-BULLET-RADIUS (- GEN-0-BULLET-RADIUS (* BULLET-STEP gen))))

; draw-ships: [List-of Ship] -> Image
; draw a list of ships to a transparent canvas
(check-expect (draw-ships '())
              (empty-scene WIDTH HEIGHT "transparent"))
(check-expect (draw-ships (list SHIP-1))
              (place-image
               (circle SHIP-RADIUS "solid" SHIP-COLOR)
               0 20
               (empty-scene WIDTH HEIGHT "transparent")))
(check-expect (draw-ships (list SHIP-0 SHIP-2 SHIP-3))
              (overlay
               (place-image
                (circle SHIP-RADIUS "solid" SHIP-COLOR)
                0 0
                (empty-scene WIDTH HEIGHT "transparent"))
               (place-image
                (circle SHIP-RADIUS "solid" SHIP-COLOR)
                10 50
                (empty-scene WIDTH HEIGHT "transparent"))
               (place-image
                (circle SHIP-RADIUS "solid" SHIP-COLOR)
                30 20
                (empty-scene WIDTH HEIGHT "transparent"))))
(define (draw-ships los)
  (cond
    [(empty? los) (empty-scene WIDTH HEIGHT "transparent")]
    [(cons? los) (overlay (draw-ship (first los))
                          (draw-ships (rest los)))]))
  
; draw-ship: Ship -> Image
; draws a ship to a transparent canvas
(check-expect (draw-ship SHIP-1)
              (place-image
               (circle SHIP-RADIUS "solid" SHIP-COLOR)
               0 20
               (empty-scene WIDTH HEIGHT "transparent")))
(check-expect (draw-ship SHIP-2)
              (place-image
               (circle SHIP-RADIUS "solid" SHIP-COLOR)
               10 50
               (empty-scene WIDTH HEIGHT "transparent")))
(define (draw-ship s)
  (place-image (circle SHIP-RADIUS "solid" SHIP-COLOR)
               (posn-x (ship-loc s))
               (posn-y (ship-loc s))
               (empty-scene WIDTH HEIGHT "transparent")))

; draw-bullet-count: Nat -> Image
; draws the amount of bullets remaining
(check-expect (draw-bullet-count 5)
              (text "Bullets left: 5" FONT-SIZE "red"))
(check-expect (draw-bullet-count 0)
              (text "Bullets left: 0" FONT-SIZE "red"))
(define (draw-bullet-count bc)
  (text (string-append "Bullets left: " (number->string bc)) FONT-SIZE "red"))

; draw-score: Nat -> Image
; draws the scoreboard
(check-expect (draw-score 10)
              (text "Score: 10" FONT-SIZE "black"))
(check-expect (draw-score 0)
              (text "Score: 0" FONT-SIZE "black"))
(define (draw-score score)
  (text (string-append "Score: " (number->string score)) FONT-SIZE "black"))

; draw-time: Nat -> Image
; draws the amount of time remaining, converting ticks to seconds
(check-expect (draw-time 840)
              (text "30s" FONT-SIZE "blue"))
(check-expect (draw-time 1)
              (text "1s" FONT-SIZE "blue"))
(define (draw-time t)
  (text (string-append (number->string (ceiling (/ t 28))) "s") FONT-SIZE "blue"))



; tick-world: Game -> Game
; Updates game state on tick
; updates time, updates score, filters projectiles, explodes projectiles
(check-expect (tick-world (make-game '() '() 19 0 0)) (make-game '() '() 18 0 0))
(check-random (tick-world (make-game '() (list SHIP-2) SPAWN-INTERVAL 0 0))
              (make-game '() (cons (move-ship SHIP-2) (spawn-ships 0)) (sub1 SPAWN-INTERVAL) 0 0))
(check-within (tick-world
               (make-game
                (list (make-bullet POSN-OFFSCREEN-TOP 90 0)
                      (make-bullet POSN-OFFSCREEN-LEFT 180 1)
                      (make-bullet POSN-OFFSCREEN-RIGHT 45 2)
                      (make-bullet POSN-OFFSCREEN-BOTTOM 45 3)
                      (make-bullet POSN-3 0 1)
                      (make-bullet POSN-2 45 0)
                      (make-bullet POSN-2 0 1)
                      (make-bullet POSN-4 0 1))
                (list (make-ship POSN-2 0)
                      (make-ship POSN-3 180)
                      (make-ship POSN-1 0 ))
                29 5 5))
              (make-game
               (list (make-bullet (move-posn POSN-3 0 BULLET-SPEED) 0 2)
                     (make-bullet (move-posn POSN-3 120 BULLET-SPEED) 120 2)
                     (make-bullet (move-posn POSN-3 240 BULLET-SPEED) 240 2)
                     (make-bullet (move-posn POSN-2 0 BULLET-SPEED) 0 1)
                     (make-bullet (move-posn POSN-2 180 BULLET-SPEED) 180 1)
                     (make-bullet (move-posn POSN-2 0 BULLET-SPEED) 0 2)
                     (make-bullet (move-posn POSN-2 120 BULLET-SPEED) 120 2)
                     (make-bullet (move-posn POSN-2 240 BULLET-SPEED) 240 2)
                     (make-bullet (move-posn POSN-4 0 BULLET-SPEED) 0 1))
               (list (make-ship (move-posn POSN-1 0 SHIP-SPEED) 0))
               28 7 5) 0.001)
(define (tick-world g)
  (make-game
   (tick-bullets (game-bullets g) (game-ships g))
   (append
    (tick-ships (game-ships g) (game-bullets g))
    (spawn-ships (game-time g)))
   (sub1 (game-time g))
   (+ (game-score g) (count-hits (game-bullets g) (game-ships g)))
   (game-bullet-count g)))


; tick-bullets: [List-of Bullet] [List-of Ship] -> [List-of Bullet]
; alters bullets appropriately for one tick
(check-expect (tick-bullets '() (list SHIP-1 SHIP-2)) '())
(check-within (tick-bullets
               (list
                (make-bullet (make-posn 20 30) 0 1)
                (make-bullet (make-posn 22 31) 120 2)
                (make-bullet POSN-OFFSCREEN-LEFT 90 0)
                (make-bullet POSN-OFFSCREEN-RIGHT 120 2)
                (make-bullet (make-posn 50 70) 90 3))
               (list
                (make-ship (make-posn 19 30) 180)))
              (list
               (make-bullet (make-posn (+ 20 BULLET-SPEED) 30) 0 2)
               (make-bullet (move-posn (make-posn 20 30) 120 BULLET-SPEED ) 120 2)
               (make-bullet (move-posn (make-posn 20 30) 240 BULLET-SPEED) 240 2)
               (make-bullet (make-posn (+ 22 BULLET-SPEED) 31) 0 3)
               (make-bullet (make-posn 22 (- 31 BULLET-SPEED)) 90 3)
               (make-bullet (make-posn (- 22 BULLET-SPEED) 31) 180 3)
               (make-bullet (make-posn 22 (+ 31 BULLET-SPEED)) 270 3)
               (make-bullet (make-posn 50 (- 70 BULLET-SPEED)) 90 3)) 0.001)
(define (tick-bullets bullets ships)
  ( (explode-bullets (filter bullet-onscreen? bullets) ships)))

; move-bullet: Bullet -> Bullet
; moves a bullet for one tick
(check-within (move-bullet (make-bullet (make-posn 4 5) 90 0))
              (make-bullet (make-posn 4 (- 5 BULLET-SPEED)) 90 0) 0.0001)
(define (move-bullet b)
  (make-bullet (move-posn (bullet-loc b) (bullet-angle b) BULLET-SPEED)
               (bullet-angle b)
               (bullet-generation b)))

; move-posn : Posn Number Nat -> Posn
; moves a posn for one tick of time given its trajectory and speed
(check-within (move-posn (make-posn 20 30) 90 5)
              (make-posn 20 25) 0.0001)
(check-expect (move-posn (make-posn 10 20) 0 3)
              (make-posn 13 20))
(define (move-posn p angle speed)
  (make-posn (+ (posn-x p) (* speed (cos (* (/ pi 180) angle))))
             (+ (posn-y p) (* speed (sin (* (/ pi 180) -1 angle))))))

; bullet-onscreen? : Bullet -> Boolean
; Returns whether a Bullet is at least partially on screen
(check-expect (bullet-onscreen?
               (make-bullet POSN-OFFSCREEN-TOP 90 0)) #false)
(check-expect (bullet-onscreen?
               (make-bullet POSN-3 90 0)) #true)
(define (bullet-onscreen? b)
  (onscreen? (bullet-loc b) (bullet-radius (bullet-generation b))))

; onscreen? : Posn radius -> Boolean
; Returns whether a square with sides "radius" away from
; a point would include or border a point on screen.
(check-expect (onscreen? (make-posn -5 1) 5) #true)
(check-expect (onscreen? (make-posn -5 1) 4) #false)
(check-expect (onscreen? (make-posn -5 1) 6) #true) 
(check-expect (onscreen? (make-posn 1 -4) 4) #true)
(check-expect (onscreen? (make-posn 1 -4) 3) #false)
(check-expect (onscreen? (make-posn 1 -6) 7) #true)
(check-expect (onscreen? (make-posn (+ WIDTH 40) 1) 40) #true)
(check-expect (onscreen? (make-posn (+ WIDTH 40) 1) 39) #false)
(check-expect (onscreen? (make-posn (+ WIDTH 40) 1) 41) #true)
(check-expect (onscreen? (make-posn 1 (+ HEIGHT 34)) 34) #true)
(check-expect (onscreen? (make-posn 1 (+ HEIGHT 34)) 33) #false)
(check-expect (onscreen? (make-posn 1 (+ HEIGHT 34)) 35) #true)
(define (onscreen? p radius)
  (and
   (>= (+ (posn-x p) radius) 0)
   (<= (- (posn-x p) radius) WIDTH)
   (>= (+ (posn-y p) radius) 0)
   (<= (- (posn-y p) radius) HEIGHT)))

; explode-bullets : [List-of Bullet] [List-of Ship] -> [List-of Bullet]
; creates a new list of bullets based on which need to be turned into fragments
;;  because they are colliding with a ship.
(check-expect (explode-bullets '() (list SHIP-1 SHIP-2)) '())
(check-expect (explode-bullets (list (make-bullet POSN-1 180 1)) '())
              (list (make-bullet POSN-1 180 1)))
(check-expect (explode-bullets (list (make-bullet POSN-1 90 0)) (list (make-ship POSN-1 0)))
              (list (make-bullet POSN-1 0 1) (make-bullet POSN-1 180 1)))
(define (explode-bullets lob los)
  (cond
    [(empty? lob) '()]
    [else (append
           (explode-bullet (first lob) los)
           (explode-bullets (rest lob) los))]))

; explode-bullet: Bullet [List-of Ship] -> [List-of Bullet]
; returns the list of bullets which results from interactions with the ship,
;; either a list with just the bullet or the list of bullets formed as a result
;; of the collision
(check-expect (explode-bullet (make-bullet POSN-1 90 0)
                              (list (make-ship POSN-1 0) (make-ship POSN-1 180)))
              (list (make-bullet POSN-1 0 1) (make-bullet POSN-1 180 1)))
(check-expect (explode-bullet (make-bullet POSN-1 90 0)
                              (list (make-ship POSN-4 0)))
              (list (make-bullet POSN-1 90 0)))
(define (explode-bullet b los)
  (if (ormap (lambda (s) (collision? b s)) los)
      (bullet-fragments b)
      (list b)))

; collision? : Bullet Ship -> Boolean
; returns whether the bullet and ship intersect,
(check-expect (collision? (make-bullet (make-posn 34 45) 90 50)
                          (make-ship (make-posn 33 45) 180))
              #true)
(check-expect (collision? (make-bullet (make-posn 34 45) 90 50)
                          (make-ship (make-posn 34 45) 180))
              #true)
(check-expect (collision? (make-bullet (make-posn 43 23) 90 0)
                          (make-ship (make-posn 43 (+ 23 -1 SHIP-RADIUS GEN-0-BULLET-RADIUS)) 0))
              #true)
(check-expect (collision? (make-bullet (make-posn 43 23) 90 0)
                          (make-ship (make-posn 43 (+ 23 SHIP-RADIUS GEN-0-BULLET-RADIUS)) 0))
              #false)
(check-expect (collision? (make-bullet (make-posn 40 20) 120 2)
                          (make-ship (make-posn 0 0) 0))
              #false)           
(define (collision? b s)
  (> (+ SHIP-RADIUS (bullet-radius (bullet-generation b)))
     (distance (bullet-loc b) (ship-loc s))))

; distance : Posn Posn -> Number
; returns the distance between two points
(check-within (distance (make-posn 45 32) (make-posn -4 15)) 51.8652 0.00005)
(check-expect (distance (make-posn 2 5) (make-posn -1 1)) 5)
(define (distance p1 p2)
  (sqrt (+ (expt (- (posn-x p1) (posn-x p2)) 2) (expt (- (posn-y p1) (posn-y p2)) 2))))

; bullet-fragments : Bullet -> [List-of Bullet]
; returns the list of bullets generated following a collision
(check-expect (bullet-fragments (make-bullet POSN-3 90 0))
              (list (make-bullet POSN-3 0 1) (make-bullet POSN-3 180 1)))
(check-expect (bullet-fragments (make-bullet POSN-2 180 1))
              (list (make-bullet POSN-2 0 2) (make-bullet POSN-2 120 2) (make-bullet POSN-2 240 2)))
(define (bullet-fragments b)
  (bullet-fragments-helper b 0))

; bullet-fragments-helper : Bullet Number -> [List-of Bullet]
; returns the bullets generated from a collision involving the given bullet
; omitting the first i bullets
(check-expect (bullet-fragments-helper (make-bullet POSN-1 90 0) 2) '())
(check-expect (bullet-fragments-helper (make-bullet POSN-2 0 1) 0)
              (list (make-bullet POSN-2 0 2) (make-bullet POSN-2 120 2) (make-bullet POSN-2 240 2)))
(check-expect (bullet-fragments-helper (make-bullet POSN-2 180 2) 2)
              (list (make-bullet POSN-2 180 3) (make-bullet POSN-2 270 3)))
(check-expect (bullet-generation
               (first (bullet-fragments-helper (make-bullet POSN-2 180 MAX-BULLET-GENERATION) 2)))
              MAX-BULLET-GENERATION)
(define (bullet-fragments-helper b i)
  (if (>= i (+ 2 (bullet-generation b)))
      '()
      (cons (make-bullet
             (bullet-loc b)
             (* i (/ 360 (+ 2 (bullet-generation b))))
             (min MAX-BULLET-GENERATION (add1 (bullet-generation b))))
            (bullet-fragments-helper b (add1 i)))))


; tick-ships : [List-of Ship] [List-of Bullet] -> [List-of Ship]
; moves and removes ships appropriately for one tick
(check-expect (tick-ships '() '()) '())
(check-within (tick-ships (list SHIP-1 SHIP-2 (make-ship POSN-OFFSCREEN-RIGHT 180)) '())
              (list SHIP-1-MOVED SHIP-2-MOVED) 0.001)
(check-expect (tick-ships (list SHIP-1 SHIP-2) (list BULLET-1)) (list SHIP-2-MOVED))
(define (tick-ships ships bullets)
  (map move-ship
       (filter ship-onscreen?
               (filter (lambda (s) (andmap (λ (b) (not (collision? b s))) bullets))
                       ships))))

; move-ship : Ship -> Ship
; moves the ship for one tick
(check-expect (move-ship (make-ship (make-posn 5 4) 0))
              (make-ship (make-posn (+ SHIP-SPEED 5) 4) 0))
(check-within (move-ship (make-ship (make-posn 40 20) 180))
              (make-ship (make-posn (- 40 SHIP-SPEED) 20) 180) 0.0001)
(define (move-ship s)
  (make-ship (move-posn (ship-loc s) (ship-angle s) SHIP-SPEED) (ship-angle s)))

; ship-onscreen? : Ship -> Boolean
; Returns whether a Ship is at least partially on screen
(check-expect (ship-onscreen?
               (make-ship POSN-OFFSCREEN-LEFT 180)) #false)
(check-expect (ship-onscreen?
               (make-ship POSN-1 90)) #true)
(define (ship-onscreen? s)
  (onscreen? (ship-loc s) SHIP-RADIUS))

; spawn-ships: Number -> [List-of Ship]
; Spawns a random arrangement of ships if at the start of an interval, or returns '() otherwise
(check-within (length (spawn-ships 0)) 2 1)
(check-expect (ship? (first (spawn-ships 0))) #true)
(check-within (length (spawn-ships SPAWN-INTERVAL)) 2 1)
(check-expect (ship? (first (spawn-ships 0))) #true)
(check-expect (spawn-ships (sub1 SPAWN-INTERVAL)) '())
(define (spawn-ships tick)
  (if (= 0 (modulo tick SPAWN-INTERVAL )) 
      (local [(define rand (add1 (random 3)))]
        (spawn-ships-helper rand))
      '()))

; spawn-ships-helper: Number -> [List-of Ship]
; Spawns the given number of random ships
(check-expect (length (spawn-ships-helper 5)) 5)
(check-expect (spawn-ships-helper 0) '())
(check-expect (ship? (first (spawn-ships-helper 1))) #true)
(define (spawn-ships-helper i)
  (if(< i 1) '()
     (local [(define rand-bool (random 2))]
       (cons
        (make-ship
         (make-posn (if (= 1 rand-bool) (+ SHIP-RADIUS WIDTH) (- SHIP-RADIUS))
                    (+ (ceiling (/ HEIGHT 7)) (random (floor (* 5 (/ HEIGHT 7))))))
         (* 180 rand-bool ))
        (spawn-ships-helper (sub1 i))))))

; count-hits: [List-of Bullet] [List-of Ship] -> Nat
; Returns the number of ships with at least one bullet intersecting them
(check-expect (count-hits (list (make-bullet POSN-1 45 5)
                                (make-bullet POSN-1 30 2)
                                (make-bullet POSN-1 0 1))
                          (list (make-ship POSN-1 0)
                                (make-ship POSN-4 180)))
              1)
(check-expect (count-hits (list (make-bullet POSN-1 45 5))
                          (list (make-ship POSN-1 0)
                                (make-ship POSN-1 180)
                                (make-ship POSN-4 180)))
              2)
(check-expect (count-hits (list (make-bullet POSN-1 45 5)
                                (make-bullet POSN-4 45 3))
                          (list (make-ship POSN-1 0)
                                (make-ship POSN-1 180)
                                (make-ship POSN-OFFSCREEN-TOP 180)
                                (make-ship POSN-4 180)))
              3)                    
(define (count-hits lob los)
  (cond
    [(empty? los) 0]
    [else (+
           (if (ormap (lambda (b) (collision? b (first los))) lob) 1 0)
           (count-hits lob (rest los)))]))

; handle-key: Game -> Game
; generates a new bullet when the user presses the space bar
(check-expect (handle-key GAME-1 "a") GAME-1)
(check-expect (handle-key (make-game '() '() 0 30 10) " ")
              (make-game (list (make-bullet
                                (make-posn (/ WIDTH 2) (+ HEIGHT GEN-0-BULLET-RADIUS))
                                90
                                0))
                         '() 0 30 9))
(check-expect (handle-key (make-game (list BULLET-2 BULLET-1) (list SHIP-2) 5 1 7) " ")
              (make-game (list (make-bullet
                                (make-posn (/ WIDTH 2) (+ HEIGHT GEN-0-BULLET-RADIUS))
                                90
                                0) BULLET-2 BULLET-1)
                         (list SHIP-2) 5 1 6))
(check-expect (handle-key (make-game '() '() 5 1 0) " ")
              (make-game '() '() 5 1 0))
(define (handle-key g key)
  (cond
    [(and (key=? key " ") (> (game-bullet-count g) 0))
     (make-game
      (cons (make-bullet
             (make-posn (/ WIDTH 2) (+ HEIGHT GEN-0-BULLET-RADIUS))
             90 0)
            (game-bullets g))
      (game-ships g)
      (game-time g)
      (game-score g)
      (sub1 (game-bullet-count g)))]
    [else g]))

; should-I-stop? : Game -> Boolean
; returns whether the clock is run out,
; or the user is both out of bullets and there are no bullets on screen
(check-expect (should-I-stop? (make-game (list BULLET-1) '() 1 0 0)) #false)
(check-expect (should-I-stop? (make-game '() '() 1 0 1)) #false)
(check-expect (should-I-stop? (make-game (list BULLET-1 BULLET-2) '() 0 0 3)) #true)
(check-expect (should-I-stop? (make-game '() '() 10 10 0)) #true)
(define (should-I-stop? g)
  (or (and (< (game-bullet-count g) 1) (empty? (game-bullets g)))
      (<= (game-time g) 0)))

; end-scene : Game -> Image
; draws the final scene of the game
(check-expect (end-scene GAME-0)
              (overlay (text (string-append "Final Score: 0") (* 2 FONT-SIZE) "black")
                       (empty-scene WIDTH HEIGHT BG-COLOR)))
(check-expect (end-scene GAME-1)
              (overlay (text (string-append "Final Score: 3") (* 2 FONT-SIZE) "black")
                       (empty-scene WIDTH HEIGHT BG-COLOR)))
(define (end-scene g)
  (overlay (text (string-append "Final Score: " (number->string (game-score g)))
                 (* 2 FONT-SIZE)
                 "black")
           (empty-scene WIDTH HEIGHT BG-COLOR)))

(big-bang GAME-0
  [to-draw draw-world]
  [on-tick tick-world]
  [on-key handle-key]
  [stop-when should-I-stop? end-scene])