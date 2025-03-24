(require 'package)

(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/") t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "https://stable.melpa.org/packages/") t)
(add-to-list 'package-archives '("org" . "https://orgmode.org/elpa/") t)

(package-initialize)


(setq custom-file (concat user-emacs-directory "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

(defvar backup-dir "~/.emacs.d/backups/")
(setq backup-directory-alist (list (cons "." backup-dir)))

;; always load emacs maximized
(setq default-frame-alist '((fullscreen . maximized)))

(setq locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(when (display-graphic-p)
   (setq x-select-request-type '(UTF8_STRING COMPOUND_TEXT TEXT STRING)))

(setq display-line-numbers 'relative)
(setq inhibit-startup-message t)
(setq make-backup-files nil)
(setq
   split-width-threshold 0
   split-height-threshold nil)

(scroll-bar-mode -1)
(tool-bar-mode -1)
(tooltip-mode -1)
(set-fringe-mode 10)
(menu-bar-mode -1)
(setq visible-bell t)
(setq display-line-numbers-type 'relative)
(setq-default fill-column 120)
(setq inihibit-startup-message t)

(global-set-key (kbd "M-b") 'switch-to-buffer)

(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)
(setq indent-line-function 'insert-tab)
(global-hl-line-mode 1)


(column-number-mode)
(global-display-line-numbers-mode t)
(set-face-attribute 'default nil
                    :font"FiraCode Nerd Font Mono"
                    :height 130)


(defun my/toggle-vterm ()
  "Toggle between vterm and the previous buffer."
  (interactive)
  (if (derived-mode-p 'vterm-mode)
      (switch-to-prev-buffer)  
    (vterm)))

(global-set-key (kbd "C-c t") 'my/toggle-vterm)

(add-to-list 'display-buffer-alist
             '("\\*vterm\\*"                     ;; Match ESS R process buffer
               (display-buffer-reuse-window   ;; Try to reuse an existing window
                display-buffer-in-side-window)
               (side . bottom)                ;; Place it at the bottom
               (slot . 0)                     ;; First in the bottom slot
               (window-height . 0.3)))        ;; Set height to 30% of the frame

(use-package vterm
  :ensure t)

(use-package emacs :ensure nil :config (setq ring-bell-function #'ignore))

;; Install and configure evil model
(use-package evil
  :ensure t
  :demand t
  :init
  (setq evil-want-integration t)
  (setq evil-want-keybinding nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump nil)
  :config
  (evil-mode 1)
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)

  ;; Use visual line motions even outside of visual-line-mode buffers
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)

  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-initial-state 'dashboard-mode 'normal)
  (evil-mode 1)
  (evil-set-leader 'motion (kbd "SPC")))

(use-package evil-collection
  :ensure t
  :after evil
  :config
  (evil-collection-init))

(use-package doom-modeline
  :ensure t
  :demand t
  :init (doom-modeline-mode 1))

(use-package doom-themes
  :ensure t
  :demand t)

(load-theme 'doom-tomorrow-day t)
(add-to-list 'default-frame-alist '(foreground-color . "#000000"))
(add-to-list 'default-frame-alist '(background-color . "#FFFFFF"))

(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  :custom
  (vertico-cycle t))

(use-package savehist
  :init
  (savehist-mode))

(use-package marginalia
  :ensure t
  :init
  (marginalia-mode))

(use-package consult
  :ensure t
  :bind (("C-c l" . consult-line)
         ("C-c m" . consult-imenu)
         ("C-c b" . consult-buffer)))

;; Parentheses delimiter
(use-package rainbow-delimiters
  :ensure t
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package which-key
  :ensure t
  :init (which-key-mode)
  :diminish
  :config
  (setq which-key-idle-delay 0.1))

; Parentheses
(use-package highlight-parentheses
  :ensure t
  :config
  (progn
    (highlight-parentheses-mode)
    (global-highlight-parentheses-mode))
  )

(electric-pair-mode 1)
(setq electric-pair-preserve-balance nil)

(use-package highlight-indent-guides
  :ensure t
  :config (add-hook 'prog-mode-hook 'highlight-indent-guides-mode))
(setq highlight-indent-guides-method 'character)

(use-package python-mode
  :ensure t
  :hook ((python-mode . eglot-ensure)
         (python-mode . company-mode))
  :mode (("\\.py\\'" . python-mode)))

(add-to-list 'exec-path "/home/arekkas/.local/bin")
(setq inferior-R-program-name "/home/arekkas/.local/bin/R")
backquote-backquote-symbol(setq ess-indent-offset 2)

(use-package ess
  :ensure t
  :init
  (require 'ess-site)
  :config
  (setq ess-indent-offset 2)
  (setq inferior-R-program-name "/home/arekkas/.local/bin/R") ;; Set the correct R path
  :bind (:map ess-r-mode-map
              ("C-SPC" . (lambda () (interactive) (insert " |> ")))
         :map ess-r-mode-map
              ("C-S-SPC" . (lambda () (interactive) (insert " <- ")))))

(use-package eglot
  :ensure t
  :hook ((ess-r-mode . eglot-ensure))  ;; Enable Eglot in R buffers
  :config
  (add-to-list 'exec-path "/home/arekkas/.local/bin") ;; Ensure Emacs finds R
  (add-to-list 'eglot-server-programs
               '(ess-r-mode . ("/home/arekkas/.local/bin/R"
                               "--no-init-file" "--slave" "-e" "languageserver::run()"))))

(defun my/toggle-r-console ()
  "Toggle between the *R* process buffer and the previous buffer."
  (interactive)
  (if (string= (buffer-name) "*R*")
      (switch-to-prev-buffer)  ;; If in *R*, go back to the last buffer
    (if (get-buffer "*R*")
        (pop-to-buffer "*R*")  ;; If *R* exists, switch to it
      (R))))                    ;; Otherwise, start R

(global-set-key (kbd "C-c r") 'my/toggle-r-console)

;;; LSP-mode

(use-package lsp-mode
  :ensure t
  :commands (lsp lsp-deferred)
  :init
  (setq lsp-keymap-prefix "C-c l")
  :config
  (lsp-enable-which-key-integration t))

(use-package company
  :ensure t
  :config
  (setq company-idle-delay 0.1
        company-minimum-prefix-length 1)
  :hook (prog-mode . company-mode))

(use-package gptel
  :ensure t
