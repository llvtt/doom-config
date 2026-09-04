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
;; (setq doom-theme 'doom-snazzy        )
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
        "s" #'consult-lsp-file-symbols))
(after! (lsp-mode flycheck)
  (map! :map lsp-mode-map
        :leader
        :prefix ("l" . "LSP")
        "el" #'flycheck-list-errors
        "en" #'flycheck-next-error
        "ep" #'flycheck-previous-error))

(remove-hook 'doom-first-input-hook #'evil-snipe-mode)

;;;;;;;;;;;;;;;;;;;;;;;
;; TOOL INTEGRATIONS ;;
;;;;;;;;;;;;;;;;;;;;;;;

;; --- mise ---
(use-package! mise
  :hook (after-init-hook . #'global-mise-mode))
(use-package! mise-tasks
  :config
  (mise-tasks-projectile-mode t)

  ;; ;; `mise-tasks--compile' reuses a single per-project buffer, so starting a
  ;; ;; second task kills the first. Give each task its own buffer, keyed by the
  ;; ;; actual command run, so multiple tasks can run concurrently.
  ;; (defun +mise-tasks-per-task-buffer-name (orig-fn root command)
  ;;   (let ((mise-tasks-buffer-name-function
  ;;          (lambda (root)
  ;;            (format "*mise: %s: %s*"
  ;;                    (file-name-nondirectory (directory-file-name root))
  ;;                    command))))
  ;;     (funcall orig-fn root command)))
  ;; (advice-add 'mise-tasks--compile :around #'+mise-tasks-per-task-buffer-name)

  (map! :leader
        :prefix ("r" . "Run")
        :desc "List tasks" "l" #'mise-tasks-list
        :desc "Run task" "c" #'mise-tasks-run
        :desc "Run last" "r" #'mise-tasks-run-last)

  (evil-define-key '(normal motion) mise-tasks-list-mode-map
    (kbd "RET") #'mise-tasks-list-run-at-point
    "g" #'mise-tasks-list-refresh
    "x" #'mise-tasks-list-kill))

;; --- cmake ---

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
        "cK" #'cmake-integration-cmake-configure-with-preset
        "cr" #'cmake-integration-run-last-target
        "car" #'cmake-integration-run-last-target-with-arguments
        "cg" #'my/cmake-run-google-test-at-point
        "cd" #'cmake-integration-debug-last-target))
(add-hook! '(c-ts-mode-hook c++-ts-mode-hook) #'cmake-integration-project-mode)

;; brew install neocmakelsp
(after! lsp-mode
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection (lambda () (list (or (executable-find "neocmakelsp") "neocmakelsp") "stdio")))
    :activation-fn (lsp-activate-on "cmake")
    :language-id "cmake"
    :priority 1
    :server-id 'neocmakelsp)))
(add-hook! 'cmake-ts-mode-hook #'lsp!)

;; -- terraform --
(add-hook! 'terraform-mode-hook #'terraform-format-on-save-mode)

;; --- device tree ---
(after! '(device-ts-mode treesit)
  (add-to-list 'treesit-language-source-alist
               '(devicetree "https://github.com/joelspadin/tree-sitter-devicetree")))

;; --- shell configuration ---
;; TODO - need to evaluate if ghostel is annoying, or if it's just PEBCAK
;;   - cursor shape is not respected between normal/insert
;;   - normal emacs editing keybindings do not work
;;   - cannot switch windows in insert mode, because they are vim keybindings
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
;; XXX - the following is taken care of with evil-ghostel
;; (after! evil
;; (evil-set-initial-state 'ghostel-mode 'insert))

;; ghostel leaves C-c C-u free. Send it through the terminal's key encoder
;; rather than a raw "\x15" so kitty-keyboard-protocol apps see it too.
(defun my/ghostel-send-C-u ()
  "Send \\`C-u' to the terminal, clearing the current input line."
  (interactive)
  (ghostel-send-key "u" "ctrl"))

(defun my/ghostel-send-change-line ()
  "Emulate changing the line in the terminal vim (`cc'), clearing the
  current input line and entering insert mode."
  (interactive)
  (ghostel-send-key "e" "ctrl")
  (ghostel-send-key "u" "ctrl")
  (evil-insert 1))

(after! ghostel
  ;; :n shadows evil's `c' operator in ghostel buffers (so cw/ciw are gone
  ;; there), which is fine — there is no editable buffer text to change.
  (map! :map ghostel-mode-map
        :i "C-c C-g" #'ghostel-send-C-g
        :g "C-c C-u" #'my/ghostel-send-C-u
        :n "cc" #'my/ghostel-send-C-u))

;; --- git link ---

(use-package! git-link
  :config
  (setq git-link-use-commit t)

  (general-define-key
   :states '(normal visual motion)
   :keymaps 'override
   "<SPC>gh" #'git-link))

;; --- claude code ---

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

;; --- evil cursor changer ---
;; TODO: this does not work in ghostel
(after! evil
  (require 'evil-terminal-cursor-changer)
  ;; It's often hard to see text inside a box, so make most of these 'hbar
  (setq
   evil-motion-state-cursor 'hbar
   evil-visual-state-cursor 'box
   evil-normal-state-cursor 'hbar
   evil-emacs-state-cursor 'hbar
   evil-insert-state-cursor 'bar)
  (etcc-on))

;; --- use symbols-outline instead of imenu ---

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

;; (use-package! rich-minority
;;   :defer nil
;;   :config
;;   (unless rich-minority-mode (rich-minority-mode 1))
;;   (setq rm-whitelist (format "^ \\(%s\\)$"
;;                              (mapconcat #'identity
;;                                         '("Projectile.*" ".*Lsp.*")
;;                                         "\\|"))))

(after! doom-modeline
  (setq doom-modeline-position-column-line-format '("%l行%c列")
        doom-modeline-vcs-max-length 40))

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

;;;;;;;;;;;;;;
;; HERCULES ;;
;;;;;;;;;;;;;;

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

;; --- window management ---

(after! evil
  (defvar +window-resize-map evil-window-map
    "Resize-only subset of `evil-window-map'.")

  (defvar +window-resize-funs
    '(evil-window-increase-height evil-window-decrease-height
      evil-window-increase-width  evil-window-decrease-width
      evil-window-set-height      evil-window-set-width
      doom/window-enlargen        balance-windows)
    "Commands kept in `+window-resize-map'.")

  ;; `:transient t' routes through `set-transient-map', so keys in the map
  ;; repeat and any other key dismisses the popup and runs normally.
  ;;
  ;; `balance-windows' stays in the *map* but out of `:show-funs':
  ;; `evil-auto-balance-windows' calls it behind every split, which would pop
  ;; the resize map open unbidden.
  (hercules-def
   :show-funs      (remq 'balance-windows +window-resize-funs)
   :keymap         '+window-resize-map
   :whitelist-funs +window-resize-funs
   :transient t))

;; --- vc hunks ---

;; Doom already binds `SPC g [' / `SPC g ]' to the hunk motions; all this adds
;; is stickiness, so `SPC g ]]]' walks three hunks forward and `[' reverses
;; without re-entering the prefix.
;;
;; `+vc-gutter-hunk-map' starts life as `doom-leader-git-map' itself, but
;; `:whitelist-funs' `set's the symbol to a freshly built sparse map containing
;; only the whitelisted bindings -- the real leader map is never mutated.
(after! evil
  (defvar +vc-gutter-hunk-map doom-leader-git-map
    "Hunk-motion-only subset of `doom-leader-git-map'.")

  (defvar +vc-gutter-hunk-funs
    '(+vc-gutter/next-hunk +vc-gutter/previous-hunk)
    "Commands kept in `+vc-gutter-hunk-map'.")

  (hercules-def
   :show-funs      +vc-gutter-hunk-funs
   :keymap         '+vc-gutter-hunk-map
   :whitelist-funs +vc-gutter-hunk-funs
   :transient t))

;; --- dape stepping ---

;; Same trick over Doom's `SPC d' debugger prefix: `SPC d n' then bare `n n n'
;; to step, `s'/`o' to dive in and out, `c' to continue.
;;
;; `after! dape' is load-bearing twice over: it keeps `hercules--advise' from
;; `fset'ting a no-op onto a command that isn't loaded yet, and it defers the
;; whitelist rebuild until the session actually starts. `SPC d d' autoloads
;; dape, which runs this before any stepping key can be pressed.
(after! dape
  (defvar +dape-step-map doom-leader-debugger-map
    "Stepping-only subset of `doom-leader-debugger-map'.")

  (defvar +dape-step-funs
    '(dape-next dape-step-in dape-step-out dape-continue dape-pause)
    "Commands kept in `+dape-step-map'.")

  (hercules-def
   :show-funs      +dape-step-funs
   :keymap         '+dape-step-map
   :whitelist-funs +dape-step-funs
   :transient t))

;; --- dape: jest ---

;; None of dape's stock js-debug configs can run a jest test: they all set
;; `:program dape-buffer-default', i.e. hand the *test file itself* to
;; node/ts-node/tsx.  A jest test only makes sense inside jest's runtime
;; (`describe'/`jest.mock' globals, `moduleNameMapper' for the `@/' aliases, the
;; jsdom environment, the SWC transform), so the program has to be jest and the
;; test file has to be an argument.  Two more mismatches for good measure:
;; `js-debug-node' is `modes (js-mode js-ts-mode)' so it isn't even suggested in
;; a `typescript-ts-mode' buffer, and `js-debug-ts-node'/`js-debug-tsx' fail
;; `ensure' because ts-node/tsx live in a project's node_modules/.bin, not on
;; `exec-path'.
;;
;; `:cwd' can't be `dape-cwd' either -- Doom points `dape-cwd-function' at the
;; projectile root, which in a monorepo is the git root, while jest must run
;; from the directory holding jest.config.js.
(after! dape
  (defun +dape-jest-root ()
    "Directory of the nearest jest project, falling back to `dape-cwd'.
Expanded: `default-directory' is often abbreviated to `~/...', which node
would not resolve."
    (expand-file-name
     (or (locate-dominating-file (or (buffer-file-name) default-directory)
                                 "jest.config.js")
         (dape-cwd))))

  (defun +dape-jest-program ()
    "Path to jest's CLI entry point, relative to `+dape-jest-root'."
    "node_modules/jest/bin/jest.js")

  (add-to-list
   'dape-configs
   `(jest
     modes (typescript-ts-mode typescript-mode tsx-ts-mode
                               js-ts-mode js-mode js-jsx-mode)
     ensure ,(lambda (config)
               (dape-ensure-command config)
               (let ((server (car (plist-get config 'command-args))))
                 (unless (file-exists-p server)
                   (user-error "js-debug missing, %S does not exist" server)))
               (let* ((root (+dape-jest-root))
                      (jest (file-name-concat root (+dape-jest-program))))
                 (unless (file-exists-p jest)
                   (user-error "No jest under %S" root))))
     command "node"
     command-args (,(expand-file-name
                     (file-name-concat dape-adapter-dir
                                       "js-debug" "src" "dapDebugServer.js"))
                   :autoport)
     port :autoport
     :type "pwa-node"
     :request "launch"
     :cwd +dape-jest-root
     :program +dape-jest-program
     ;; `--runInBand' keeps the tests in the process js-debug launched; without
     ;; it jest forks workers and breakpoints depend on child auto-attach.
     :args ,(lambda ()
              (vector "--runInBand" "--no-coverage"
                      (if (buffer-file-name)
                          (file-relative-name (buffer-file-name)
                                              (+dape-jest-root))
                        "")))
     ;; jest writes its report straight to stderr, which `outputCapture'
     ;; "console" (the js-debug default) does not forward.
     :console "internalConsole"
     :outputCapture "std"
     :sourceMaps t
     :skipFiles ["<node_internals>/**"])))

;;;;;;;;;;;;;;;;;;;;;
;; VERSION CONTROL ;;
;;;;;;;;;;;;;;;;;;;;;

(use-package! code-review
  :config
  (require 'ghub-legacy)
  (setq code-review-auth-login-marker 'forge)
  (map! :map code-review-mode-map
        :nvm
        "c" #'code-review-comment-add-or-edit))

(use-package! magit
  :config
  (setq git-commit-summary-max-length 100)
  (map! :leader
        :desc "Magit diff" "g d" #'magit-diff))

;;;;;;;;;;;;;;;;;;
;; GLOBAL STUFF ;;
;;;;;;;;;;;;;;;;;;
;;
;; Final configuration that overrides everything else

(setq-hook! '(typescript-mode-hook javascript-mode-hook) +format-with '(lsp eslint prettier))
(add-hook! '(javascript-mode-hook typescript-mode-hook) #'jest-test-mode)
(after! lsp-mode
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection (lambda () (list (or (executable-find "typescript-languge-server") "typescript-languge-server") "--lsp" "--stdio")))
    :activation-fn (lsp-activate-on "typescript" "typescriptreact" "javascript" "javascriptreact")
    :language-id "typescript"
    :priority 1
    :server-id 'typescript-language-server)))

;; `lang/javascript' drops `?\n' from `electric-indent-chars' for TS modes
;; (only `}'/`)' trigger reindent), which silently breaks RET-triggered
;; indentation entirely -- both plain `newline' and
;; `electric-newline-and-maybe-indent' rely on `?\n' being in that list.
;; Restore it while keeping the extra `}'/`)' electric behavior.
(dolist (mode '(typescript-ts-mode tsx-ts-mode typescript-mode))
  (set-electric! mode :chars '(?\n ?\} ?\)) :words '("||" "&&")))

(fset 'yes-or-no-p 'y-or-n-p)
(setq confirm-kill-emacs nil)
(xterm-mouse-mode t)

(setq-default fill-column 100)

(general-define-key
 :keymaps 'doom-leader-buffer-map
 "w" #'consult-buffer-other-window)
(general-define-key
 :keymaps 'doom-leader-file-map
 "w" #'projectile-find-file-other-window)
(general-define-key
 :states '(normal visual motion)
 :keymaps 'override
 "<SPC> w w" #'ace-window)
(general-define-key
 :states '(normal visual motion insert)
 :keymaps 'override
 "C-z" #'suspend-frame)
(general-define-key
 :states '(normal visual motion insert)
 :keymaps 'override
 "<f11>" #'window-toggle-side-windows)
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
