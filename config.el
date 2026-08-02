;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;;(setq doom-font (font-spec :family "Fira Code" :size 12 :weight 'semi-light)
;;      doom-variable-pitch-font (font-spec :family "Fira Sans" :size 13))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'doom-old-hope)
;; (setq doom-theme 'doom-laserwave)
;; (setq doom-theme 'doom-dark+)
;; (setq doom-theme 'doom-snazzy)
(setq doom-theme 'doom-monokai-pro)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")


;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
(use-package! lsp-pyright :defer
              :custom (lsp-pyright-langserver-command "basedpyright"))
(after! lsp-ui
  (map! :map lsp-ui-mode-map
        :leader
        :prefix ("l" . "LSP")
        "k" #'lsp-ui-peek-find-references))
(after! lsp-mode
  (map! :map lsp-mode-map
        :leader
        :prefix ("l" . "LSP")
        "n" #'lsp-rename
        "f" #'lsp-format-buffer
        "a" #'lsp-execute-code-action
        "l" #'lsp-workspace-restart
        "r" #'lsp-find-references
        "i" #'lsp-find-implementation
        "f" #'lsp-clangd-find-other-file
        "s" #'consult-lsp-file-symbols
        ))

(remove-hook 'doom-first-input-hook #'evil-snipe-mode)

;;;;;;;;;;;
;; CMAKE ;;
;;;;;;;;;;;

(defun my/cmake-run-google-test-at-point ()
  (interactive)
  (save-excursion
    (let ((case-fold-search nil)
          (found (re-search-backward "^\\s-*TEST\\(_F\\)?(\\([^,]+\\)\\s-*,\\s-*\\([^\\)]+\\)" nil t)))
      (when found
        (let ((test-args (format "--gtest_filter=%s.%s" (string-trim (match-string 2)) (string-trim (match-string 3)))))
          (cmake-integration-run-last-target-with-arguments test-args))))))

(after! cmake-integration
  (map! :map cmake-integration-project-mode-map
        :localleader
        "cc" #'cmake-integration-save-and-compile
        "ck" #'cmake-integration-cmake-reconfigure
        "cr" #'cmake-integration-run-last-target
        "car" #'cmake-integration-run-last-target-with-arguments
        "cg" #'my/cmake-run-google-test-at-point
        "cd" #'cmake-integration-debug-last-target))
(add-hook! '(c-ts-mode-hook c++-ts-mode-hook) #'cmake-integration-project-mode)

;; --- shell configuration ---
(use-package! ghostel-compile
  :hook
  (after-init . ghostel-compile-global-mode))
(use-package! ghostel-comint
  :hook
  (after-init . ghostel-comint-global-mode))
(use-package! evil-ghostel
  :after (ghostel evil)
  :hook (ghostel-mode . evil-ghostel-mode))

;; ghostel derives from fundamental-mode and ships no evil integration, so
;; terminals would otherwise come up in normal state. Land in insert so keys
;; reach the terminal. This covers claude-code-ide too, since it uses the
;; ghostel backend. C-z drops to emacs state; ESC to normal state.
                                        ;(after! evil
                                        ;  (evil-set-initial-state 'ghostel-mode 'insert))

;; ghostel leaves C-c C-u free. Send it through the terminal's key encoder
;; rather than a raw "\x15" so kitty-keyboard-protocol apps see it too.
(defun my/ghostel-send-C-u ()
  "Send \\`C-u' to the terminal, clearing the current input line."
  (interactive)
  (ghostel-send-key "u" "ctrl"))

(after! ghostel
  ;; :n shadows evil's `c' operator in ghostel buffers (so cw/ciw are gone
  ;; there), which is fine — there is no editable buffer text to change.
  (map! :map ghostel-mode-map
        :i "C-c C-g" #'ghostel-send-C-g
        :g "C-c C-u" #'my/ghostel-send-C-u
        :n "cc" #'my/ghostel-send-C-u))

;; --- git link ---
(after! git-link
  (setq git-link-use-commit t)

  (general-define-key
   :states '(normal visual motion)
   :keymaps 'override
   "<SPC>ml" #'git-link))

;; git link

;;;;;;;;;
;; LLM ;;
;;;;;;;;;

(use-package! claude-code-ide
  :bind ("<f2>" . claude-code-ide-menu) ; Set your favorite keybinding
  :config
  (setq claude-code-ide-terminal-backend 'ghostel)
  (claude-code-ide-emacs-tools-setup)) ; Optionally enable Emacs MCP tools

;; claude-code-ide ships no minor mode of its own, so buffer-local keys would
;; otherwise have to go in ghostel's shared mode maps and leak into every
;; terminal. This map only exists where the minor mode is enabled.
;; Kept at top level (not in :config) so the definitions are byte-compilable.
(defvar-keymap claude-code-ide-buffer-mode-map
  :doc "Keys active only in Claude Code terminal buffers.")

(define-minor-mode claude-code-ide-buffer-mode
  "Buffer-local keybindings for Claude Code sessions."
  :keymap claude-code-ide-buffer-mode-map)

;; Runs with the Claude buffer current; evil-normalize-keymaps is what makes
;; the per-state bindings below visible to evil.
(defun my/claude-code-ide-enable-buffer-mode ()
  (claude-code-ide-buffer-mode 1)
  (evil-normalize-keymaps))
(advice-add 'claude-code-ide--setup-terminal-keybindings :after
            #'my/claude-code-ide-enable-buffer-mode)

(map! :map claude-code-ide-buffer-mode-map
      :i "M-<RET>" #'claude-code-ide-insert-newline
      :g "<f1>" #'claude-code-ide-send-escape)

;;;;;;;;
;; UI ;;
;;;;;;;;


;; --- imenu ---

;; We need a nerd-font compatible font like this one:
;; brew install font-iosevka-term-nerd-font
(use-package! symbols-outline
  :commands symbols-outline-show
  ;; `:init', not `:config': the binding has to exist *before* the package
  ;; loads, since pressing the key is what autoloads it.
  :init
  (setq symbols-outline-fetch-fn #'symbols-outline-lsp-fetch)
  (map! :leader
        :prefix ("l" . "LSP")
        :desc "Symbols outline" "w" #'symbols-outline-show)
  :config
  (symbols-outline-follow-mode t)
  ;; `symbols-outline-mode' derives from `special-mode', so its major-mode map
  ;; loses to evil's state maps (RET -> `evil-ret' in motion state). Rebind as
  ;; an evil auxiliary binding so it actually wins.
  (map! :map symbols-outline-mode-map
        :nvm "RET" #'symbols-outline-visit
        :nvm [return] #'symbols-outline-visit
        :nvm "M-RET" #'symbols-outline-visit-and-quit))

;; --- mode line ---

(use-package! rich-minority
  :defer nil
  :config
  (unless rich-minority-mode (rich-minority-mode 1))
  (setq rm-whitelist (format "^ \\(%s\\)$"
                             (mapconcat #'identity
                                        '("Projectile.*" ".*Lsp.*")
                                        "\\|"))))

(after! lsp-mode
  (setq lsp-modeline-workspace-status-enable t
        lsp-modeline-diagnostics-enable t
        lsp-modeline-code-actions-enable t))

;; --- protobuf ---
;; protols is fully-featured lsp language server that uses protoc (unlike buf)
;; cargo install protols
(after! lsp-mode
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection
                     (lambda () (list (or (executable-find "protols") "protols"))))
    :activation-fn (lsp-activate-on "protobuf")
    :language-id "protobuf"
    :priority 1
    :server-id 'protols)))

(add-hook! 'protobuf-mode-hook #'lsp!)

;; disable protoc, it doesn't know how to resolve paths on its own
(after! flycheck
  (add-hook! 'protobuf-mode-hook
    (add-to-list 'flycheck-disabled-checkers 'protobuf-protoc)))

(use-package! mood-line
  :config
  (mood-line-mode t)
  (defun my/mood-line-segment-cursor-position ()
    (format-mode-line "%l行%c列"))
  (defun my/lsp-workspace-statuses ()
    "Return an alist of (SERVER-ID . STATUS) for this buffer's workspaces.
STATUS is `starting' or `initialized'."
    (mapcar (lambda (ws)
              (cons (lsp--client-server-id (lsp--workspace-client ws))
                    (lsp--workspace-status ws)))
            (lsp-workspaces)))
  (defun my/lsp-overall-status ()
    "Return `connected', `starting', or `exited' for the current buffer."
    (if (and (bound-and-true-p lsp-mode) (fboundp 'lsp-workspaces))
        (let ((workspaces (lsp-workspaces)))
          (cond
           ((null workspaces) "disconnected")
           ((seq-some (lambda (ws) (eq (lsp--workspace-status ws) "starting")) workspaces)
            'starting)
           (t "connected")))
      ""))
  (setq mood-line-format
        (mood-line-defformat
         :left
         (" " (mood-line-segment-modal) " "
          (or (mood-line-segment-buffer-status) "  ")  ; alternative char is full-width
          "[" (mood-line-segment-project) "]/"
          (mood-line-segment-buffer-name) "  "
          (mood-line-segment-anzu) "  "
          (mood-line-segment-multiple-cursors) "  "
          (my/mood-line-segment-cursor-position) " "
          (mood-line-segment-scroll) "")
         :right
         ((mood-line-segment-vc) "  "
          (mood-line-segment-major-mode) "  "
          (mood-line-segment-misc-info)
          ;; "LSP["
          ;; (eval global-mode-string)
          ;; "]"
          ;; (my/lsp-overall-status) "  "
                                        ; TODO - abbreviate this from "Checking" and "No issues"
                                        ; TODO - add a segment that captures the status of the LSP process
          (mood-line-segment-checker) "  "
          (mood-line-segment-process) "  " " ")
         ))
  :custom
  (mood-line-segment-modal-evil-state-alist
   '((normal . ("[N]" . font-lock-variable-name-face))
     (insert . ("[I]" . font-lock-string-face))
     (visual . ("[V]" . font-lock-keyword-face))
     (replace . ("[R]" . font-lock-type-face))
     (motion . ("[M]" . font-lock-constant-face))
     (operator . ("[O]" . font-lock-function-name-face))
     (emacs . ("[E]" . font-lock-builtin-face))))
  (mood-line-glyph-alist
   '((:buffer-modified . ?変)
     (:buffer-read-only . ?鍵))))

(after! dape-mode
  (global-set-key (kbd "<f7>") 'dape-step-in)
  (global-set-key (kbd "<f8>") 'dape-next)
  (global-set-key (kbd "<f9>") 'dape-continue)
  (global-set-key (kbd "<f10>") 'dape-step-out))

;; --- projectile ---
(after! projectile
  (map! :map projectile-mode-map
        "<f12>" 'projectile-find-file))

;; --- docker ---
(use-package! treesit
  :config
  (add-to-list 'treesit-language-source-alist
               '(dockerfile "https://github.com/camdencheek/tree-sitter-dockerfile"))
  (add-to-list 'major-mode-remap-alist '(dockerfile-mode . dockerfile-ts-mode))
  ;; Dockerfile was not loading in dockerfile-mode, so was not being remapped
  (add-to-list 'auto-mode-alist '("Dockerfile" . dockerfile-ts-mode)))

;;;;;;;;;;;;;
;; EDITING ;;
;;;;;;;;;;;;;

;; --- multiple cursors ---

;; Doom rewires evil-mc so `evil-mc-mode' is only on while cursors exist, which
;; makes `evil-mc-initialize-active-state' an exact "session started" boundary:
;; `evil-mc-run-cursors-before' only fires it when no cursors exist yet, so it
;; runs once per session. Hand it to hercules and the whole `gz' map goes
;; sticky the moment the first cursor appears -- `gzd' then repeats on a bare
;; `d'. `gz' itself is never rebound, so the vanilla prefix still works.
;;
;; `after!' is load-bearing: `evil-mc-initialize-active-state' isn't in the
;; module's `:commands' list, and `hercules--advise' will `fset' a no-op onto
;; any name that isn't a function yet.
(after! evil-mc
  ;; hercules wants a *symbol* whose value is a keymap, and Doom's `gz'
  ;; bindings already live in a real prefix map. Reuse it instead of restating
  ;; all 17 of them.
  (defvar +mc-cursors-map (lookup-key evil-normal-state-map (kbd "gz"))
    "Doom's `gz' multiple-cursors prefix keymap.")

  ;; `:transient t' routes through `set-transient-map', so keys in the map
  ;; repeat and any other key dismisses the popup and runs normally. It also
  ;; supplies the exit function, hence no `:hide-funs' here.
  (hercules-def
   :show-funs '(evil-mc-initialize-active-state)
   :keymap    '+mc-cursors-map
   :transient t))

;;;;;;;;;;;;;;;;;;;;;
;; VERSION CONTROL ;;
;;;;;;;;;;;;;;;;;;;;;

(use-package! code-review
  :config
  (require 'ghub-legacy)
  (setq code-review-auth-login-marker 'forge))

;;;;;;;;;;;;;;;;;;
;; GLOBAL STUFF ;;
;;;;;;;;;;;;;;;;;;
;;
;; Final configuration that overrides everything else

(setq-hook! '(typescript-mode-hook javascript-mode-hook) +format-with '(lsp eslint prettier))
(add-hook! '(javascript-mode-hook typescript-mode-hook) #'jest-test-mode)

(fset 'yes-or-no-p 'y-or-n-p)
(setq confirm-kill-emacs nil)
(xterm-mouse-mode t)

(evil-global-set-key 'normal (kbd "C-z") 'suspend-frame)
(evil-global-set-key 'insert (kbd "C-z") 'suspend-frame)
(evil-global-set-key 'visual (kbd "C-z") 'suspend-frame)
(general-define-key
 :states '(normal visual motion)
 :keymaps 'override
 "C-w o" #'delete-other-windows)
(general-define-key
 :states '(normal visual motion)
 :keymaps 'override
 "C-w O" #'doom/window-enlargen)
(defun comment-thing ()
  (interactive)
  (if (region-active-p)
      (comment-or-uncomment-region (region-beginning) (region-end))
    (comment-or-uncomment-region (line-beginning-position) (line-end-position))
    (forward-line 1)))
(general-define-key
 :states '(normal visual motion)
 :keymaps 'override
 ";" #'comment-thing)
(global-set-key (kbd "<escape>") 'evil-normal-state)
(defun occur-all-buffers (arg)
  (interactive "sSearch for regex: ")
  (multi-occur-in-matching-buffers ".*" arg))

(global-set-key (kbd "M-s M-o") 'occur-all-buffers)

(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; aliases
(defalias 'css 'custom-theme-visit-theme)
(defalias 'ttl 'toggle-truncate-lines)
(defalias 'rr 'replace-rectangle)
(defalias 'kr 'kill-rectangle)
(defalias 'rs 'replace-string)
(defalias 'rreg 'replace-regexp)
(defalias 'rev 'revert-buffer)
(defalias 'atb 'append-to-buffer)
(defalias 'vd 'vc-diff)
(defalias 'diffbuff 'diff-buffer-with-file)
(defalias 'db 'diff-buffer-with-file)
(defalias 'vtt 'visit-tags-table)
(defalias 'vcrb 'vc-revert-buffer)
(defalias 'msf 'magit-stage-file)
(defalias 'rack 'inf-ruby-console-racksh)
