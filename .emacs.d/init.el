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

(setq default-input-method "greek")


(column-number-mode)
(global-display-line-numbers-mode t)
(set-face-attribute 'default nil
                    ;; :font"Fira Code Nerd Font"
                    :font"Literation Mono Nerd Font"
                    :height 115)


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

(use-package evil-surround
    :ensure t
  :config
  (global-evil-surround-mode 1))

;; Add custom surround mappings if needed

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
  :hook (python-mode . eglot-ensure)
         ;; (python-mode . company-mode))
  :mode (("\\.py\\'" . python-mode)))

(add-to-list 'exec-path "~/.local/bin")
(setq inferior-R-program-name "~/.local/bin/R")
backquote-backquote-symbol(setq ess-indent-offset 2)

(use-package ess
  :ensure t
  :init
  (require 'ess-site)
  :config
  (setq ess-indent-offset 2)
  (setq inferior-R-program-name "~/.local/bin/R") ;; Set the correct R path
  :bind (:map ess-r-mode-map
              ("C-SPC" . (lambda () (interactive) (insert " |> ")))
         :map ess-r-mode-map
              ("C-S-SPC" . (lambda () (interactive) (insert " <- ")))))

;; Define namespace face explicitly with default family and italic slant
(defface ess-namespace-face
  `((t (:foreground "#a10352"
        :slant italic
        :inherit default)))
  "Face for highlighting package namespaces in ESS R mode.")

;; Highlight package namespaces
(defun my-ess-highlight-namespace ()
  "Highlight package namespaces distinctly in ESS R mode."
  (font-lock-add-keywords
   nil
   '(("\\b\\([[:alnum:].]+::\\)" 1 'ess-namespace-face prepend))))

(add-hook 'ess-r-mode-hook #'my-ess-highlight-namespace)


(use-package eglot
  :ensure t
  :hook ((ess-r-mode . eglot-ensure))  ;; Enable Eglot in R buffers
  :config
  (add-to-list 'exec-path "~/.local/bin") ;; Ensure Emacs finds R
  (add-to-list 'eglot-server-programs
               '(ess-r-mode . ("~/.local/bin/R"
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

(use-package corfu
  :ensure t
  :init
  (global-corfu-mode)
  :custom
  (corfu-cycle t)                ;; Enable cycling for `corfu'.
  (corfu-auto t)                 ;; Enable auto completion
  (corfu-auto-prefix 2)          ;; Minimum prefix length for auto completion
  (corfu-auto-delay 0.0))        ;; No delay for auto completion

(use-package kind-icon
  :ensure t
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default) ; offers a unified appearance
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(use-package gptel
  :ensure t)

;; ===============================================
;; Custom functions
;; ===============================================

(defvar my/previous-window-configuration nil
  "Store the previous window configuration before maximizing.")

(defun my/toggle-maximize-window ()
  "Toggle between maximizing the current window and restoring the previous window configuration."
  (interactive)
  (if my/previous-window-configuration
      (progn
        (set-window-configuration my/previous-window-configuration)
        (setq my/previous-window-configuration nil))
    (setq my/previous-window-configuration (current-window-configuration))
    (delete-other-windows)))

(defun my/copy-directory-path-to-kill-ring ()
  "Copy the current file's directory path to the kill ring."
  (interactive)
  (if-let ((file-name (buffer-file-name)))
      (let ((directory (file-name-directory file-name)))
        (kill-new directory)
        (message "Copied directory path: %s" directory))
    (message "No file associated with this buffer.")))

;; ===============================================
;; Keymaps
;; ===============================================
(define-prefix-command 'my-space-map)
(define-key evil-normal-state-map (kbd "SPC") 'my-space-map)
(define-key evil-normal-state-map (kbd "s") 'evil-surround-edit)
(define-key evil-visual-state-map (kbd "s") 'evil-surround-region)

;; Define sub-prefixes
(define-prefix-command 'my-space-f-map)
(define-prefix-command 'my-space-w-map)
(define-prefix-command 'my-space-b-map)
(define-prefix-command 'my-space-g-map)
(define-prefix-command 'my-space-c-map)

;; Assign sub-prefixes to main space-map
(define-key my-space-map (kbd "f") 'my-space-f-map)
(define-key my-space-map (kbd "w") 'my-space-w-map)
(define-key my-space-map (kbd "b") 'my-space-b-map)
(define-key my-space-map (kbd "g") 'my-space-g-map)
(define-key my-space-map (kbd "c") 'my-space-c-map)

;; Define file commands under SPC f ...
(define-key my-space-f-map (kbd "f") 'find-file)
(define-key my-space-f-map (kbd "c") 'my/copy-directory-path-to-kill-ring)


;; Define window switching under SPC w ...
(define-key my-space-w-map (kbd "w") 'evil-window-next)
(define-key my-space-w-map (kbd "m") 'my/toggle-maximize-window)
(define-key my-space-w-map (kbd "b") 'switch-to-buffer)
(define-key my-space-w-map (kbd "k") 'kill-buffer)
(define-key my-space-w-map (kbd "3") 'split-window-right)
(define-key my-space-w-map (kbd "2") 'split-window-below)
(define-key my-space-w-map (kbd "0") 'delete-window)
(define-key my-space-w-map (kbd "1") 'delete-other-windows)

;; Define window switching under SPC b ...
(define-key my-space-b-map (kbd "b") 'bookmark-jump)
(define-key my-space-b-map (kbd "s") 'bookmark-set)

;; Define window switching under SPC g ...
(define-key my-space-g-map (kbd "g") 'gptel)
(define-key my-space-g-map (kbd "RET") 'gptel-send)
(define-key my-space-g-map (kbd "f") 'gptel-add-file)
