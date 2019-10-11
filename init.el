(require 'package)
(add-to-list 'package-archives
         '("melpa" . "http://melpa.org/packages/") t)

(package-initialize)

(when (not package-archive-contents)
    (package-refresh-contents))

(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

(add-to-list 'load-path "~/.emacs.d/custom")

(require 'setup-general)
(if (version< emacs-version "24.4")
    (require 'setup-ivy-counsel)
  (require 'setup-helm)
  (require 'setup-helm-gtags))
;; (require 'setup-ggtags)
(require 'setup-cedet)
(require 'setup-editing)

(when (string= system-type "darwin")
  (setq dired-use-ls-dired nil))

;; function-args
;; (require 'function-args)
;; (fa-config-default)
;; (define-key c-mode-map  [(tab)] 'company-complete)
;; (define-key c++-mode-map  [(tab)] 'company-complete)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   (quote
    (zygospore helm-gtags helm yasnippet ws-butler volatile-highlights use-package undo-tree iedit dtrt-indent counsel-projectile company clean-aindent-mode anzu))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


(defvar current-user
  (getenv
   (if (equal system-type 'windows-nt) "USERNAME" "USER")))

(message "Prelude is powering up... Be patient, Master %s!" current-user)

(when (version< emacs-version "25.1")
  (error "Prelude requires GNU Emacs 25.1 or newer, but you're running %s" emacs-version))

;; Always load newest byte code
(setq load-prefer-newer t)

(defvar prelude-dir (file-name-directory load-file-name)
  "The root dir of the Emacs Prelude distribution.")
(defvar prelude-core-dir (expand-file-name "core" prelude-dir)
  "The home of Prelude's core functionality.")
(defvar prelude-modules-dir (expand-file-name  "modules" prelude-dir)
  "This directory houses all of the built-in Prelude modules.")
(defvar prelude-personal-dir (expand-file-name "personal" prelude-dir)
  "This directory is for your personal configuration.

Users of Emacs Prelude are encouraged to keep their personal configuration
changes in this directory.  All Emacs Lisp files there are loaded automatically
by Prelude.")
(defvar prelude-personal-preload-dir (expand-file-name "preload" prelude-personal-dir)
  "This directory is for your personal configuration, that you want loaded before Prelude.")
(defvar prelude-vendor-dir (expand-file-name "vendor" prelude-dir)
  "This directory houses packages that are not yet available in ELPA (or MELPA).")
(defvar prelude-savefile-dir (expand-file-name "savefile" prelude-dir)
  "This folder stores all the automatically generated save/history-files.")
(defvar prelude-modules-file (expand-file-name "prelude-modules.el" prelude-personal-dir)
  "This file contains a list of modules that will be loaded by Prelude.")
(defvar prelude-deprecated-modules-file
  (expand-file-name "prelude-modules.el" prelude-dir)
  (format "This file may contain a list of Prelude modules.

This is DEPRECATED, use %s instead." prelude-modules-file))

(unless (file-exists-p prelude-savefile-dir)
  (make-directory prelude-savefile-dir))

(defun prelude-add-subfolders-to-load-path (parent-dir)
 "Add all level PARENT-DIR subdirs to the `load-path'."
 (dolist (f (directory-files parent-dir))
   (let ((name (expand-file-name f parent-dir)))
     (when (and (file-directory-p name)
                (not (string-prefix-p "." f)))
       (add-to-list 'load-path name)
       (prelude-add-subfolders-to-load-path name)))))

;; add Prelude's directories to Emacs's `load-path'
(add-to-list 'load-path prelude-core-dir)
(add-to-list 'load-path prelude-modules-dir)
(add-to-list 'load-path prelude-vendor-dir)
(prelude-add-subfolders-to-load-path prelude-vendor-dir)

;; reduce the frequency of garbage collection by making it happen on
;; each 50MB of allocated data (the default is on every 0.76MB)
(setq gc-cons-threshold 50000000)

;; warn when opening files bigger than 100MB
(setq large-file-warning-threshold 100000000)

;; preload the personal settings from `prelude-personal-preload-dir'
(when (file-exists-p prelude-personal-preload-dir)
  (message "Loading personal configuration files in %s..." prelude-personal-preload-dir)
  (mapc 'load (directory-files prelude-personal-preload-dir 't "^[^#\.].*el$")))

(message "Loading Prelude's core...")

;; the core stuff
(require 'prelude-packages)
(require 'prelude-custom)  ;; Needs to be loaded before core, editor and ui
(require 'prelude-ui)
(require 'prelude-core)
(require 'prelude-mode)
(require 'prelude-editor)
(require 'prelude-global-keybindings)

;; macOS specific settings
(when (eq system-type 'darwin)
  (require 'prelude-macos))

;; Linux specific settings
(when (eq system-type 'gnu/linux)
  (require 'prelude-linux))

(message "Loading Prelude's modules...")

;; the modules
(if (file-exists-p prelude-modules-file)
    (progn
      (load prelude-modules-file)
      (if (file-exists-p prelude-deprecated-modules-file)
          (message "Loading new modules configuration, ignoring DEPRECATED prelude-module.el")))
  (if (file-exists-p prelude-deprecated-modules-file)
      (progn
        (load prelude-deprecated-modules-file)
        (message (format "The use of %s is DEPRECATED! Use %s instead!"
                         prelude-deprecated-modules-file
                         prelude-modules-file)))
    (message "Missing modules file %s" prelude-modules-file)
    (message "You can get started by copying the bundled example file from sample/prelude-modules.el")))

;; config changes made through the customize UI will be stored here
(setq custom-file (expand-file-name "custom.el" prelude-personal-dir))

;; load the personal settings (this includes `custom-file')
(when (file-exists-p prelude-personal-dir)
  (message "Loading personal configuration files in %s..." prelude-personal-dir)
  (mapc 'load (delete
               prelude-modules-file
               (directory-files prelude-personal-dir 't "^[^#\.].*\\.el$"))))

(message "Prelude is ready to do thy bidding, Master %s!" current-user)

;; Patch security vulnerability in Emacs versions older than 25.3
(when (version< emacs-version "25.3")
  (with-eval-after-load "enriched"
    (defun enriched-decode-display-prop (start end &optional param)
      (list start end))))

(prelude-eval-after-init
 ;; greet the use with some useful tip
 (run-at-time 5 nil 'prelude-tip-of-the-day))

;;; init.el ends here
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes/")
(load-theme 'ample-zen t)

(defun fira-code-mode--make-alist (list)
  "Generate prettify-symbols alist from LIST."
  (let ((idx -1))
    (mapcar
     (lambda (s)
       (setq idx (1+ idx))
       (let* ((code (+ #Xe100 idx))
              (width (string-width s))
              (prefix ())
              (suffix '(?\s (Br . Br)))
              (n 1))
         (while (< n width)
           (setq prefix (append prefix '(?\s (Br . Bl))))
           (setq n (1+ n)))
         (cons s (append prefix suffix (list (decode-char 'ucs code))))))
     list)))

(defconst fira-code-mode--ligatures
  '("www" "**" "***" "**/" "*>" "*/" "\\\\" "\\\\\\"
    "{-" "[]" "::" ":::" ":=" "!!" "!=" "!==" "-}"
    "--" "---" "-->" "->" "->>" "-<" "-<<" "-~"
    "#{" "#[" "##" "###" "####" "#(" "#?" "#_" "#_("
    ".-" ".=" ".." "..<" "..." "?=" "??" ";;" "/*"
    "/**" "/=" "/==" "/>" "//" "///" "&&" "||" "||="
    "|=" "|>" "^=" "$>" "++" "+++" "+>" "=:=" "=="
    "===" "==>" "=>" "=>>" "<=" "=<<" "=/=" ">-" ">="
    ">=>" ">>" ">>-" ">>=" ">>>" "<*" "<*>" "<|" "<|>"
    "<$" "<$>" "<!--" "<-" "<--" "<->" "<+" "<+>" "<="
    "<==" "<=>" "<=<" "<>" "<<" "<<-" "<<=" "<<<" "<~"
    "<~~" "</" "</>" "~@" "~-" "~=" "~>" "~~" "~~>" "%%"
    "x" ":" "+" "+" "*"))

(defvar fira-code-mode--old-prettify-alist)

(defun fira-code-mode--enable ()
  "Enable Fira Code ligatures in current buffer."
  (setq-local fira-code-mode--old-prettify-alist prettify-symbols-alist)
  (setq-local prettify-symbols-alist (append (fira-code-mode--make-alist fira-code-mode--ligatures) fira-code-mode--old-prettify-alist))
  (prettify-symbols-mode t))

(defun fira-code-mode--disable ()
  "Disable Fira Code ligatures in current buffer."
  (setq-local prettify-symbols-alist fira-code-mode--old-prettify-alist)
  (prettify-symbols-mode -1))

(define-minor-mode fira-code-mode
  "Fira Code ligatures minor mode"
  :lighter " Fira Code"
  (setq-local prettify-symbols-unprettify-at-point 'right-edge)
  (if fira-code-mode
      (fira-code-mode--enable)
    (fira-code-mode--disable)))

(defun fira-code-mode--setup ()
  "Setup Fira Code Symbols"
  (set-fontset-font t '(#Xe100 . #Xe16f) "Fira Code Symbol"))

(provide 'fira-code-mode)

(add-to-list 'default-frame-alist '(font . "DejaVu Sans Mono-10"))

; Company Mode
(require 'req-package)

(req-package company
             :config
             (progn
               (add-hook 'after-init-hook 'global-company-mode)
               (global-set-key (kbd "M-/") 'company-complete-common-or-cycle)
               (setq company-idle-delay 0)))

(global-flycheck-mode)

(req-package flycheck
             :config
             (progn
               (global-flycheck-mode)))

(req-package irony
             :config
             (progn
               ;; If irony server was never installed, install it.
               (unless (irony--find-server-executable) (call-interactively #'irony-install-server))

               (add-hook 'c++-mode-hook 'irony-mode)
               (add-hook 'c-mode-hook 'irony-mode)

               ;; Use compilation database first, clang_complete as fallback.
               (setq-default irony-cdb-compilation-databases '(irony-cdb-libclang
                                                               irony-cdb-clang-complete))

               (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
               ))

;; I use irony with company to get code completion.
(req-package company-irony
             :require company irony
             :config
             (progn
               (eval-after-load 'company '(add-to-list 'company-backends 'company-irony))))

;; I use irony with flycheck to get real-time syntax checking.
(req-package flycheck-irony
             :require flycheck irony
             :config
             (progn
               (eval-after-load 'flycheck '(add-hook 'flycheck-mode-hook #'flycheck-irony-setup))))

;; Eldoc shows argument list of the function you are currently writing in the echo area.
(req-package irony-eldoc
             :require eldoc irony
             :config
             (progn
               (add-hook 'irony-mode-hook #'irony-eldoc)))

(req-package irony
             :config
             (progn
               ;; If irony server was never installed, install it.
               (unless (irony--find-server-executable) (call-interactively #'irony-install-server))

               (add-hook 'c++-mode-hook 'irony-mode)
               (add-hook 'c-mode-hook 'irony-mode)

               ;; Use compilation database first, clang_complete as fallback.
               (setq-default irony-cdb-compilation-databases '(irony-cdb-libclang
                                                               irony-cdb-clang-complete))

               (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
               ))

;; I use irony with company to get code completion.
(req-package company-irony
             :require company irony
             :config
             (progn
               (eval-after-load 'company '(add-to-list 'company-backends 'company-irony))))

;; I use irony with flycheck to get real-time syntax checking.
(req-package flycheck-irony
             :require flycheck irony
             :config
             (progn
               (eval-after-load 'flycheck '(add-hook 'flycheck-mode-hook #'flycheck-irony-setup))))

;; Eldoc shows argument list of the function you are currently writing in the echo area.
(req-package irony-eldoc
             :require eldoc irony
             :config
             (progn
               (add-hook 'irony-mode-hook #'irony-eldoc)))
;; (req-package rtags
;;              :config
;;              (progn
;;                (unless (rtags-executable-find "rc") (error "Binary rc is not installed!"))
;;                (unless (rtags-executable-find "rdm") (error "Binary rdm is not installed!"))

;;                (define-key c-mode-base-map (kbd "M-.") 'rtags-find-symbol-at-point)
;;                (define-key c-mode-base-map (kbd "M-,") 'rtags-find-references-at-point)
;;                (define-key c-mode-base-map (kbd "M-?") 'rtags-display-summary)
;;                (rtags-enable-standard-keybindings)

;;                (setq rtags-use-helm t)

;;                ;; Shutdown rdm when leaving emacs.
;;                (add-hook 'kill-emacs-hook 'rtags-quit-rdm)
;;                ))

;; ;; TODO: Has no coloring! How can I get coloring?
;; (req-package helm-rtags
;;              :require helm rtags
;;              :config
;;              (progn
;;                (setq rtags-display-result-backend 'helm)
;;                ))

;; ;; Use rtags for auto-completion.
;; (req-package company-rtags
;;              :require company rtags
;;              :config
;;              (progn
;;                (setq rtags-autostart-diagnostics t)
;;                (rtags-diagnostics)
;;                (setq rtags-completions-enabled t)
;;                (push 'company-rtags company-backends)
;;                ))

;; ;; Live code checking.
;; (req-package flycheck-rtags
;;              :require flycheck rtags
;;              :config
;;              (progn
;;                ;; ensure that we use only rtags checking
;;                ;; https://github.com/Andersbakken/rtags#optional-1
;;                (defun setup-flycheck-rtags ()
;;                  (flycheck-select-checker 'rtags)
;;                  (setq-local flycheck-highlighting-mode nil) ;; RTags creates more accurate overlays.
;;                  (setq-local flycheck-check-syntax-automatically nil)
;;                  (rtags-set-periodic-reparse-timeout 2.0)  ;; Run flycheck 2 seconds after being idle.
;;                  )
;;                (add-hook 'c-mode-hook #'setup-flycheck-rtags)
;;                (add-hook 'c++-mode-hook #'setup-flycheck-rtags)
                   ;; ))

(req-package projectile
  :config
  (progn
    (projectile-global-mode)
        ))

;; (require 'company)
;; (add-hook 'after-init-hook 'global-company-mode)
;; (setq company-backends (delete 'company-semantic company-backends))
;; (define-key c-mode-map  [(tab)] 'company-complete)
;; (define-key c++-mode-map  [(tab)] 'company-complete)

;; ; C/C++ Irony / Flycheck

;; (add-hook 'c++-mode-hook 'irony-mode)
;; (add-hook 'c-mode-hook 'irony-mode)
;; (add-hook 'objc-mode-hook 'irony-mode)

;; (add-hook 'irony-mode-hook 'irony-cdb-autosetup-compile-options)
;; (eval-after-load 'flycheck
;;   '(add-hook 'flycheck-mode-hook #'flycheck-irony-setup))

(when (version <= "26.0.50" emacs-version)
  (global-display-line-numbers-mode))
(global-set-key (kbd "C-\\") 'set-mark-command)
(global-set-key (kbd "<f5>") (lambda ()
                               (interactive)
                               (setq-local compilation-read-command nil)
                               (call-interactively 'compile)))

(require 'multiple-cursors)
(global-set-key (kbd "M-s m") 'mc/edit-lines)

(set-frame-parameter (selected-frame) 'alpha '(91 . 85))
(add-to-list 'default-frame-alist '(alpha . (91 . 85)))

(require 'redo+)
(global-set-key (kbd "C-x C-_") 'redo)

(require 'dtrt-indent)
(dtrt-indent-mode 1)
(setq dtrt-indent-verbosity 0)

(custom-set-variables '(c-basic-offset 2))
(setq-default indent-tabs-mode nil)

;; ## added by OPAM user-setup for emacs / base ## 56ab50dc8996d2bb95e7856a6eddb17b ## you can edit, but keep this line
(require 'opam-user-setup "~/.emacs.d/opam-user-setup.el")
;; ## end of OPAM user-setup addition for emacs / base ## keep this line

(push "/Users/kinetc/.opam/4.02.3/share/emacs/site-lisp" load-path)
(autoload 'merlin-mode "merlin" "Merlin mode" t)
(add-hook 'tuareg-mode-hook 'merlin-mode)
(add-hook 'caml-mode-hook 'merlin-mode)

(setq-default truncate-lines 1)

(add-hook 'prog-mode-hook 'electric-pair-mode)
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)
(global-set-key (kbd "C-v") 'View-scroll-half-page-forward)
(global-set-key (kbd "M-v") 'View-scroll-half-page-backward)

(use-package dired-sidebar
  :bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
  :ensure t
  :commands (dired-sidebar-toggle-sidebar)
  :init
  (add-hook 'dired-sidebar-mode-hook
            (lambda ()
              (unless (file-remote-p default-directory)
                (auto-revert-mode))))
  :config
  (push 'toggle-window-split dired-sidebar-toggle-hidden-commands)
  (push 'rotate-windows dired-sidebar-toggle-hidden-commands)

  (setq dired-sidebar-subtree-line-prefix "__")
  (setq dired-sidebar-theme 'vscode)
  (setq dired-sidebar-use-term-integration t)
  (setq dired-sidebar-use-custom-font t))

(add-hook 'prog-mode-hook 'highlight-indent-guides-mode)
(setq highlight-indent-guides-method 'character)

;; use only one desktop
(setq desktop-path '("~/.emacs.d/"))
(setq desktop-dirname "~/.emacs.d/")
(setq desktop-base-file-name "emacs-desktop")

;; remove desktop after it's been read
(add-hook 'desktop-after-read-hook
	  '(lambda ()
	     ;; desktop-remove clears desktop-dirname
	     (setq desktop-dirname-tmp desktop-dirname)
	     (desktop-remove)
	     (setq desktop-dirname desktop-dirname-tmp)))

(defun saved-session ()
  (file-exists-p (concat desktop-dirname "/" desktop-base-file-name)))

;; use session-restore to restore the desktop manually
(defun session-restore ()
  "Restore a saved emacs session."
  (interactive)
  (if (saved-session)
      (desktop-read)
    (message "No desktop found.")))

;; use session-save to save the desktop manually
(defun session-save ()
  "Save an emacs session."
  (interactive)
  (if (saved-session)
      (if (y-or-n-p "Overwrite existing desktop? ")
	  (desktop-save-in-desktop-dir)
	(message "Session not saved."))
  (desktop-save-in-desktop-dir)))

;; ask user whether to restore desktop at start-up
(add-hook 'after-init-hook
	  '(lambda ()
	     (if (saved-session)
		 (if (y-or-n-p "Restore desktop? ")
		     (session-restore)))))
