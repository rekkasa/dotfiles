;;; md-preview.el --- Live GitHub-styled Markdown preview in Firefox -*- lexical-binding: t; -*-

;; Live-previews the *buffer* (not the file on disk), so edits show up in
;; the browser as you type. Rendering is done by pandoc; styling by
;; GitHub's own github-markdown-css; display by surf.
;;
;; Usage:  M-x my/md-preview      (or SPC m p)
;;         M-x my/md-preview-stop (or SPC m k)
;;
;; Requires the `pandoc' and `surf' binaries on PATH.

;; ---------------------------------------------------------------------------
;; Packages
;; ---------------------------------------------------------------------------

;; You reference `markdown-mode' in my/llm-new-query but never install it.
(use-package markdown-mode
  :ensure t
  :mode (("README\\.md\\'" . gfm-mode)
         ("\\.md\\'"       . gfm-mode)
         ("\\.markdown\\'" . gfm-mode))
  :config
  ;; syntax-highlight fenced code blocks inside Emacs too
  (setq markdown-fontify-code-blocks-natively t))

(use-package simple-httpd
  :ensure t
  :config (setq httpd-port 8090))

(use-package impatient-mode
  :ensure t)

;; ---------------------------------------------------------------------------
;; Configuration
;; ---------------------------------------------------------------------------

(defvar my/md-preview-command
  '("pandoc" "--from=gfm" "--to=html5" "--no-highlight")
  "Program and arguments used to turn Markdown into an HTML fragment.
`--no-highlight' is deliberate: without it pandoc emits its own
highlighting classes, which github-markdown-css does not style.
Plain `<pre><code>' blocks get GitHub's code-block styling instead.")

(defvar my/md-preview-browser-command
  '("surf" "-S" "-B")
  "Browser program and arguments; the URL is appended as the last argument.
`-S' force-enables JavaScript, which impatient-mode's long-polling
needs — without it the page loads once and never updates again.
`-B' force-enables scrollbars. Drop either if your config.h already
does the right thing. Add e.g. \"-z\" \"1.3\" to zoom on a HiDPI screen.")

(defvar my/md-preview-css-url
  "https://cdn.jsdelivr.net/npm/github-markdown-css@5/github-markdown.css"
  "Where to fetch GitHub's Markdown stylesheet from, once.")

(defvar my/md-preview-css-file
  (expand-file-name "md-preview/github-markdown.css" user-emacs-directory)
  "Local cache of the stylesheet, so previews work offline.")

(defvar my/md-preview--css-cache nil
  "Stylesheet contents, cached for the session.")

(defvar my/md-preview--browser-proc nil
  "The running preview browser, if any.
surf has no tabs, so we track the window and replace it rather than
accumulating one window per invocation.")

;; ---------------------------------------------------------------------------
;; Internals
;; ---------------------------------------------------------------------------

(defun my/md-preview--css ()
  "Return the GitHub stylesheet as a string, or nil if unavailable.
Downloads it to `my/md-preview-css-file' on first use."
  (or my/md-preview--css-cache
      (setq my/md-preview--css-cache
            (condition-case err
                (progn
                  (unless (file-exists-p my/md-preview-css-file)
                    (make-directory (file-name-directory my/md-preview-css-file) t)
                    (url-copy-file my/md-preview-css-url my/md-preview-css-file t))
                  (with-temp-buffer
                    (insert-file-contents my/md-preview-css-file)
                    (buffer-string)))
              (error
               (message "md-preview: could not fetch CSS (%s), falling back to CDN link"
                        (error-message-string err))
               nil)))))

(defun my/md-preview--render (buffer)
  "Convert BUFFER's Markdown to an HTML fragment via `my/md-preview-command'."
  (condition-case err
      (with-temp-buffer
        (insert-buffer-substring-no-properties buffer)
        (let ((exit (apply #'call-process-region
                           (point-min) (point-max)
                           (car my/md-preview-command)
                           t t nil
                           (cdr my/md-preview-command))))
          (if (eq exit 0)
              (buffer-string)
            (format "<pre>pandoc exited with %s:\n%s</pre>"
                    exit (buffer-string)))))
    (error (format "<pre>%s</pre>" (error-message-string err)))))

(defun my/md-preview-filter (buffer)
  "impatient-mode filter: render BUFFER as a GitHub-styled HTML page."
  (let ((css  (my/md-preview--css))
        (body (my/md-preview--render buffer)))
    (princ
     (concat
      ;; the doctype matters: without it browsers fall into quirks mode and
      ;; the dark-theme table styling breaks
      "<!DOCTYPE html>\n<html lang=\"en\"><head><meta charset=\"utf-8\">"
      "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">"
      (if css
          (concat "<style>" css "</style>")
        (format "<link rel=\"stylesheet\" href=\"%s\">" my/md-preview-css-url))
      ;; the layout rules GitHub itself uses around the stylesheet
      "<style>"
      "body{margin:0;}"
      ".markdown-body{box-sizing:border-box;min-width:200px;max-width:980px;"
      "margin:0 auto;padding:45px;}"
      "@media(max-width:767px){.markdown-body{padding:15px;}}"
      "@media(prefers-color-scheme:dark){body{background-color:#0d1117;}}"
      "</style></head><body><article class=\"markdown-body\">"
      body
      "</article></body></html>")
     (current-buffer))))

;; ---------------------------------------------------------------------------
;; Commands
;; ---------------------------------------------------------------------------

(defun my/md-preview--open (url)
  "Show URL in the preview browser, replacing any window already open."
  (when (process-live-p my/md-preview--browser-proc)
    (delete-process my/md-preview--browser-proc))
  (setq my/md-preview--browser-proc
        (apply #'start-process "md-preview-browser" nil
               (append my/md-preview-browser-command (list url))))
  ;; don't let Emacs ask about the subprocess on exit, and don't spam
  ;; a *Messages* line when the window is closed
  (set-process-query-on-exit-flag my/md-preview--browser-proc nil)
  (set-process-sentinel my/md-preview--browser-proc #'ignore))

(defun my/md-preview ()
  "Live-preview the current buffer as GitHub-flavoured Markdown."
  (interactive)
  (dolist (bin (list (car my/md-preview-command)
                     (car my/md-preview-browser-command)))
    (unless (executable-find bin)
      (user-error "`%s' not found on PATH — install it first" bin)))
  (unless (and (fboundp 'httpd-running-p) (httpd-running-p))
    (httpd-start))
  (impatient-mode 1)
  (imp-set-user-filter #'my/md-preview-filter)
  (my/md-preview--open
   (format "http://localhost:%d/imp/live/%s/"
           httpd-port (url-hexify-string (buffer-name))))
  (message "Live preview: edits appear in the browser without saving"))

(defun my/md-preview-stop ()
  "Stop live-previewing the current buffer and close the preview window."
  (interactive)
  (impatient-mode -1)
  (when (process-live-p my/md-preview--browser-proc)
    (delete-process my/md-preview--browser-proc))
  (setq my/md-preview--browser-proc nil)
  (message "Live preview stopped for %s" (buffer-name)))

(provide 'md-preview)
;;; md-preview.el ends here
