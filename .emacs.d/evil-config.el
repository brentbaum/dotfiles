(evil-mode 1)
(global-evil-leader-mode)
(evil-leader/set-leader ",")
(evil-leader/set-key 
  "W" 'paredit-wrap-round
  "w" 'paredit-forward
  "b" 'paredit-backward
  "p" 'paredit-splice-sexp
  "/" 'evilnc-comment-or-uncomment-lines
  "j" 'cider-jump
  "k" 'kibit-current-file)
(define-key evil-normal-state-map ";" 'evil-ex)
(define-key evil-normal-state-map "p" 'paste-newline)
(define-key evil-normal-state-map " " 'ace-jump-mode)
;;(key-chord-define evil-insert-state-map "cv" 'evil-normal-state)
(defun paste-newline (&optional arguments)
  "Pastes like vim does - on a new line."
  (interactive) (evil-ret) (evil-paste-before nil))

(defun my-save ()
    (if (buffer-file-name)
        (save-buffer buffer-file-name)))

   (add-hook 'evil-insert-state-exit-hook 'my-save)

(require 'key-chord)

(setq key-chord-two-keys-delay 0.4)
(key-chord-define evil-insert-state-map "kk" 'evil-normal-state)
(key-chord-mode 1)

(provide 'evil-config)

;;; evil-config.el ends here
