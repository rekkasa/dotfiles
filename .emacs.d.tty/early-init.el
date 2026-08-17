;;; early-init.el --- Runs before the package system and the first frame -*- lexical-binding: t; -*-

;;; Commentary:
;; Emacs 27+ loads this before `package-initialize' and before any frame is
;; created.  Everything here exists to make startup cheap; nothing here
;; configures behaviour you would notice while editing.

;;; Code:

;; ---------------------------------------------------------------- package.el
;; straight.el and package.el will fight over `load-path' if both are live.
;; This must happen here, not in init.el -- by then package.el has run.
(setq package-enable-at-startup nil)

;; ----------------------------------------------------------------------- GC
;; Garbage collection during startup is pure waste: almost nothing collected
;; during init is garbage.  Turn it off entirely, then hand the job to gcmh
;; (see init.el), which raises the threshold while you type and collects when
;; you pause.  The old config's permanent 100MB threshold is the common
;; alternative, but it trades many small pauses for occasional long ones.
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)

;; --------------------------------------------------------- file-name handlers
;; Every `load' consults `file-name-handler-alist' (TRAMP, jka-compr, ...).
;; During init that's thousands of regexp matches against paths that are
;; always local.  Restore it before anything can want a remote file.
(defvar my/saved-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

(add-hook 'emacs-startup-hook
          (lambda ()
            (setq file-name-handler-alist my/saved-file-name-handler-alist
                  gc-cons-percentage 0.1)))

;; -------------------------------------------------------------------- chrome
;; Mostly moot in a TTY, but a daemon serves GUI frames too (emacsclient -c),
;; and setting these here means the widgets are never created rather than
;; created and then destroyed.
(setq default-frame-alist
      '((menu-bar-lines . 0)
        (tool-bar-lines . 0)
        (vertical-scroll-bars . nil)
        (horizontal-scroll-bars . nil)))

(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil
      tooltip-mode nil)

(setq frame-inhibit-implied-resize t   ; don't resize the frame per font change
      inhibit-startup-screen t
      inhibit-startup-message t
      initial-scratch-message nil
      inhibit-x-resources t
      use-file-dialog nil
      use-dialog-box nil)

;; ------------------------------------------------------------- native-comp
;; Warnings from third-party packages are noise you cannot act on.  JIT
;; compilation on means the first use of a package is slightly slower and
;; every use after that is faster.
(setq native-comp-async-report-warnings-errors 'silent
      native-comp-jit-compilation t
      load-prefer-newer t)

;; Skip site-wide startup files; distro defaults tend to enable package.el.
(setq site-run-file nil)

;;; early-init.el ends here
