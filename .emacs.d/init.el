;;; init.el --- So these are my settings and yeah.
;;; Commentary:
;; paredit flyycheck rainbowdelimiters cider keychord evil-leader autocomplete ido(enable) smex
;;(load-file "~/.emacs.d/emacs-strip.el")
;;; Code:
(global-set-key (kbd "C-c C-r") (lambda () (interactive) (load-file "~/.emacs.d/init.el")))

;; ------------------- No Backup  ------------------- ;;
(setq backup-directory-alist `(("." . "~/.backup")))
(setq auto-save-default nil)
(desktop-save-mode 1)

;; ---------------------- GUI ----------------------- ;;

(defun do-gui-config ()
  (tool-bar-mode -1)
  (scroll-bar-mode -1))
(if (display-graphic-p)
    (do-gui-config))

;; ----------------- Miscellaneous ------------------- ;;
(menu-bar-mode -1)
(setq bell-volume 0)
(define-key global-map (kbd "RET") 'newline-and-indent)
(define-key global-map "\M-'" 'other-frame)
(setq require-final-newline nil)

(global-set-key (kbd "C-x p")
		(kbd (concat "M-! latexmk -pdf "
			     load-file-name)))
(global-set-key (kbd "C-x o") 'switch-window)
(add-hook 'css-mode-hook 'rainbow-mode)
(fset 'yes-or-no-p 'y-or-n-p)
(setq inhibit-splash-screen t)
(setq inhibit-startup-message t)
(global-hl-line-mode 1)
(set-face-background 'hl-line "#333333")
(setq-default indent-tabs-mode nil)
(setq tab-width 4)
(global-set-key (kbd "C-h C-f") 'find-function)

;; -------------------- Scala --------------------------;;
(add-to-list 'auto-mode-alist '("\\.scala$" . scala-mode))

;; ---------------- Package Archives ------------------ ;;
(setq package-archives '(("gnu" . "http://elpa.gnu.org/packages/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")
                         ("melpa" . "http://melpa.milkbox.net/packages/")))
(package-initialize)

;; ------------------- FLYCHECK -------------------- ;;
(add-hook 'after-init-hook #'global-flycheck-mode)
(add-hook 'flycheck-mode-hook 'flycheck-color-mode-line-mode)

;; ------------------- FLYMAKE --------------------- ;;
(defun flymanke-get-tex-args (file-name)
  (list "pdflatex"
	(list "-file-line-error" "-draftmode" "-interaction=nonstopmode" file-name)))

(add-hook 'LaTeX-mode-hook 'flymake-mode)

;; -------------- Rainbow Delimeters --------------- ;;
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

;; -------------------- Paredit -------------------- ;;
(load-file "~/.emacs.d/paredit-config.el")

;; --------------------- Eldoc --------------------- ;;
(add-hook 'emacs-lisp-mode-hook 'turn-on-eldoc-mode)
(add-hook 'lisp-interaction-mode-hook 'turn-on-eldoc-mode)
(add-hook 'ielm-mode-hook 'turn-on-eldoc-mode)
(add-hook 'cider-mode-hook 'cider-turn-on-eldoc-mode)

;; --------------------- Cider --------------------- ;;
(add-hook 'cider-mode-hook 'cider-turn-on-eldoc-mode)
(setq nrepl-hide-special-buffers t)
(setq cider-repl-pop-to-buffer-on-connect nil)
(setq cider-repl-display-in-current-window t)
(setq cider-popup-stacktraces t)
(add-hook 'cider-repl-mode-hook 'paredit-mode)

;; ------------------- Autocomplete ---------------- ;;
(require 'auto-complete-config)
(ac-config-default)
(require 'ac-helm)  ;; Not necessary if using ELPA package
(global-set-key (kbd "C-:") 'ac-complete-with-helm)
(define-key ac-complete-mode-map (kbd "C-:") 'ac-complete-with-helm)

;; ---------------------- Ido ---------------------- ;;
;(require 'ido)
;(ido-mode t)
;(setq ido-enable-flex-matching t)

;; --------------------- LaTex --------------------- ;;
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq TeX-save-query nil)
                                        ;(setq TeX-PDF-mode t)

;; ----------------- Web Stuff -------------------- ;;
(dolist (pattern '("\\.jshintrc$" "\\.jslint$"))
  (add-to-list 'auto-mode-alist (cons pattern 'json-mode)))
(setq httpd-port 6789)
                                        ; javascript
(autoload 'js2-mode "js2-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))

(require 'web-beautify) ;; Not necessary if using ELPA package
(eval-after-load 'js2-mode
  '(define-key js2-mode-map (kbd "C-c C-t") 'web-beautify-js))

(add-hook 'js2-mode-hook 'skewer-mode)
(add-hook 'css-mode-hook 'skewer-css-mode)
(add-hook 'html-mode-hook 'skewer-html-mode)

;; ---------------- Line Numbering ------------------;;
(require 'linum)
(load-file "~/.emacs.d/relative-number.el")
(global-linum-mode 1)

;; ------------------- Navigation --------------------;;
(autoload
  'ace-jump-mode
  "ace-jump-mode"
  "Emacs quick move minor mode"
  t)
;; you can select the key you prefer to

;; ---------------- RUUUUUUUUUUBY -------------------;;
(add-to-list 'auto-mode-alist
             '("\\.\\(?:gemspec\\|irbrc\\|gemrc\\|rake\\|rb\\|ru\\|thor\\)\\'" . ruby-mode))
(add-to-list 'auto-mode-alist
             '("\\(Capfile\\|Gemfile\\(?:\\.[a-zA-Z0-9._-]+\\)?\\|[rR]akefile\\)\\'" . ruby-mode))

;; --------------------- KIBIT -------------------- ;;
;; Teach compile the syntax of the kibit output
(require 'compile)
(add-to-list 'compilation-error-regexp-alist-alist
             '(kibit "At \\([^:]+\\):\\([[:digit:]]+\\):" 1 2 nil 0))
(add-to-list 'compilation-error-regexp-alist 'kibit)

;; A convenient command to run "lein kibit" in the project to which
;; the current emacs buffer belongs to.
(defun kibit ()
  "Run kibit on the current project.
Display the results in a hyperlinked *compilation* buffer."
  (interactive)
  (compile "lein kibit"))

(defun kibit-current-file ()
  "Run kibit on the current file.
Display the results in a hyperlinked *compilation* buffer."
  (interactive)
  (compile (concat "lein kibit " buffer-file-name)))

;; --------------------- Smex ------------------------- ;;
(load-file "~/.emacs.d/smex-config.el")

;; --------------------- Evil ---------------------- ;;
(load-file "~/.emacs.d/evil-config.el")

;; ------------------- Haskell --------------------- ;;
(add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
(add-hook 'haskell-mode-hook 'turn-on-haskell-indent)
;; (add-hook 'haskell-mode-hook 'interactive-haskell-mode)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("1e7e097ec8cb1f8c3a912d7e1e0331caeed49fef6cff220be63bd2a6ba4cc365" default)))
 '(haskell-process-auto-import-loaded-modules t)
 '(haskell-process-log t)
 '(haskell-process-suggest-remove-import-lines t)
 '(haskell-process-type (quote ghci)))

(define-key haskell-mode-map (kbd "C-c C-l") 'haskell-process-load-or-reload)
(define-key haskell-mode-map (kbd "C-`") 'haskell-interactive-bring)
(define-key haskell-mode-map (kbd "C-c C-t") 'haskell-process-do-type)
(define-key haskell-mode-map (kbd "C-c C-i") 'haskell-process-do-info)
(define-key haskell-mode-map (kbd "C-c C-c") 'haskell-process-cabal-build)
(define-key haskell-mode-map (kbd "C-c C-k") 'haskell-interactive-mode-clear)
(define-key haskell-mode-map (kbd "C-c c") 'haskell-process-cabal)
(define-key haskell-mode-map (kbd "SPC") 'haskell-mode-contextual-space)

;; ---------------------- C ------------------------ ;;
(global-ede-mode 1)
(require 'semantic/sb)

(provide 'init)

;; ---------------- Solarized Theme ---------------- ;;
(load-theme 'solarized-light t)

;; ------------------- Helm Mode ------------------- ;;
(require 'helm)
(require 'helm-config)

(global-unset-key (kbd "C-x c"))
(global-set-key (kbd "C-c h") 'helm-command-prefix)
(global-set-key (kbd "C-x b") 'helm-buffers-list)
(global-set-key (kbd "M-x") 'helm-M-x)
(global-set-key (kbd "C-x C-f") 'helm-find-files)
(global-set-key (kbd "M-y") 'helm-show-kill-ring)
(define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action) 
(define-key helm-map (kbd "C-z")  'helm-select-action) ; list actions using C-z

(when (executable-find "curl")
  (setq helm-google-suggest-use-curl-p t))

(setq helm-split-window-in-side-p           t ; open helm buffer inside current window, not occupy whole other window
      helm-move-to-line-cycle-in-source     t ; move to end or beginning of source when reaching top or bottom of source.
      helm-ff-search-library-in-sexp        t ; search for library in `require' and `declare-function' sexp.
      helm-scroll-amount                    8 ; scroll 8 lines other window using M-<next>/M-<prior>
      helm-ff-file-name-history-use-recentf t
      )

(helm-mode 1)

;;;
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
