;; 1) Don’t let TRAMP ever log its debug messages
(setq tramp-verbose 0)

;; ─────── Make Emacs see your local ~/.local/bin ──────────────────────────
(let ((my-bin (expand-file-name "~/.local/bin")))
  ;; for Emacs subprocesses (eglot on localhost)
  (add-to-list 'exec-path my-bin)
  (setenv      "PATH"   (concat my-bin ":" (getenv "PATH"))))

;; ─────── Teach TRAMP to use a login bash and prepend ~/.local/bin ────────
(with-eval-after-load 'tramp
  (setq tramp-remote-shell       "/bin/bash"
        tramp-remote-shell-login t
        tramp-remote-shell-args  '("-l" "-i"))
  ;; so that remote “Rscript” resolves to ~/​.local/bin/Rscript
  (add-to-list 'tramp-remote-path "~/.local/bin"))

;; ─────── Tell Eglot to start R languageserver with the generic Rscript ──
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '(ess-r-mode . ("Rscript" "-e" "languageserver::run()")))
  (add-hook 'eglot-managed-mode-hook #'corfu-mode)

  ;; If for any reason Eglot’s CAPF isn't first, force it:
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              (setq-local completion-at-point-functions
                          (cons #'eglot-completion-at-point
                                (remq #'eglot-completion-at-point
                                      completion-at-point-functions))))))

