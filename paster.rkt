#lang racket/gui
(require file/resource)
(module+ test
  (require rackunit))

;;; purpose

; Quickly paste items into the clipboard from an easy to resize panel.
; Add an item from the clipboard using the '+' button.

;;; configuration

; a config file (paster.conf) can optionally be provided, and paster will create buttons for each string in it.
; passwords can be partially hidden if their config line starts with "* ".

;;; version history

; v1.1 - added support for reading the initial clips off an optional configuration file.
; v1.0 - initial release.

;;; consts

(define *version* "1.1")
(define *app-maker* "Gluten Free Software")
(define *app-name* "Paster")
(define *min-button-size* 220)
(define *max-button-size* 1024)
(define *max-title-length* 64)
(define *default-font-size* 10)
(define *default-config-file* "paster.conf")

;;; defs

;; initialize button list
(define main-frame #f)
(define button-list '())

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

;; generates a small frame to fill with controls
;; traps mouse click events and quits cleanly
(define (make-elastic-frame appname x-pos y-pos)
  (new (class frame% (super-new)
         (define/augment (on-close)
           (set-saved-window-pos *app-maker* *app-name*
                                 (send main-frame get-x)
                                 (send main-frame get-y))
           (exit 0))
         (define/override (on-subwindow-event r e)
           (define control-label (send r get-label))
           (if (send e button-up? 'right)
               (unless (string=? control-label "+")
                 (when (show-confirmation-dialog "Delete clip?")
                   (send main-frame delete-child r)
                   (set! button-list (remove r button-list))))
               #f)))
       [label appname]
       [x x-pos]
       [y y-pos]
       [width 0]
       [height 0]
       [stretchable-width 1024]
       [stretchable-height #f]))

;; re-order buttons in the button list order
(define (reorder-buttons)
  (send main-frame change-children
        (λ (children) button-list)))

;; adds a button given a string used as both clipping and title
;; optionally hides secret text behind stars
(define (add-a-button str password?)
  (when (non-empty-string? str)
    (define title-len
      (if (< (string-length str) *max-title-length*)
          (string-length str)
          *max-title-length*))
    (define button-title
      ; if the clip is a password, hide the middle of it behind stars
      (if password?
          (string-append (substring str 0 1)
                         (make-string (- title-len 2) #\*)
                         (substring str (- title-len 1) title-len))
          (substring str 0 title-len)))
    (define new-button
      (new button%
           [label button-title]
           [parent main-frame]
           [min-width *min-button-size*]
           [stretchable-width *max-button-size*]
           [min-height 24]
           [stretchable-height #f]
           [font (make-object font% *default-font-size* 'swiss 'normal 'bold)]
           [callback (λ (b e) (paste-button-callback str))]))
    (set! button-list
          (cons new-button button-list))))

;; defines what happens when one clicks on a paste button:
;; sets the clipboard with the button's content.
(define (paste-button-callback clip)
  (set-clipboard-text clip))

;; defines what happens when one clicks on the '+' button:
;; reads the clipboard, if non-empty grab a portion of it as title for a new button.
(define (add-button-callback)
  (add-a-button (get-clipboard-text) #f)
  (reorder-buttons))

;; load x and y window position from the registry. Returns #f if not available
(define (get-saved-window-pos app-maker app-name)
  (values (get-resource "HKEY_CURRENT_USER"
                        (string-append "Software\\" app-maker "\\" app-name "\\x-pos")
                        #f #f #:type 'integer)
          (get-resource "HKEY_CURRENT_USER"
                        (string-append "Software\\" app-maker "\\" app-name "\\y-pos")
                        #f #f #:type 'integer)))

;; save x and y window position to the registry on Windows only
(define (set-saved-window-pos app-maker app-name x-pos y-pos)
  (values (write-resource "HKEY_CURRENT_USER"
                          (string-append "Software\\" app-maker "\\" app-name "\\x-pos")
                          x-pos #f #:type 'dword #:create-key? #t)
          (write-resource "HKEY_CURRENT_USER"
                          (string-append "Software\\" app-maker "\\" app-name "\\y-pos")
                          y-pos #f #:type 'dword #:create-key? #t)))

;;; main

; load window position from the registry, on Windows only
(define-values (x-pos y-pos)
  (get-saved-window-pos *app-maker* *app-name*))

; create a resizable frame for our buttons
(set! main-frame
      (make-elastic-frame *app-name* x-pos y-pos))

; add a '+' button to the window
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

; load config file if it exists
(when (and (file-exists? *default-config-file*)
           (non-empty-string? (file->string *default-config-file*)))
  (define lines (file->lines *default-config-file*))
  (when (cons? lines)
    (map (λ (l)
           (if (string-prefix? l "* ")
               (add-a-button (string-replace l "* " "") #t)
               (add-a-button l #f))) (reverse lines)))
  (reorder-buttons))

; initialize button list with the add button alone
(set! button-list
      (append button-list (list add-button)))

; display the window
(send main-frame show #t)


; EOF
