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
(defun paste-newline (&optional arguments)
  "Pastes like vim does - on a new line."
  (interactive) (evil-ret) (evil-paste-before nil))

(provide 'evil-config)

;;; evil-config.el ends here
