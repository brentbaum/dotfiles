;;; init.el --- So these are my settings and yeah.
;;; Commentary:
;; paredit flyycheck rainbowdelimiters cider keychord evil-leader autocomplete ido(enable) smex
;;(load-file "~/.emacs.d/emacs-strip.el")
;; ----------------- Copy / Paste -------------------- ;;
(defun copy-from-osx ()
  (shell-command-to-string "pbpaste"))

(defun paste-to-osx (text &optional push)
  (let ((process-connection-type nil))
    (let ((proc (start-process "pbcopy" "*Messages*" "pbcopy")))
      (process-send-string proc text)
      (process-send-eof proc))))

(setq interprogram-cut-function 'paste-to-osx)
(setq interprogram-paste-function 'copy-from-osx)

;; ------------------- No Backup  ------------------- ;;
(setq backup-directory-alist `(("." . "~/.backup")))
(setq auto-save-default nil)

;; ---------------------- GUI ----------------------- ;;

(defun do-gui-config ()
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (set-frame-parameter nil 'fullscreen 'fullboth))
(if (display-graphic-p)
    (do-gui-config))

;; ----------------- Miscellaneous ------------------- ;;
(menu-bar-mode -1)
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
(setq-default indent-tabs-mode nil)
(setq tab-width 4)
(global-set-key (kbd "C-h C-f") 'find-function)

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

;; ---------------- Solarized Theme ---------------- ;;
(load-theme 'solarized-dark t)

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
(setq cider-popup-stacktraces nil)
(add-hook 'cider-repl-mode-hook 'paredit-mode)

;; ------------------- Autocomplete ---------------- ;;
(require 'auto-complete-config)
(ac-config-default)

;; ---------------------- Ido ---------------------- ;;
(require 'ido)
(ido-mode t)
(setq ido-enable-flex-matching t)

;; --------------------- LaTex --------------------- ;;
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq TeX-save-query nil)
                                        ;(setq TeX-PDF-mode t)

;; ----------------- Javascript -------------------- ;;
(dolist (pattern '("\\.jshintrc$" "\\.jslint$"))
  (add-to-list 'auto-mode-alist (cons pattern 'json-mode)))

                                        ; javascript
(autoload 'js2-mode "js2-mode" nil t)
(add-to-list 'auto-mode-alist '("\\.js$" . js2-mode))

(require 'powerline)

(powerline-default-theme)

;; ---------------- Line Numbering ------------------;;
(require 'linum)
(load-file "~/.emacs.d/relative-number.el")
(global-linum-mode 1)

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

(provide 'init)

;;;
