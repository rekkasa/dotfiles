;;; init.el --- Terminal-first Emacs -*- lexical-binding: t; -*-

;;; Commentary:
;; Port of the previous package.el config to straight.el, targeting
;; `emacs -nw' / `emacsclient -nw' as the primary interface.
;;
;; Sections, in load order:
;;   1. straight.el + use-package
;;   2. GC management
;;   3. Terminal foundations   <- the part that is genuinely new
;;   4. Defaults
;;   5. Evil
;;   6. Appearance
;;   7. Minibuffer completion  (vertico / orderless / marginalia / consult / embark)
;;   8. In-buffer completion   (corfu / corfu-terminal / cape)
;;   9. LSP: eglot, incl. the R languageserver contact function
;;  10. Languages: ESS, Python, Markdown
;;  11. Org (base; the research layer lives in knowledge.el)
;;  12. Tools: magit, vterm, gptel
;;  13. Custom functions
;;  14. Keymaps
;;  15. External files (knowledge.el, md-preview.el)

;;; Code:

;; ===========================================================================
;; 0. Version check
;; ===========================================================================
;; Emacs 29 is the floor: it is where `use-package', `eglot' and
;; `--init-directory' became built-in.  The config adapts to what is actually
;; available rather than assuming a version -- see the which-key branch in
;; section 4, the eglot events-buffer branch in section 9, and the
;; corfu-terminal guards in section 8.
(when (< emacs-major-version 29)
  (error "This config needs Emacs 29 or newer; this is %s" emacs-version))

;; ===========================================================================
;; 1. straight.el + use-package
;; ===========================================================================

;; Must be set BEFORE the bootstrap: straight decides its modification-check
;; strategy at load time.  `check-on-save' means straight does not stat every
;; file in every repo on startup, which is the single biggest straight.el
;; startup cost.  Shallow clones keep ~/.emacs.d/straight from reaching a
;; gigabyte.
(setq straight-check-for-modifications '(check-on-save find-when-checking)
      straight-vc-git-default-clone-depth 1)

(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name "straight/repos/straight.el/bootstrap.el"
                         user-emacs-directory))
      (bootstrap-version 7))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/radian-software/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

(straight-use-package 'use-package)

;; With straight, `:straight t' is implicit and `:ensure' (package.el's
;; keyword) is not used at all -- hence no `use-package-always-ensure'.
;; Built-in packages need an explicit `:straight nil' or straight will fetch
;; a duplicate from ELPA.
(setq straight-use-package-by-default t
      use-package-expand-minimally t)

;; Uncomment, restart, then M-x use-package-report to see what init spends
;; its time on.  Left off because collecting the statistics is itself a cost.
;; (setq use-package-compute-statistics t)

;; --------------------------------------------------------------- org pinning
;; This must come before anything that could depend on org.  Emacs ships org,
;; but org-roam, org-ql and citar-org-roam all declare `org' as a dependency,
;; so straight would happily fetch a second copy from ELPA.  You then get the
;; classic mixed-version failure: org's autoloads point at the built-in files,
;; the newer .el files get loaded on top, and you see errors like
;; "org-element-at-point: Invalid function" or "wrong-number-of-arguments" in
;; code you never touched.  Declaring org built-in makes straight satisfy that
;; dependency from the binary instead of cloning it.
(straight-use-package '(org :type built-in))

;; Custom goes in its own file and is never loaded into the "real" config.
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file nil 'nomessage))

;; ===========================================================================
;; 2. GC management
;; ===========================================================================
;; early-init.el disabled GC for startup.  gcmh restores sane behaviour:
;; effectively no GC while you are typing, a collection when you go idle.
(use-package gcmh
  :demand t
  :config
  (setq gcmh-idle-delay 'auto
        gcmh-auto-idle-delay-factor 10
        gcmh-high-cons-threshold (* 64 1024 1024))
  (gcmh-mode 1))

;; Subprocess output in 4KB chunks throttles any LSP server; JSON-RPC payloads
;; are routinely much larger.  (Kept from the old config -- still correct.)
(setq read-process-output-max (* 1024 1024))
(setq process-adaptive-read-buffering nil)

;; ===========================================================================
;; 3. Terminal foundations
;; ===========================================================================
;; These four items are the difference between "Emacs runs in my terminal" and
;; "Emacs works in my terminal".  Nothing here has a GUI equivalent because in
;; a GUI none of these problems exist.

;; --- 3a. Key disambiguation -------------------------------------------------
;; A terminal cannot express C-S-SPC, C-<tab>, C-<return>, S-<up> etc.  It
;; sends bytes, and `C-i' and `TAB' are the same byte.  The Kitty Keyboard
;; Protocol fixes this at the protocol level.  Requires a terminal that speaks
;; it: kitty, foot, ghostty, WezTerm, Alacritty.  Check with M-x kkp-status.
;;
;; NOTE: tmux does not forward KKP.  If you multiplex, use the terminal's own
;; splits/tabs, or zellij, or accept the TTY-safe fallback bindings in §13.
(use-package kkp
  :straight (kkp :type git :host github :repo "benotn/kkp")
  :demand t
  :config
  ;; If C-g stops aborting blocking subprocesses, uncomment this:
  ;; (setq kkp-restore-legacy-keys-around-subprocesses t)
  (global-kkp-mode 1))

;; --- 3b. Clipboard ----------------------------------------------------------
;; A TTY Emacs has no X selection.  clipetty pushes the kill ring to the
;; *terminal's* clipboard via OSC 52, which means it works identically over
;; SSH, which matters if you ever edit over a remote shell.  Your terminal must
;; have OSC 52 writes enabled (kitty: `clipboard_control write-primary
;; write-clipboard`; tmux: `set -g set-clipboard on`).
(use-package clipetty
  :demand t
  :config (global-clipetty-mode 1))

;; --- 3c. Mouse --------------------------------------------------------------
;; Emacs 31 turns this on by default; on 30 it needs asking for.
(unless (bound-and-true-p xterm-mouse-mode)
  (xterm-mouse-mode 1))
(setq mouse-wheel-scroll-amount '(1 ((shift) . 1))
      mouse-wheel-progressive-speed nil
      mouse-wheel-follow-mouse t)

;; --- 3d. Colour -------------------------------------------------------------
;; Emacs emits 24-bit colour escapes only when terminfo advertises them.  The
;; usual `xterm-256color' entry does not, so catppuccin gets quantised to the
;; 256-colour cube and looks muddy.  Fix it OUTSIDE Emacs, by launching with a
;; direct-colour TERM:
;;
;;     TERM=xterm-direct emacsclient -nw        # or foot-direct, etc.
;;
;; Verify inside Emacs with (display-color-cells) -- you want 16777216.

;; ===========================================================================
;; 4. Defaults
;; ===========================================================================

(setq locale-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-selection-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

(setq default-input-method "greek")     ; toggle with C-\

;; No backups scattered next to source.
(setq make-backup-files nil
      create-lockfiles nil
      auto-save-default t
      auto-save-file-name-transforms
      `((".*" ,(expand-file-name "auto-save/" user-emacs-directory) t)))
(make-directory (expand-file-name "auto-save/" user-emacs-directory) t)

(setq ring-bell-function #'ignore)      ; `visible-bell' flashes the whole TTY
(setq use-short-answers t)
(setq sentence-end-double-space nil)
(setq require-final-newline t)
(setq scroll-conservatively 101         ; no half-screen jumps when scrolling
      scroll-margin 3)

;; Always split side by side, as before.
(setq split-width-threshold 0
      split-height-threshold nil)

(setq-default indent-tabs-mode nil)
(setq-default tab-width 2)
(setq-default fill-column 120)
;; NOTE: the old config had (setq indent-line-function 'insert-tab).  That is
;; dropped deliberately -- it overrides the *global* indent function, so any
;; mode that does not set its own buffer-locally loses real indentation.

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode 1)
(dolist (hook '(term-mode-hook vterm-mode-hook eshell-mode-hook
                shell-mode-hook comint-mode-hook))
  (add-hook hook (lambda () (display-line-numbers-mode -1))))

(column-number-mode 1)
(global-hl-line-mode 1)
(electric-pair-mode 1)
(setq electric-pair-preserve-balance nil)
(global-so-long-mode 1)                 ; survive opening a minified file
(global-auto-revert-mode 1)
(setq global-auto-revert-non-file-buffers t
      auto-revert-verbose nil)

(use-package savehist
  :straight nil
  :demand t
  :config
  (setq history-length 500
        savehist-additional-variables '(kill-ring search-ring regexp-search-ring))
  (savehist-mode 1))

(use-package saveplace
  :straight nil
  :demand t
  :config (save-place-mode 1))

(use-package recentf
  :straight nil
  :demand t
  :config
  (setq recentf-max-saved-items 300
        recentf-exclude '("/straight/" "/elpa/" "/tmp/"))
  (recentf-mode 1))

;; which-key joined Emacs core in 30.1.  On 29 it has to come from ELPA, so
;; fetch it first and then load it the same way in both cases.
(unless (>= emacs-major-version 30)
  (straight-use-package 'which-key))

(use-package which-key
  :straight nil
  :demand t
  :config
  (setq which-key-idle-delay 0.1)
  (which-key-mode 1))

;; Abbrevs (R templates live in global_r_abbrevs.el).
(setq-default abbrev-mode t)
(setq save-abbrevs 'silently)
(defun my/load-global-r-abbrevs ()
  "Load the external R abbrev definitions, if present."
  (let ((f (expand-file-name "global_r_abbrevs.el" user-emacs-directory)))
    (when (file-exists-p f)
      (load-file f)))
  (abbrev-mode 1))
(add-hook 'after-init-hook #'my/load-global-r-abbrevs)

;; Start a server so `emacsclient -nw' is instant.  Harmless when already
;; running as a daemon.
(use-package server
  :straight nil
  :defer 1
  :config (unless (server-running-p) (server-start)))

(add-to-list 'exec-path (expand-file-name "~/.local/bin"))

;; ===========================================================================
;; 5. Evil
;; ===========================================================================

(use-package evil
  :demand t
  :init
  (setq evil-want-integration t
        evil-want-keybinding nil
        evil-want-C-u-scroll t
        evil-want-C-i-jump nil          ; C-i IS Tab in a TTY; leave it alone
        evil-undo-system 'undo-redo     ; built-in since 28; no undo-tree needed
        evil-respect-visual-line-mode t)
  :config
  (evil-mode 1)
  ;; ESC is the Meta prefix in a terminal, so leaving insert state with ESC
  ;; costs a timeout.  C-g is instant and unambiguous -- keep using it.
  (define-key evil-insert-state-map (kbd "C-g") 'evil-normal-state)
  (evil-global-set-key 'motion "j" 'evil-next-visual-line)
  (evil-global-set-key 'motion "k" 'evil-previous-visual-line)
  (evil-set-initial-state 'messages-buffer-mode 'normal)
  (evil-set-leader 'motion (kbd "SPC")))

(use-package evil-collection
  :after evil
  :demand t
  :config (evil-collection-init))

(use-package evil-surround
  :after evil
  :demand t
  :config (global-evil-surround-mode 1))

;; Org and org-roam are heavily keybound; evil-org makes them navigable.
(use-package evil-org
  :after (evil org)
  :hook (org-mode . evil-org-mode)
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

;; ===========================================================================
;; 6. Appearance
;; ===========================================================================

(use-package catppuccin-theme
  :demand t
  :init (setq catppuccin-flavor 'latte)  ; latte/frappe/macchiato/mocha
  :config (load-theme 'catppuccin :no-confirm))

(use-package nerd-icons :defer t)

(use-package doom-modeline
  :demand t
  :init
  (setq doom-modeline-height 1
        doom-modeline-buffer-encoding nil
        doom-modeline-icon t)           ; needs a Nerd Font in the TERMINAL
  :config (doom-modeline-mode 1))

(use-package rainbow-delimiters
  :hook (prog-mode . rainbow-delimiters-mode))

(use-package highlight-parentheses
  :demand t
  :config (global-highlight-parentheses-mode 1))

(use-package highlight-indent-guides
  :hook (prog-mode . highlight-indent-guides-mode)
  :init
  ;; 'character is the only method that renders in a terminal.
  (setq highlight-indent-guides-method 'character
        highlight-indent-guides-responsive nil))

(use-package zoom
  :demand t
  :config
  (defun my/zoom-size-callback ()
    (cond ((> (frame-width) 160) '(100 . 0.75))
          (t                     '(0.5 . 0.5))))
  (setq zoom-size #'my/zoom-size-callback)
  (zoom-mode 1))

;; Font only applies to graphical frames; a TTY uses the terminal's font.
(when (display-graphic-p)
  (set-face-attribute 'default nil :font "Fira Code Nerd Font" :height 115))

;; ===========================================================================
;; 7. Minibuffer completion
;; ===========================================================================

(use-package vertico
  :demand t
  :init (vertico-mode 1)
  :custom
  (vertico-cycle t)
  (vertico-resize nil))                 ; a fixed-height popup redraws less

(use-package orderless
  :demand t
  :custom
  (completion-styles '(orderless basic))
  (completion-category-defaults nil)
  (completion-category-overrides
   ;; eglot sets its own style; force orderless back on for LSP candidates.
   '((file (styles basic partial-completion))
     (eglot (styles orderless))
     (eglot-capf (styles orderless)))))

(use-package marginalia
  :demand t
  :init (marginalia-mode 1))

(use-package consult
  :bind (("C-c l" . consult-line)
         ("C-c m" . consult-imenu)
         ("C-c b" . consult-buffer)
         ("C-c g" . consult-ripgrep)
         ("C-c f" . consult-recent-file)
         ("M-y"   . consult-yank-pop))
  :config
  (setq consult-narrow-key "<"))

;; Embark is the piece your stack is missing: it turns any completion
;; candidate (or the thing at point) into a menu of actions.  Sibling of
;; vertico/consult by design.
(use-package embark
  :bind (("C-c ." . embark-act)         ; C-. is not expressible without kkp
         ("C-h B" . embark-bindings))
  :init (setq prefix-help-command #'embark-prefix-help-command))

(use-package embark-consult
  :after (embark consult)
  :hook (embark-collect-mode . consult-preview-at-point-mode))

;; Makes `embark-export' from a consult-ripgrep an editable buffer -- i.e.
;; project-wide search and replace with normal editing commands.
(use-package wgrep
  :defer t
  :config (setq wgrep-auto-save-buffer t))

;; ===========================================================================
;; 8. In-buffer completion
;; ===========================================================================

(use-package corfu
  :demand t
  :init (global-corfu-mode 1)
  :custom
  (corfu-cycle t)
  (corfu-auto t)
  (corfu-auto-prefix 2)
  (corfu-auto-delay 0.1)
  (corfu-quit-no-match 'separator)
  :bind (:map corfu-map
              ("TAB"       . corfu-next)
              ("<tab>"     . corfu-next)
              ("S-TAB"     . corfu-previous)
              ("<backtab>" . corfu-previous)
              ("RET"       . corfu-insert)))

;; Corfu draws its popup in a child frame.  Emacs 31 supports child frames on
;; TTYs; Emacs 30 and earlier do not, so on 30 corfu silently falls back to the
;; *Completions* buffer -- which is why corfu "does nothing" for people who
;; move to terminal Emacs.  corfu-terminal reimplements the popup with overlays.
(use-package popon
  :straight (popon :type git :repo "https://codeberg.org/akib/emacs-popon.git")
  :if (< emacs-major-version 31))

(use-package corfu-terminal
  :straight (corfu-terminal :type git
                            :repo "https://codeberg.org/akib/emacs-corfu-terminal.git")
  :if (< emacs-major-version 31)
  :after corfu
  :config
  (unless (display-graphic-p)
    (corfu-terminal-mode 1)))

;; kind-icon is SVG-based and renders nothing in a TTY.  This is the
;; Nerd-Font equivalent, which your terminal font already covers.
(use-package nerd-icons-corfu
  :after corfu
  :config
  (add-to-list 'corfu-margin-formatters #'nerd-icons-corfu-formatter))

(use-package cape
  :demand t
  :init
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file))

;; NOTE: the old config ran company (not corfu) in R buffers, because corfu
;; does not reliably re-issue eglot's completion request if you keep typing
;; while one is in flight.  Your own comment noted that this was invisible on
;; a fast local server and only bit over the SSH round trip -- so with the VM
;; gone, company goes too.  Corfu now handles every buffer.

;; ===========================================================================
;; 9. eglot
;; ===========================================================================
;; lsp-mode is gone.  It was installed but every hook in the old config used
;; eglot, and its `C-c l' keymap prefix collided with consult-line.

(defvar my/eglot-r-debug nil
  "Set to t for verbose R-side logging via `eglot-stderr-buffer'.")

(defun my/eglot-r-contact (_interactive)
  "Return the R languageserver command.
Keeps --no-init-file so we never load an unrelated .Rprofile -- if eglot's
chosen project root has none of its own, it can pick up your home-directory
profile, which caused hard crashes.  Instead, explicitly walks upward from
the R process's working directory looking for renv/activate.R and sources it
if found, so renv-managed packages are still visible to completion and
diagnostics regardless of which directory eglot happened to treat as the
project root.  This part is unrelated to where Emacs runs -- renv projects
have the same problem locally."
  (list (or (executable-find "R") "R")
        "--no-init-file" "--slave"
        "-e" (concat
              "local({"
              "  orig_libs <- .libPaths();"
              "  d <- getwd();"
              "  repeat {"
              "    f <- file.path(d, 'renv', 'activate.R');"
              "    if (file.exists(f)) { source(f); break };"
              "    parent <- dirname(d);"
              "    if (identical(parent, d)) break;"
              "    d <- parent"
              "  };"
              ;; renv::activate() REPLACES .libPaths() with just the project's
              ;; private library, which isolates the project -- but also hides
              ;; languageserver if it isn't an renv dependency.  Keep both.
              "  .libPaths(unique(c(.libPaths(), orig_libs)))"
              "})")
        "-e" (format "languageserver::run(debug = %s)"
                     (if my/eglot-r-debug "TRUE" "FALSE"))))

(use-package eglot
  :straight nil                         ; built in since Emacs 29
  :hook ((ess-r-mode . eglot-ensure)
         (python-base-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs (cons 'ess-r-mode #'my/eglot-r-contact))
  (setq eglot-connect-timeout 30        ; R + languageserver startup, locally
        eglot-sync-connect nil          ; don't block the UI while connecting
        eglot-autoshutdown t
        eglot-extend-to-xref t)

  ;; Eglot logs every JSON-RPC message into a buffer by default: a measurable
  ;; amount of consing for data you will never read.
  (if (boundp 'eglot-events-buffer-config)
      (setq eglot-events-buffer-config '(:size 0 :format full))  ; Emacs 30+
    (setq eglot-events-buffer-size 0))

  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (setq-local completion-at-point-functions
                          (list #'eglot-completion-at-point
                                #'cape-dabbrev
                                #'cape-file))
              (setq-local eldoc-echo-area-use-multiline-p 1)))

  ;; PROBABLY REMOVABLE.  A pty translates outgoing \n to \r\n and has a small
  ;; buffer, which corrupted the JSON-RPC stream (stray \r inside JSON, and
  ;; "Resource temporarily unavailable" on large completion lists).  You hit
  ;; that over SSH; modern eglot already asks for a pipe on local processes,
  ;; so this is most likely redundant now.  Comment it out, request completion
  ;; on a large namespace (e.g. `dplyr::`), and if nothing breaks, delete it.
  (advice-add 'eglot--connect :around
              (lambda (orig-fn &rest args)
                (let ((process-connection-type nil))
                  (apply orig-fn args)))))

;; ===========================================================================
;; 10. Languages
;; ===========================================================================

(use-package ess
  :defer t
  :mode ("\\.[rR]\\'" . ess-r-mode)
  :init (setq ess-indent-offset 2
              ess-style 'RStudio
              ess-use-flymake nil       ; eglot supplies diagnostics
              ess-ask-for-ess-directory nil
              ;; `inferior-R-program-name' (the old config's name) has been
              ;; obsolete since ESS 18.10; setting it does nothing on a
              ;; current ESS, so the R console would quietly use whichever R
              ;; is first on PATH instead of the one you meant.
              inferior-ess-r-program (or (executable-find "R")
                                         (expand-file-name "~/.local/bin/R"))))

(defface ess-namespace-face
  '((t (:foreground "#a10352" :slant italic :inherit default)))
  "Face for highlighting package namespaces in ESS R mode.")

(defun my/ess-highlight-namespace ()
  "Highlight package namespaces distinctly in ESS R mode."
  (font-lock-add-keywords
   nil '(("\\b\\([[:alnum:].]+::\\)" 1 'ess-namespace-face prepend))))

(add-hook 'ess-r-mode-hook #'my/ess-highlight-namespace)
(add-hook 'inferior-ess-mode-hook
          (lambda () (display-line-numbers-mode -1)))

;; Built-in python.el, not the external python-mode package.  The external one
;; defines a *different* major mode with the same name and quietly breaks any
;; hook or eglot association that assumes the built-in.
(use-package python
  :straight nil
  :defer t
  :init (setq python-indent-guess-indent-offset-verbose nil))

(use-package markdown-mode
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'"       . gfm-mode)
         ("\\.markdown\\'" . gfm-mode))
  :config (setq markdown-fontify-code-blocks-natively t))

;; Backends for md-preview.el (loaded in §14).
(use-package simple-httpd
  :defer t
  :config (setq httpd-port 8090))

(use-package impatient-mode :defer t)

;; ===========================================================================
;; 11. Org
;; ===========================================================================
;; Base org behaviour only.  The research layer -- org-roam, citar, org-ql --
;; lives in knowledge.el, which is deliberately frozen and loaded last.
;; Nothing here should overlap with it.

(use-package org
  :straight nil                         ; pinned built-in in section 1
  :defer t
  :config
  (setq org-startup-indented t
        org-startup-folded 'content
        org-hide-emphasis-markers t
        org-return-follows-link t
        org-fold-catch-invisible-edits 'show-and-error
        org-src-fontify-natively t
        org-src-tab-acts-natively t
        org-src-preserve-indentation t
        org-edit-src-content-indentation 0
        org-export-with-broken-links 'mark
        ;; Neither of these can render in a TTY.  knowledge.el already takes
        ;; this position deliberately (section 10.2: source in the buffer,
        ;; browser for rendered output), so this just makes it explicit.
        org-startup-with-inline-images nil
        org-startup-with-latex-preview nil)
  (add-hook 'org-mode-hook #'visual-line-mode))

;; ===========================================================================
;; 12. Tools
;; ===========================================================================

;; Not in the old config, and conspicuously so given how much R package work
;; you do.  Autoloaded: costs nothing until called.
(use-package magit
  :defer t
  :commands (magit-status magit-blame magit-log-current)
  :init (setq magit-define-global-key-bindings nil)
  :config (setq magit-diff-refine-hunk 'all))

(use-package vterm
  :defer t
  :commands (vterm)
  :config
  (setq vterm-max-scrollback 10000
        vterm-timer-delay 0.01))

(add-to-list 'display-buffer-alist
             '("\\*vterm\\*"
               (display-buffer-reuse-window display-buffer-in-side-window)
               (side . bottom)
               (slot . 0)
               (window-height . 0.3)))

(use-package gptel :defer t :commands (gptel gptel-send))

;; ===========================================================================
;; 13. Custom functions
;; ===========================================================================

(defun my/toggle-vterm ()
  "Toggle between vterm and the previous buffer."
  (interactive)
  (if (derived-mode-p 'vterm-mode)
      (switch-to-prev-buffer)
    (vterm)))

(defun my/toggle-r-console ()
  "Toggle between the *R* process buffer and the previous buffer."
  (interactive)
  (if (string= (buffer-name) "*R*")
      (switch-to-prev-buffer)
    (if (get-buffer "*R*")
        (pop-to-buffer "*R*")
      (R))))

(defun my/extract-package-function ()
  "Return the symbol at point like `package::function' as `packagefunction'."
  (interactive)
  (save-excursion
    (skip-chars-backward "[:alnum:]_")
    (let* ((start (point))
           (end (progn (skip-chars-forward "[:alnum:]_:") (point)))
           (raw (buffer-substring-no-properties start end))
           (clean (replace-regexp-in-string "::" "" raw)))
      (message "%s" clean)
      clean)))

(defvar my/previous-window-configuration nil
  "Stored window configuration from before the last maximize.")

(defun my/toggle-maximize-window ()
  "Toggle between maximizing this window and restoring the previous layout."
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

(defun my/goto-first-number-on-line ()
  "If point isn't on a digit, move to the first digit in the current line."
  (unless (looking-at "[0-9]")
    (beginning-of-line)
    (if (re-search-forward "[0-9]+" (line-end-position) t)
        (goto-char (match-beginning 0))
      (error "No number on current line"))))

(defun my/increment-number-at-point ()
  "Increment the decimal number under point by 1."
  (interactive)
  (my/goto-first-number-on-line)
  (skip-chars-backward "0-9")
  (unless (looking-at "[0-9]+")
    (error "No number at point"))
  (replace-match (number-to-string (1+ (string-to-number (match-string 0))))))

(defun my/decrement-number-at-point ()
  "Decrement the decimal number under point by 1."
  (interactive)
  (my/goto-first-number-on-line)
  (skip-chars-backward "0-9")
  (unless (looking-at "[0-9]+")
    (error "No number at point"))
  (replace-match (number-to-string (1- (string-to-number (match-string 0))))))

(defun my/R-insert-pipe ()
  "Insert the R pipe |>."
  (interactive)
  (insert " |> "))

(defun my/R-insert-assignment ()
  "Insert the R assignment arrow <-."
  (interactive)
  (insert " <- "))

;; --- R abbrev expansions ----------------------------------------------------

(defun my-abbrevs/insert-r-fun ()
  "Insert an R function template."
  (interactive)
  (insert "
f <- function(
  x1,
  x2,
  ...
) {

  TRUE

}")
  t)

(defun my-abbrevs/insert-db-connection-fun ()
  "Insert a DatabaseConnector connection template."
  (interactive)
  (insert "
connection <- DatabaseConnector::connect(connectionDetails)
on.exit(DatabaseConnector::disconnect(connection))
")
  t)

(defun my-abbrevs/insert-roxygen-doc-fun ()
  "Insert a roxygen documentation skeleton."
  (interactive)
  (insert "\n" "#' Title\n" "#'\n" "#' @description\n" "#'\n"
          "#' @param\n" "#' @param\n" "#'\n" "#' @return\n" "#'\n"
          "#' @export\n" "#'\n" "#' @examples\n")
  t)

(defun my-abbrevs/insert-query-sql ()
  "Insert a DatabaseConnector::querySql template."
  (interactive)
  (insert "DatabaseConnector::querySql(\n"
          "  connection = connection,\n"
          "  sql = glue::glue(\n"
          "    \"\n"
          "    \"\n"
          "  )\n"
          ")\n")
  t)

(define-abbrev global-abbrev-table "collapsebutton" ""
  (lambda ()
    (insert "<button class=\"btn btn-outline-primary btn-sm\" type=\"button\" data-bs-toggle=\"collapse\" data-bs-target=\"#REPLACE\">\n"
            "  Show\n"
            "</button>\n"
            "::: {#REPLACE .collapse}\n"
            "\n"
            "\n"
            ":::\n")
    t))

(with-eval-after-load 'ess-r-mode
  (define-abbrev ess-r-mode-abbrev-table "Rfun"   "" 'my-abbrevs/insert-r-fun)
  (define-abbrev ess-r-mode-abbrev-table "dbcon"  "" 'my-abbrevs/insert-db-connection-fun)
  (define-abbrev ess-r-mode-abbrev-table "roxy"   "" 'my-abbrevs/insert-roxygen-doc-fun)
  (define-abbrev ess-r-mode-abbrev-table "rquery" "" 'my-abbrevs/insert-query-sql))

;; --- LLM query scratch buffers ----------------------------------------------

(defvar llm-query-template
  "# Background\n\n- \n\n# Task\n\n- \n\n# Instructions\n\n- \n\n# Notes\n\n- \n"
  "Template for LLM queries.")

(defvar llm-queries-dir "~/Documents/queries/"
  "Directory where LLM query markdown files are saved.")

(defun my/llm-new-query ()
  "Open a new scratch buffer with the LLM query template."
  (interactive)
  (let ((buf (generate-new-buffer "*llm-query*")))
    (switch-to-buffer buf)
    (insert llm-query-template)
    (markdown-mode)
    (goto-char (point-min))
    (forward-line 2)
    (message "LLM query ready.  SPC c s to save.")))

(defun my/llm-save-query ()
  "Save the current buffer as a timestamped markdown file."
  (interactive)
  (unless (file-directory-p llm-queries-dir)
    (make-directory llm-queries-dir t))
  (let* ((timestamp (format-time-string "%Y%m%d_%H%M%S"))
         (name (read-string "Query name (blank for timestamp only): "))
         (slug (if (string-blank-p name)
                   timestamp
                 (concat timestamp "_"
                         (replace-regexp-in-string "[^a-zA-Z0-9_-]" "_" name))))
         (filepath (expand-file-name (concat slug ".md") llm-queries-dir)))
    (write-region (point-min) (point-max) filepath)
    (message "Saved: %s" filepath)))

;; ===========================================================================
;; 14. Keymaps
;; ===========================================================================

(global-set-key (kbd "M-b") #'switch-to-buffer)
(global-set-key (kbd "C-c t") #'my/toggle-vterm)
(global-set-key (kbd "C-c r") #'my/toggle-r-console)

;; Raw keymaps bound as prefixes, rather than `define-prefix-command'.  Same
;; behaviour, but the byte-compiler sees a real `defvar' instead of a free
;; variable, and which-key gets a readable label from the table below.
(defvar my-space-map   (make-sparse-keymap) "Leader map (SPC).")
(defvar my-space-f-map (make-sparse-keymap) "Leader: files.")
(defvar my-space-w-map (make-sparse-keymap) "Leader: windows.")
(defvar my-space-b-map (make-sparse-keymap) "Leader: bookmarks.")
(defvar my-space-g-map (make-sparse-keymap) "Leader: gptel.")
(defvar my-space-c-map (make-sparse-keymap) "Leader: capture/code.")
(defvar my-space-n-map (make-sparse-keymap) "Leader: numbers.")
(defvar my-space-r-map (make-sparse-keymap) "Leader: roam.")
(defvar my-space-m-map (make-sparse-keymap) "Leader: markdown.")
(defvar my-space-v-map (make-sparse-keymap) "Leader: version control.")
(defvar my-space-a-map (make-sparse-keymap) "Leader: act (embark).")

(define-key evil-normal-state-map (kbd "SPC") my-space-map)
(define-key evil-motion-state-map (kbd "SPC") my-space-map)
(define-key evil-normal-state-map (kbd "s") 'evil-surround-edit)
(define-key evil-visual-state-map (kbd "s") 'evil-surround-region)

(define-key my-space-map (kbd "f") my-space-f-map)
(define-key my-space-map (kbd "w") my-space-w-map)
(define-key my-space-map (kbd "b") my-space-b-map)
(define-key my-space-map (kbd "g") my-space-g-map)
(define-key my-space-map (kbd "c") my-space-c-map)
(define-key my-space-map (kbd "n") my-space-n-map)
(define-key my-space-map (kbd "r") my-space-r-map)
(define-key my-space-map (kbd "m") my-space-m-map)
(define-key my-space-map (kbd "v") my-space-v-map)
(define-key my-space-map (kbd "a") my-space-a-map)

(with-eval-after-load 'which-key
  (which-key-add-key-based-replacements
    "SPC f" "files"      "SPC w" "windows"  "SPC b" "bookmarks"
    "SPC g" "gptel"      "SPC c" "capture"  "SPC n" "numbers"
    "SPC r" "roam"       "SPC m" "markdown" "SPC v" "git"
    "SPC a" "act"))

;; SPC f -- files
(define-key my-space-f-map (kbd "f") #'find-file)
(define-key my-space-f-map (kbd "r") #'consult-recent-file)
(define-key my-space-f-map (kbd "c") #'my/copy-directory-path-to-kill-ring)

;; SPC w -- windows
(define-key my-space-w-map (kbd "w") #'evil-window-next)
(define-key my-space-w-map (kbd "q") #'evil-window-prev)
(define-key my-space-w-map (kbd "l") #'evil-window-right)
(define-key my-space-w-map (kbd "h") #'evil-window-left)
(define-key my-space-w-map (kbd "m") #'my/toggle-maximize-window)
(define-key my-space-w-map (kbd "b") #'switch-to-buffer)
(define-key my-space-w-map (kbd "k") #'kill-buffer)
(define-key my-space-w-map (kbd "3") #'split-window-right)
(define-key my-space-w-map (kbd "2") #'split-window-below)
(define-key my-space-w-map (kbd "0") #'delete-window)
(define-key my-space-w-map (kbd "1") #'delete-other-windows)

;; SPC b -- bookmarks
(define-key my-space-b-map (kbd "b") #'bookmark-jump)
(define-key my-space-b-map (kbd "s") #'bookmark-set)

;; SPC g -- gptel
(define-key my-space-g-map (kbd "g")   #'gptel)
(define-key my-space-g-map (kbd "RET") #'gptel-send)
(define-key my-space-g-map (kbd "f")   #'gptel-add-file)

;; SPC v -- version control
(define-key my-space-v-map (kbd "v") #'magit-status)
(define-key my-space-v-map (kbd "b") #'magit-blame)
(define-key my-space-v-map (kbd "l") #'magit-log-current)

;; SPC a -- embark ("act")
(define-key my-space-a-map (kbd "a") #'embark-act)
(define-key my-space-a-map (kbd "e") #'embark-export)

;; SPC n -- numbers
(define-key my-space-n-map (kbd "i") #'my/increment-number-at-point)
(define-key my-space-n-map (kbd "d") #'my/decrement-number-at-point)

;; SPC c -- LLM query capture
(define-key my-space-c-map (kbd "n") #'my/llm-new-query)
(define-key my-space-c-map (kbd "s") #'my/llm-save-query)
(define-key my-space-c-map (kbd "e") #'my/extract-package-function)

;; SPC r -- roam
(define-key my-space-r-map (kbd "j") #'org-roam-buffer-toggle)
(define-key my-space-r-map (kbd "f") #'org-roam-node-find)
(define-key my-space-r-map (kbd "i") #'org-roam-node-insert)
(define-key my-space-r-map (kbd "l") #'citar-open-notes)

;; SPC m -- markdown preview
(define-key my-space-m-map (kbd "p") #'my/md-preview)
(define-key my-space-m-map (kbd "k") #'my/md-preview-stop)

;; --- ESS bindings -----------------------------------------------------------
;; C-SPC survives a terminal (it is C-@) but C-S-SPC and C-<tab> do NOT --
;; a terminal has no way to encode them.  With kkp active they work; the
;; M-- and SPC c e bindings below are the fallbacks that always work.
;;
;; IMPORTANT: these must hang off `ess-r-mode' and `ess-inf', not `ess'.
;; ESS is split across files: ess.el provides `ess' and defines neither map;
;; `ess-r-mode-map' comes from ess-r-mode.el and `inferior-ess-mode-map' from
;; ess-inf.el.  `with-eval-after-load 'ess' fires the moment ess.el finishes,
;; which is *before* either map exists -- giving
;; "File mode specification error: (void-variable ess-r-mode-map)" and, worse,
;; aborting the rest of major-mode setup so `ess-r-mode-hook' never runs and
;; eglot never starts.

(defun my/ess-bind-keys (map)
  "Install the R editing keys into MAP."
  (define-key map (kbd "C-SPC")   #'my/R-insert-pipe)
  (define-key map (kbd "M--")     #'my/R-insert-assignment)  ; RStudio's key
  (define-key map (kbd "C-S-SPC") #'my/R-insert-assignment)  ; needs kkp
  (define-key map (kbd "C-<tab>") #'my/extract-package-function)) ; needs kkp

(with-eval-after-load 'ess-r-mode
  (my/ess-bind-keys ess-r-mode-map))

(with-eval-after-load 'ess-inf
  (my/ess-bind-keys inferior-ess-mode-map))

;; ===========================================================================
;; 15. External files
;; ===========================================================================
;; Loaded last, so they can rely on everything above.  The old config loaded
;; knowledge.el on line 6 -- before use-package existed.

(let ((md-preview (expand-file-name "md-preview.el" user-emacs-directory)))
  (when (file-exists-p md-preview)
    (load md-preview nil 'nomessage)))

(let ((knowledge "~/Documents/my-knowledge/emacs/knowledge.el"))
  (when (file-exists-p (expand-file-name knowledge))
    (load (expand-file-name knowledge) nil 'nomessage)))

;;; init.el ends here
