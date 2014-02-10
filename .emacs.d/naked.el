;; Prevent the cursor from blinking
(blink-cursor-mode 0)
;; Don't use messages that you don't read
(setq initial-scratch-message "")
(setq inhibit-startup-message t)
;; Don't let Emacs hurt your ears
(setq visible-bell t)

;; You need to set `inhibit-startup-echo-area-message' from the
;; customization interface:
;; M-x customize-variable RET inhibit-startup-echo-area-message RET
;; then enter your username
(setq inhibit-startup-echo-area-message "guerry")

;; This is bound to f11 in Emacs
(toggle-frame-fullscreen)
;; Who use the bar to scroll?
(scroll-bar-mode 0)

(tool-bar-mode 0)
(menu-bar-mode 0)

;; You can also set the initial frame parameters
;; (setq initial-frame-alist
;;       '((menu-bar-lines . 0)
;;         (tool-bar-lines . 0)))

;; See http://bzg.fr/emacs-hide-mode-line.html
(defvar-local hidden-mode-line-mode nil)
(defvar-local hide-mode-line nil)

(define-minor-mode hidden-mode-line-mode
    "Minor mode to hide the mode-line in the current buffer."
    :init-value nil
    :global nil
    :variable hidden-mode-line-mode
    :group 'editing-basics
    (if hidden-mode-line-mode
      ;; rotatef will swap the values of the two args
      (rotatef hide-mode-line mode-line-format)
      (rotatef mode-line-format hide-mode-line))
    (when (and (called-interactively-p 'interactive)
              hidden-mode-line-mode)
      (run-with-idle-timer
        0 nil 'message
         (concat "Hidden Mode Line Mode enabled.  "
	      "Use M-x hidden-mode-line-mode RET to make the mode-line appear."))))

;; Activate hidden-mode-line-mode
(hidden-mode-line-mode 1)
