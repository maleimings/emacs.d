;;; init.el — personal Emacs configuration
;;; Sections: packages / UI / completion & search / in-buffer completion /
;;;           LSP / tree-sitter / terminal / project / git / pi agent

;; ==============================
;; Package management
;; ==============================
(require 'package)
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile (require 'use-package))

;; ==============================
;; Default directory
;; ==============================
(add-hook 'after-init-hook (lambda () (cd "/Volumes/SSD/Code")))

;; ==============================
;; UI & general niceties
;; ==============================
(use-package which-key
  :ensure t
  :config
  (which-key-mode +1)
  (setq which-key-idle-delay 0.5))

;; persist minibuffer history & recent files across sessions
(savehist-mode +1)
(recentf-mode +1)
(setq recentf-max-saved-items 200)

;; ==============================
;; Code editing conveniences
;; ==============================
(electric-pair-mode +1)       ; auto-close brackets/quotes
(show-paren-mode +1)          ; highlight matching parens
(setq-default indent-tabs-mode nil)
(global-auto-revert-mode +1)  ; auto-reload files changed on disk (git pulls, etc.)

;; ==============================
;; Whitespace & tabs visualization
;; ==============================
(use-package whitespace
  :ensure nil                ; built-in
  :config
  ;; Show: tab glyph + face, space dots + face, trailing whitespace highlight
  (setq whitespace-style '(face tabs spaces trailing))
  (setq whitespace-display-mappings
        '((space-mark ?\s [?·] [?•])          ; space -> middle dot
          (tab-mark ?\t [?» ?\t] [?\\ ?\t])))   ; tab  -> guillemet
  ;; subtle colors: spaces grey, tabs amber, trailing whitespace red
  (set-face-attribute 'whitespace-space nil :foreground "gray45" :background nil)
  (set-face-attribute 'whitespace-tab nil :foreground "goldenrod" :background nil)
  (set-face-attribute 'whitespace-trailing nil :background "red4")
  (global-whitespace-mode +1))

;; toggle per-buffer with C-c w; strip trailing whitespace before saving
(global-set-key (kbd "C-c w") 'whitespace-mode)
(add-hook 'before-save-hook 'delete-trailing-whitespace)

;; ==============================
;; Completion & search
;; (vertico + orderless + marginalia + consult)
;; ==============================
(use-package vertico
  :ensure t
  :config
  (vertico-mode +1)
  (setq vertico-cycle t))

(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(orderless basic)
        completion-category-overrides '((file (styles basic partial-completion)))))

(use-package marginalia
  :ensure t
  :config
  (marginalia-mode +1))

(use-package consult
  :ensure t
  :bind (("M-s l" . consult-line)    ; search words in current buffer
         ("M-s r" . consult-ripgrep) ; search words across project (rg)
         ("M-s f" . consult-find)    ; search file names across project (fd)
         ("C-x b" . consult-buffer)
         ("M-g i" . consult-imenu)
         ("M-g o" . consult-outline))
  :config
  ;; consult auto-detects fd and rg; preview results as you type
  (consult-customize consult-find :preview-key "M-."))

;; ==============================
;; In-buffer completion (corfu + cape)
;; ==============================
(use-package corfu
  :ensure t
  :config
  (global-corfu-mode +1)
  (setq corfu-auto t
        corfu-cycle t
        corfu-auto-delay 0.15)
  (when (fboundp 'corfu-popupinfo-mode)
    (corfu-popupinfo-mode +1)))

(use-package cape
  :ensure t
  :config
  ;; fallback completions when no language server is active
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  (add-to-list 'completion-at-point-functions #'cape-file))

;; ==============================
;; Language server support (eglot, built-in)
;; ==============================
(use-package eglot
  :ensure nil                    ; built-in since Emacs 29
  :hook ((c-mode c-ts-mode c++-mode c++-ts-mode) . eglot-ensure)
  :config
  (setq eglot-autoshutdown t
        eglot-events-buffer-size 0
        read-process-output-max (* 1024 1024))
  (define-key eglot-mode-map (kbd "C-c a") #'eglot-code-actions)
  (define-key eglot-mode-map (kbd "C-c r") #'eglot-rename)
  (define-key eglot-mode-map (kbd "C-c f") #'eglot-format))

;; ==============================
;; Tree-sitter syntax highlighting
;; ==============================
(when (treesit-available-p)
  (setq treesit-font-lock-level 4)
  ;; NOTE: entries are added in reverse-priority order because
  ;; `add-to-list' prepends. ".c" must come before the ".C"-style
  ;; C++ entry, or case-fold-search would match ".c" as C++.
  (when (treesit-language-available-p 'cpp)
    (add-to-list 'auto-mode-alist '("\\.\\(cc\\|cpp\\|cxx\\|hpp\\|hh\\|C\\)\\'" . c++-ts-mode)))
  (when (treesit-language-available-p 'python)
    (add-to-list 'auto-mode-alist '("\\.py\\'" . python-ts-mode)))
  (when (treesit-language-available-p 'c)
    (add-to-list 'auto-mode-alist '("\\.c\\'" . c-ts-mode))))

;; ==============================
;; Terminal (vterm)
;; ==============================
(use-package vterm
  :ensure t
  :defer t
  :config
  (setq vterm-max-scrollback 100000)
  (setq vterm-kill-buffer-on-exit t))

;; ==============================
;; Project management (projectile)
;; ==============================
(use-package projectile
  :ensure t
  :defer t
  :config
  (projectile-mode +1)
  :bind
  (("C-c p p" . projectile-switch-project)
   ("C-c p f" . projectile-find-file)
   ("C-c p s" . projectile-ripgrep)))

;; ==============================
;; File tree sidebar (treemacs)
;; Shows a files/subdirs sidebar whenever the current directory is inside a
;; git repo (has a .git marker); hides it otherwise.
;; ==============================
(use-package treemacs
  :ensure t
  :defer t
  :config
  (setq treemacs-width 28)
  (treemacs-follow-mode +1)            ; highlight the current file in the tree
  (treemacs-project-follow-mode +1))   ; keep tree synced to the active project

(use-package treemacs-projectile
  :ensure t
  :after (treemacs projectile))

(defvar my/treemacs-auto t
  "When non-nil, auto-show the treemacs sidebar inside git repos.")

(defun my/treemacs-hide ()
  "Hide the treemacs sidebar, if it is visible."
  (when (and my/treemacs-auto
             (fboundp 'treemacs-current-visibility)
             (eq (treemacs-current-visibility) 'visible))
    (delete-window (treemacs-get-local-window))))

(defun my/treemacs-show-root (root)
  "Display treemacs showing project ROOT, avoiding the first-run prompt."
  (require 'treemacs)
  (let* ((ws (treemacs-current-workspace))
         (path (treemacs-canonical-path root)))
    ;; pre-add the project so `treemacs--init' never asks for a root
    (unless (treemacs-is-path path :in-workspace ws)
      (treemacs-do-add-project-to-workspace path nil))
    (pcase (treemacs-current-visibility)
      ('none   (treemacs--init))
      ('exists (treemacs-select-window)))))

(defun my/treemacs-sync ()
  "Show the sidebar when the current directory is inside a git repo, else hide it."
  (when my/treemacs-auto
    (if-let ((root (locate-dominating-file default-directory ".git")))
        (my/treemacs-show-root (file-truename root))
      (my/treemacs-hide))))

(add-hook 'find-file-hook #'my/treemacs-sync)
(add-hook 'dired-mode-hook #'my/treemacs-sync)
(add-hook 'projectile-after-switch-project-hook #'my/treemacs-sync)
(add-hook 'emacs-startup-hook #'my/treemacs-sync)

(defun my/treemacs-toggle-auto ()
  "Toggle automatic show/hide of the sidebar in git repos."
  (interactive)
  (setq my/treemacs-auto (not my/treemacs-auto))
  (message "treemacs auto-sync %s" (if my/treemacs-auto "on" "off"))
  (when my/treemacs-auto (my/treemacs-sync)))

(global-set-key (kbd "C-c t") 'treemacs)                 ; manual toggle
(global-set-key (kbd "C-c T") 'my/treemacs-toggle-auto)  ; auto mode on/off

;; ==============================
;; Git: magit (porcelain) + git-gutter (inline diff)
;; ==============================
(use-package magit
  :ensure t
  :defer t
  :bind
  (("C-c g" . magit-status)))

(use-package git-gutter
  :ensure t
  :demand t  ; load at startup so fringe markers show in all git files
  :config
  (global-git-gutter-mode +1)
  ;; C-x g is taken by magit-status; use the C-c v prefix instead
  :bind (("C-c v n" . git-gutter:next-hunk)
         ("C-c v p" . git-gutter:previous-hunk)
         ("C-c v r" . git-gutter:revert-hunk)))

;; ==============================
;; Pi coding agent
;; ==============================
(use-package pi-coding-agent
  :ensure t
  :config
  (setq pi-coding-agent-extra-args '("--provider" "deepseek" "--model" "deepseek-v4-flash")))

(defun pi-launch ()
  "Launch Pi coding agent in a vterm buffer."
  (interactive)
  (let ((buf (generate-new-buffer-name "*pi*")))
    (vterm buf)
    (with-current-buffer buf
      (goto-char (point-max))
      (process-send-string (get-buffer-process buf) "pi\n"))))

(defun pi-launch-here ()
  "Launch Pi coding agent in vterm, rooted in current project."
  (interactive)
  (let* ((project-dir (when (featurep 'project)
                        (let ((proj (project-current)))
                          (when proj (project-root proj)))))
         (default-directory (or project-dir default-directory))
         (buf (generate-new-buffer-name "*pi*")))
    (vterm buf)
    (with-current-buffer buf
      (goto-char (point-max))
      (process-send-string (get-buffer-process buf) "pi\n"))))

(global-set-key (kbd "C-c p i") 'pi-launch-here)

;; ==============================
;; Pi token usage in the mode line
;; (reads ~/.pi/agent/tokens.json written by the pi "token-usage" extension)
;; ==============================
(defcustom pi-tokens-file (expand-file-name "tokens.json" "~/.pi/agent/")
  "JSON file written by the pi token-usage extension."
  :type 'file
  :group 'pi-coding-agent)

(defvar pi-tokens--string "" "Cached pi token usage string.")
(defvar pi-tokens--timer nil)

(defun pi-tokens--fmt (n)
  "Format token count N compactly (e.g. 1499 -> 1.5k)."
  (cond ((or (null n) (not (numberp n))) "?")
        ((< n 1000) (number-to-string n))
        ((< n 10000) (format "%.1fk" (/ n 1000.0)))
        (t (format "%dk" (/ n 1000)))))

(defun pi-tokens--refresh ()
  "Re-read pi token stats from `pi-tokens-file'."
  (when (file-readable-p pi-tokens-file)
    (condition-case nil
        (let* ((j (json-read-file pi-tokens-file))
               (in (alist-get 'input j))
               (out (alist-get 'output j))
               (cost (alist-get 'cost j))
               (ctx (alist-get 'contextTokens j))
               (win (alist-get 'contextWindow j))
               (pct (alist-get 'percent j))
               (pct-str (if (numberp pct) (format " (%.1f%%)" pct) "")))
          (setq pi-tokens--string
                (format "pi ↑%s ↓%s $%.3f %s/%s%s"
                        (pi-tokens--fmt in) (pi-tokens--fmt out)
                        (or cost 0.0)
                        (pi-tokens--fmt ctx) (pi-tokens--fmt win)
                        pct-str)))
      (error (setq pi-tokens--string "")))))

(define-minor-mode pi-tokens-modeline-mode
  "Show pi token usage in the mode line."
  :global t
  :group 'pi-coding-agent
  (if pi-tokens-modeline-mode
      (progn
        (pi-tokens--refresh)
        (unless pi-tokens--timer
          (setq pi-tokens--timer (run-with-idle-timer 5 t #'pi-tokens--refresh))))
    (when pi-tokens--timer
      (cancel-timer pi-tokens--timer)
      (setq pi-tokens--timer nil))))

(add-to-list 'mode-line-misc-info
             '(:eval (when pi-tokens-modeline-mode pi-tokens--string)))
(add-hook 'vterm-mode-hook #'pi-tokens--refresh)
(pi-tokens-modeline-mode +1)

;; ==============================
;; Agent shell (agent-shell) — Pi as default agent
;; ==============================
(use-package agent-shell
  :ensure t
  :defer t
  :config
  ;; Pi integration uses the pi-acp ACP adapter (npm install -g pi-acp)
  (setq agent-shell-pi-acp-command '("pi-acp"))
  (setq agent-shell-preferred-agent-config 'pi))

(global-set-key (kbd "C-c p a") 'agent-shell-pi-start-agent)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(global-display-line-numbers-mode t)
 '(package-selected-packages
   '(agent-shell cape consult corfu git-gutter magit marginalia orderless
                 pi-coding-agent projectile ripgrep tree-sitter
                 vertico vterm which-key))
 '(tool-bar-mode nil)
 '(tooltip-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(global-set-key (kbd "C-x <up>") 'windmove-up)
(global-set-key (kbd "C-x <down>") 'windmove-down)
(global-set-key (kbd "C-x <left>") 'windmove-left)
(global-set-key (kbd "C-x <right>") 'windmove-right)
