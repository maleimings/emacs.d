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
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(global-display-line-numbers-mode t)
 '(package-selected-packages
   '(cape corfu consult git-gutter magit marginalia orderless pi-coding-agent projectile tree-sitter vterm vertico which-key))
 '(tool-bar-mode nil)
 '(tooltip-mode nil))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
