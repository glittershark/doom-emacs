;;; private/grfn/config.el -*- lexical-binding: t; -*-

(defvar +grfn-dir (file-name-directory load-file-name))
(defvar +grfn-snippets-dir (expand-file-name "snippets/" +grfn-dir))

;;
(when (featurep! :feature evil)
  (load! +bindings)
  (load! +commands))

(load! +private)


;;
;; Global config
;;

(setq +doom-modeline-buffer-file-name-style 'relative-to-project)

;;
;; Modules
;;

(after! smartparens
  ;; Auto-close more conservatively and expand braces on RET
  (let ((unless-list '(sp-point-before-word-p
                       sp-point-after-word-p
                       sp-point-before-same-p)))
    (sp-pair "'"  nil :unless unless-list)
    (sp-pair "\"" nil :unless unless-list))
  (sp-pair "{" nil :post-handlers '(("||\n[i]" "RET") ("| " " "))
           :unless '(sp-point-before-word-p sp-point-before-same-p))
  (sp-pair "(" nil :post-handlers '(("||\n[i]" "RET") ("| " " "))
           :unless '(sp-point-before-word-p sp-point-before-same-p))
  (sp-pair "[" nil :post-handlers '(("| " " "))
           :unless '(sp-point-before-word-p sp-point-before-same-p)))

;; feature/evil
(after! evil-mc
  ;; Make evil-mc resume its cursors when I switch to insert mode
  (add-hook! 'evil-mc-before-cursors-created
    (add-hook 'evil-insert-state-entry-hook #'evil-mc-resume-cursors nil t))
  (add-hook! 'evil-mc-after-cursors-deleted
    (remove-hook 'evil-insert-state-entry-hook #'evil-mc-resume-cursors t)))

;; feature/snippets
(after! yasnippet
  ;; Don't use default snippets, use mine.
  (setq yas-snippet-dirs
        (append (list '+grfn-snippets-dir)
                (delq 'yas-installed-snippets-dir yas-snippet-dirs))))

;; completion/helm
(after! helm
  ;; Hide header lines in helm. I don't like them
  (set-face-attribute 'helm-source-header nil :height 0.1))

(after! company
  (setq company-idle-delay 0.2
        company-minimum-prefix-length 2))

(setq +doom-modeline-height 10)

;; lang/org
;; (after! org-bullets
;;   ;; The standard unicode characters are usually misaligned depending on the
;;   ;; font. This bugs me. Personally, markdown #-marks for headlines are more
;;   ;; elegant, so we use those.
;;   (setq org-bullets-bullet-list '("#")))

;; (defmacro faces! (mode &rest forms)
;;   (let ((hook-name (-> mode symbol-name (concat "-hook"))))
;;     (if-let ((hook-sym (intern-soft hook-name)))
;;         `(add-hook! ,hook-sym
;;            (message "HELLO I AM MACRO TIME")
;;            ,@(->
;;               forms
;;               (seq-partition 2)
;;               (->> (seq-map
;;                     (lambda (pair)
;;                       (let ((face  (car pair))
;;                             (color (cadr pair)))
;;                         `(set-face-foreground ,face ,color)))))))
;;       (warn "Hook name %s (for mode %s) does not exist as symbol!"
;;             (hook-name)
;;             (symbol-name mode)))))

(setq solarized-use-variable-pitch nil
      solarized-scale-org-headlines nil)

(require 'doom-themes)

(after! doom-theme
  (set-face-foreground 'font-lock-doc-face +solarized-s-base1))

(after! solarized-theme
  (set-face-foreground 'font-lock-doc-face +solarized-s-base1))

(after! evil
  (setq evil-shift-width 2))

(after! org
  (setq
   org-directory (expand-file-name "~/notes")
   +org-dir (expand-file-name "~/notes")
   org-default-notes-file (concat org-directory "/inbox.org")
   +org-default-todo-file (concat org-directory "/inbox.org")
   org-agenda-files (list (expand-file-name "~/notes"))
   org-refile-targets '((org-agenda-files :maxlevel . 1))
   org-file-apps `((auto-mode . emacs)
                   (,(rx (or (and "." (optional "x") (optional "htm") (optional "l") buffer-end)
                             (and buffer-start "http" (optional "s") "://")))
                    . "firefox %s")
                   (,(rx ".pdf" buffer-end) . "apvlv %s")
                   (,(rx "." (or "png"
                                 "jpg"
                                 "jpeg"
                                 "gif"
                                 "tif"
                                 "tiff")
                         buffer-end)
                    . "feh %s"))
   org-log-done 'time
   org-archive-location "~/notes/trash::* From %s"
   org-cycle-separator-lines 2
   org-hidden-keywords '(title)
   org-tags-column -130
   org-ellipsis "⤵"
   org-capture-templates
   '(("t" "Todo" entry
      (file+headline +org-default-todo-file "Inbox")
      "* TODO %?\n%i" :prepend t :kill-buffer t)

     ("n" "Notes" entry
      (file+headline +org-default-notes-file "Inbox")
      "* %u %?\n%i" :prepend t :kill-buffer t)))
  (set-face-foreground 'org-block +solarized-s-base00)
  (add-hook! org-mode
    (add-hook! evil-normal-state-entry-hook
      #'org-align-all-tags))
  (setf (alist-get 'file org-link-frame-setup) 'find-file-other-window))

(after! magit
  (setq git-commit-summary-max-length 50))

(comment

 (string-match-p "(?!foo).*" "bar")
 )

(after! ivy
  (setq ivy-re-builders-alist
        '((t . ivy--regex-fuzzy))))

(setq doom-font (font-spec :family "Meslo LGSDZ Nerd Font" :size 14)
      doom-big-font (font-spec :family "Meslo LGSDZ Nerd Font" :size 19)
      doom-variable-pitch-font (font-spec :family "DejaVu Sans")
      doom-unicode-font (font-spec :family "Meslo LG S DZ"))

(add-hook 'before-save-hook 'delete-trailing-whitespace)

(after! paxedit
  (add-hook! emacs-lisp-mode #'paxedit-mode)
  (add-hook! clojure-mode #'paxedit-mode))

(require 'haskell)

(let ((m-symbols
      '(("`mappend`" . "⊕")
        ("<>"        . "⊕"))))
  (dolist (item m-symbols) (add-to-list 'haskell-font-lock-symbols-alist item)))

(setq haskell-font-lock-symbols t)

(add-hook! haskell-mode
  (flycheck-add-next-checker
   'intero
   'haskell-hlint))

(load! org-clubhouse)
(add-hook! org-mode #'org-clubhouse-mode)

(load! slack-snippets)

(after! magit
  (require 'evil-magit)
  (require 'magithub))

(require 'auth-password-store)
(auth-pass-enable)

