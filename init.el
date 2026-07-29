(require 'package)
(add-to-list 'package-archives '("gnu" . "https://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(eval-when-compile (require 'use-package))

(use-package vterm
  :ensure t
  :defer t
  :config
  (setq vterm-max-scrollback 100000)
  (setq vterm-kill-buffer-on-exit t))

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
