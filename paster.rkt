#lang racket/gui
(module+ test
  (require rackunit))

;;; purpose

; Quickly paste items into the clipboard from an easy to resize panel.
; Add an item from the clipboard using the '+' button.

;;; version history

; v1.0 - initial release.

;;; consts

(define *version* "1.0")
(define *app-name* (string-append "Paster v" *version*))
(define *min-button-size* 256)
(define *max-button-size* 1024)
(define *default-font-size* 10)

;;; defs

;; initialize button list
(define main-frame #f)
(define button-list #f)

;; returns the clipboard's contents as string
(define (get-clipboard-text)
  (send the-clipboard get-clipboard-string 0))

;; sets the clipboard's contents given a string
(define (set-clipboard-text s)
  (send the-clipboard set-clipboard-string s 0))

;; Generic confirmation dialog
(define (show-confirmation-dialog message)
  (if (equal? (message-box *app-name* message #f (list 'yes-no 'caution)) 'yes)
      #t
      #f))

;; displays an error and quits
(define die
  (λ args
    (void (message-box *app-name* (string-append (apply ~a args) "  ") #f (list 'stop)))
    (exit 1)))

;; generates a small frame to fill with controls
;; traps mouse click events and quits cleanly
(define (make-elastic-frame appname)
  (new (class frame% (super-new)
         (define/augment (on-close)
           (exit 0))
         (define/override (on-subwindow-event r e)
           (define control-label (send r get-label))
           (if (send e button-up? 'right)
               (unless (string=? control-label "+")
                 (send main-frame delete-child r)
                 (set! button-list (remove r button-list)))
               #f)))
       [label appname]
       [width 0]
       [height 0]
       [stretchable-width 1024]
       [stretchable-height #f]))

;; re-order buttons in the button list order
(define (reorder-buttons)
  (send main-frame change-children
        (λ (children) button-list)))

;;; main

;; create a resizable frame for our buttons
(set! main-frame (make-elastic-frame *app-name*))

;; defines what happens when one clicks on a paste button:
;; sets the clipboard with the button's content.
(define (paste-button-callback clip)
  (set-clipboard-text clip))

;; defines what happens when one clicks on the '+' button:
;; reads the clipboard, if non-empty grab a portion of it as title for a new button.
(define (add-button-callback)
  (let/cc return
    (define clip (get-clipboard-text))
    (when (not (non-empty-string? clip))
      (return #f))
    (define title-len
      (if (< (string-length clip) 32)
          (string-length clip)
          32))
    (define button-title (substring clip 0 title-len))
    (define new-button
      (new button%
           [label button-title]
           [parent main-frame]
           [min-width *min-button-size*]
           [stretchable-width *max-button-size*]
           [min-height 24]
           [stretchable-height #f]
           [font (make-object font% *default-font-size* 'swiss 'normal 'bold)]
           [callback (λ (b e) (paste-button-callback clip))]))
    (set! button-list (cons new-button button-list))
    (reorder-buttons)))

;; add a '+' button to the window
(define add-button
  (new button%
       [label "+"]
       [parent main-frame]
       [min-width *min-button-size*]
       [stretchable-width *max-button-size*]
       [min-height 24]
       [stretchable-height #f]
       [font (make-object font% *default-font-size* 'swiss 'normal 'bold)]
       [callback (λ (b e) (add-button-callback))]))

;; initialize button list with the add button alone
(set! button-list
      (list add-button))

;; display the window
(send main-frame show #t)


; EOF