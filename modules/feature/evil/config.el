;;; feature/evil/config.el -*- lexical-binding: t; -*-

;; I'm a vimmer at heart. Its modal philosophy suits me better, and this module
;; strives to make Emacs a much better vim than vim was.

(def-setting! :evil-state (modes state)
  "Set the initialize STATE of MODE using `evil-set-initial-state'."
  (let ((unquoted-modes (doom-unquote modes)))
    (if (listp unquoted-modes)
        `(progn
           ,@(cl-loop for mode in unquoted-modes
                      collect `(evil-set-initial-state ',mode ,state)))
      `(evil-set-initial-state ,modes ,state))))


;;
;; evil-mode
;;

(autoload 'goto-last-change "goto-chg")
(autoload 'goto-last-change-reverse "goto-chg")

(def-package! evil
  :init
  (setq evil-want-C-u-scroll t
        evil-want-visual-char-semi-exclusive t
        evil-want-Y-yank-to-eol t
        evil-magic t
        evil-echo-state t
        evil-indent-convert-tabs t
        evil-ex-search-vim-style-regexp t
        evil-ex-substitute-global t
        evil-ex-visual-char-range t  ; column range for ex commands
        evil-insert-skip-empty-lines t
        evil-mode-line-format 'nil
        evil-respect-visual-line-mode t
        ;; more vim-like behavior
        evil-symbol-word-search t
        ;; don't activate mark on shift-click
        shift-select-mode nil)

  :config
  (add-hook 'doom-init-hook #'evil-mode)
  (evil-select-search-module 'evil-search-module 'evil-search)

  (set! :popup "^\\*evil-registers" '((size . 0.3)))
  (set! :popup "^\\*Command Line" '((size . 8)))

  ;; Set cursor colors later, once theme is loaded
  (defun +evil*init-cursors (&rest _)
    (setq evil-default-cursor (face-background 'cursor nil t)
          evil-normal-state-cursor 'box
          evil-emacs-state-cursor  `(,(face-foreground 'warning) box)
          evil-insert-state-cursor 'bar
          evil-visual-state-cursor 'hollow))
  (advice-add #'load-theme :after #'+evil*init-cursors)

  ;; default modes
  (dolist (mode '(tabulated-list-mode view-mode comint-mode term-mode calendar-mode Man-mode grep-mode))
    (evil-set-initial-state mode 'emacs))
  (dolist (mode '(help-mode debugger-mode))
    (evil-set-initial-state mode 'normal))


  ;; --- keybind fixes ----------------------
  (map! (:after wgrep
          ;; A wrapper that invokes `wgrep-mark-deletion' across lines you use
          ;; `evil-delete' in wgrep buffers.
          :map wgrep-mode-map [remap evil-delete] #'+evil-delete)

        ;; replace native folding commands
        [remap evil-toggle-fold]   #'+evil:fold-toggle
        [remap evil-close-fold]    #'+evil:fold-close
        [remap evil-open-fold]     #'+evil:fold-open
        [remap evil-open-fold-rec] #'+evil:fold-open
        [remap evil-close-folds]   #'+evil:fold-close-all
        [remap evil-open-folds]    #'+evil:fold-open-all)

  (defun +evil|disable-highlights ()
    "Disable ex search buffer highlights."
    (when (evil-ex-hl-active-p 'evil-ex-search)
      (evil-ex-nohighlight)
      t))
  (add-hook 'doom-escape-hook #'+evil|disable-highlights)


  ;; --- evil hacks -------------------------
  ;; Make ESC (from normal mode) the universal escaper. See `doom-escape-hook'.
  (advice-add #'evil-force-normal-state :after #'doom/escape)
  ;; Ensure buffer is in normal mode when we leave it and return to it.
  (advice-add #'windmove-do-window-select :around #'+evil*restore-normal-state-on-windmove)
  ;; Don't move cursor when indenting
  (advice-add #'evil-indent :around #'+evil*static-reindent)
  ;; monkey patch `evil-ex-replace-special-filenames' to add more ex
  ;; substitution flags to evil-mode
  (advice-add #'evil-ex-replace-special-filenames :override #'+evil*resolve-vim-path)

  ;; make `try-expand-dabbrev' from `hippie-expand' work in minibuffer
  ;; @see `he-dabbrev-beg', so we need re-define syntax for '/'
  (defun +evil*fix-dabbrev-in-minibuffer ()
    (set-syntax-table (let* ((table (make-syntax-table)))
                        (modify-syntax-entry ?/ "." table)
                        table)))
  (add-hook 'minibuffer-inactive-mode-hook #'+evil*fix-dabbrev-in-minibuffer)

  ;; Move to new split -- setting `evil-split-window-below' &
  ;; `evil-vsplit-window-right' to non-nil mimics this, but that doesn't update
  ;; window history. That means when you delete a new split, Emacs leaves you on
  ;; the 2nd to last window on the history stack, which is jarring.
  ;;
  ;; Also recenters window on cursor in new split
  (defun +evil*window-follow (&rest _)  (evil-window-down 1) (recenter))
  (advice-add #'evil-window-split  :after #'+evil*window-follow)
  (defun +evil*window-vfollow (&rest _) (evil-window-right 1) (recenter))
  (advice-add #'evil-window-vsplit :after #'+evil*window-vfollow)

  ;; These arg types will highlight matches in the current buffer
  (evil-ex-define-argument-type buffer-match :runner +evil-ex-buffer-match)
  (evil-ex-define-argument-type global-match :runner +evil-ex-global-match)
  ;; By default :g[lobal] doesn't highlight matches in the current buffer. I've
  ;; got to write my own argument type and interactive code to get it to do so.
  (evil-ex-define-argument-type global-delim-match :runner +evil-ex-global-delim-match)

  (dolist (sym '(evil-ex-global evil-ex-global-inverted))
    (evil-set-command-property sym :ex-arg 'global-delim-match))

  ;; Other commands can make use of this
  (evil-define-interactive-code "<//>"
    :ex-arg buffer-match (list (when (evil-ex-p) evil-ex-argument)))
  (evil-define-interactive-code "<//g>"
    :ex-arg global-match (list (when (evil-ex-p) evil-ex-argument)))

  ;; Forward declare these so that ex completion works, even if the autoloaded
  ;; functions aren't loaded yet.
  (evil-set-command-properties
   '+evil:align :move-point t :ex-arg 'buffer-match :ex-bang t :evil-mc t :keep-visual t :suppress-operator t)
  (evil-set-command-properties
   '+evil:mc :move-point nil :ex-arg 'global-match :ex-bang t :evil-mc t))


;;
;; Plugins
;;

(def-package! evil-commentary
  :commands (evil-commentary evil-commentary-yank evil-commentary-line)
  :config (evil-commentary-mode 1))


(def-package! evil-easymotion
  :after evil-snipe
  :commands evilem-create)


(def-package! evil-embrace
  :after evil-surround
  :config
  (setq evil-embrace-show-help-p nil)
  (evil-embrace-enable-evil-surround-integration)

  (defun +evil--embrace-get-pair (char)
    (if-let* ((pair (cdr-safe (assoc (string-to-char char) evil-surround-pairs-alist))))
        pair
      (if-let* ((pair (assoc-default char embrace--pairs-list)))
          (if-let* ((real-pair (and (functionp (embrace-pair-struct-read-function pair))
                                    (funcall (embrace-pair-struct-read-function pair)))))
              real-pair
            (cons (embrace-pair-struct-left pair) (embrace-pair-struct-right pair)))
        (cons char char))))

  (defun +evil--embrace-escaped ()
    "Backslash-escaped surround character support for embrace."
    (let ((char (read-char "\\")))
      (if (eq char 27)
          (cons "" "")
        (let ((pair (+evil--embrace-get-pair (string char)))
              (text (if (sp-point-in-string) "\\\\%s" "\\%s")))
          (cons (format text (car pair))
                (format text (cdr pair)))))))

  (defun +evil--embrace-latex ()
    "LaTeX command support for embrace."
    (cons (format "\\%s{" (read-string "\\")) "}"))

  (defun +evil--embrace-elisp-fn ()
    "Elisp function support for embrace."
    (cons (format "(%s " (or (read-string "(") "")) ")"))

  ;; Add escaped-sequence support to embrace
  (push (cons ?\\ (make-embrace-pair-struct
                   :key ?\\
                   :read-function #'+evil--embrace-escaped
                   :left-regexp "\\[[{(]"
                   :right-regexp "\\[]})]"))
        (default-value 'embrace--pairs-list))

  ;; Add extra pairs
  (add-hook 'LaTeX-mode-hook #'embrace-LaTeX-mode-hook)
  (add-hook 'org-mode-hook   #'embrace-org-mode-hook)
  (add-hook! emacs-lisp-mode
    (embrace-add-pair ?\` "`" "'"))
  (add-hook! (emacs-lisp-mode lisp-mode)
    (embrace-add-pair-regexp ?f "([^ ]+ " ")" #'+evil--embrace-elisp-fn))
  (add-hook! (org-mode LaTeX-mode)
    (embrace-add-pair-regexp ?l "\\[a-z]+{" "}" #'+evil--embrace-latex)))


(def-package! evil-escape
  :commands evil-escape-mode
  :init
  (setq evil-escape-excluded-states '(normal visual multiedit emacs motion)
        evil-escape-excluded-major-modes '(neotree-mode)
        evil-escape-key-sequence "jk"
        evil-escape-delay 0.25)
  (add-hook 'doom-post-init-hook #'evil-escape-mode)
  :config
  ;; no `evil-escape' in minibuffer
  (push #'minibufferp evil-escape-inhibit-functions)
  (map! :irvo "C-g" #'evil-escape))


(def-package! evil-exchange
  :commands evil-exchange
  :config
  (defun +evil|escape-exchange ()
    (when evil-exchange--overlays
      (evil-exchange-cancel)
      t))
  (add-hook 'doom-escape-hook #'+evil|escape-exchange))


(def-package! evil-matchit
  :commands (evilmi-jump-items evilmi-text-object global-evil-matchit-mode)
  :config (global-evil-matchit-mode 1)
  :init
  (map! [remap evil-jump-item] #'evilmi-jump-items
        :textobj "%" #'evilmi-text-object #'evilmi-text-object)
  :config
  (defun +evil|simple-matchit ()
    "A hook to force evil-matchit to favor simple bracket jumping. Helpful when
the new algorithm is confusing, like in python or ruby."
    (setq-local evilmi-always-simple-jump t))
  (add-hook 'python-mode-hook #'+evil|simple-matchit))


(def-package! evil-multiedit
  :commands (evil-multiedit-match-all
             evil-multiedit-match-and-next
             evil-multiedit-match-and-prev
             evil-multiedit-match-symbol-and-next
             evil-multiedit-match-symbol-and-prev
             evil-multiedit-toggle-or-restrict-region
             evil-multiedit-next
             evil-multiedit-prev
             evil-multiedit-abort
             evil-multiedit-ex-match))


(def-package! evil-mc
  :commands (evil-mc-make-cursor-here evil-mc-make-all-cursors
             evil-mc-undo-all-cursors evil-mc-pause-cursors
             evil-mc-resume-cursors evil-mc-make-and-goto-first-cursor
             evil-mc-make-and-goto-last-cursor
             evil-mc-make-cursor-move-next-line
             evil-mc-make-cursor-move-prev-line evil-mc-make-cursor-at-pos
             evil-mc-has-cursors-p evil-mc-make-and-goto-next-cursor
             evil-mc-skip-and-goto-next-cursor evil-mc-make-and-goto-prev-cursor
             evil-mc-skip-and-goto-prev-cursor evil-mc-make-and-goto-next-match
             evil-mc-skip-and-goto-next-match evil-mc-skip-and-goto-next-match
             evil-mc-make-and-goto-prev-match evil-mc-skip-and-goto-prev-match)
  :init
  (defvar evil-mc-key-map (make-sparse-keymap))
  :config
  (global-evil-mc-mode +1)

  ;; Add custom commands to whitelisted commands
  (dolist (fn '(doom/deflate-space-maybe doom/inflate-space-maybe
                doom/backward-to-bol-or-indent doom/forward-to-last-non-comment-or-eol
                doom/backward-kill-to-bol-and-indent doom/newline-and-indent))
    (push (cons fn '((:default . evil-mc-execute-default-call)))
          evil-mc-custom-known-commands))

  ;; disable evil-escape in evil-mc; causes unwanted text on invocation
  (push 'evil-escape-mode evil-mc-incompatible-minor-modes)

  (defun +evil|escape-multiple-cursors ()
    "Clear evil-mc cursors and restore state."
    (when (evil-mc-has-cursors-p)
      (evil-mc-undo-all-cursors)
      (evil-mc-resume-cursors)
      t))
  (add-hook 'doom-escape-hook #'+evil|escape-multiple-cursors))


(def-package! evil-snipe
  :commands (evil-snipe-mode evil-snipe-override-mode
             evil-snipe-local-mode evil-snipe-override-local-mode)
  :init
  (setq evil-snipe-smart-case t
        evil-snipe-scope 'line
        evil-snipe-repeat-scope 'visible
        evil-snipe-char-fold t
        evil-snipe-disabled-modes '(magit-mode elfeed-show-mode elfeed-search-mode)
        evil-snipe-aliases '((?\[ "[[{(]")
                             (?\] "[]})]")
                             (?\; "[;:]")))
  ;(add-hook 'doom-post-init-hook #'evil-snipe-mode)
  ;(add-hook 'doom-post-init-hook #'evil-snipe-override-mode)
  )


(def-package! evil-surround
  :commands (global-evil-surround-mode
             evil-surround-edit
             evil-Surround-edit
             evil-surround-region)
  :config (global-evil-surround-mode 1))


(def-package! evil-vimish-fold
  :commands evil-vimish-fold-mode
  :init
  (setq vimish-fold-dir (concat doom-cache-dir "vimish-fold/")
        vimish-fold-indication-mode 'right-fringe)
  (add-hook 'doom-post-init-hook #'evil-vimish-fold-mode t))


;; Without `evil-visualstar', * and # grab the word at point and search, no
;; matter what mode you're in. I want to be able to visually select a region and
;; search for other occurrences of it.
(def-package! evil-visualstar
  :commands (global-evil-visualstar-mode
             evil-visualstar/begin-search
             evil-visualstar/begin-search-forward
             evil-visualstar/begin-search-backward)
  :init
  (map! :v "*" #'evil-visualstar/begin-search-forward
        :v "#" #'evil-visualstar/begin-search-backward)
  :config
  (global-evil-visualstar-mode 1))


;;
;; Text object plugins
;;

(def-package! evil-args
  :commands (evil-inner-arg evil-outer-arg
             evil-forward-arg evil-backward-arg
             evil-jump-out-args))


(def-package! evil-indent-plus
  :commands (evil-indent-plus-i-indent
             evil-indent-plus-a-indent
             evil-indent-plus-i-indent-up
             evil-indent-plus-a-indent-up
             evil-indent-plus-i-indent-up-down
             evil-indent-plus-a-indent-up-down))


(def-package! evil-textobj-anyblock
  :commands (evil-textobj-anyblock-inner-block evil-textobj-anyblock-a-block))


;;
;; Multiple cursors compatibility (for the plugins that use it)
;;

;; mc doesn't play well with evil, this attempts to assuage some of its problems
;; so that any plugins that depend on multiple-cursors (which I have no control
;; over) can still use it in relative safety.
(after! multiple-cursors-core
  (map! :map mc/keymap :ne "<escape>" #'mc/keyboard-quit)

  (defvar +evil--mc-compat-evil-prev-state nil)
  (defvar +evil--mc-compat-mark-was-active nil)

  (defsubst +evil--visual-or-normal-p ()
    "True if evil mode is enabled, and we are in normal or visual mode."
    (and (bound-and-true-p evil-mode)
         (not (memq evil-state '(insert emacs)))))

  (defun +evil|mc-compat-switch-to-emacs-state ()
    (when (+evil--visual-or-normal-p)
      (setq +evil--mc-compat-evil-prev-state evil-state)
      (when (region-active-p)
        (setq +evil--mc-compat-mark-was-active t))
      (let ((mark-before (mark))
            (point-before (point)))
        (evil-emacs-state 1)
        (when (or +evil--mc-compat-mark-was-active (region-active-p))
          (goto-char point-before)
          (set-mark mark-before)))))

  (defun +evil|mc-compat-back-to-previous-state ()
    (when +evil--mc-compat-evil-prev-state
      (unwind-protect
          (case +evil--mc-compat-evil-prev-state
            ((normal visual) (evil-force-normal-state))
            (t (message "Don't know how to handle previous state: %S"
                        +evil--mc-compat-evil-prev-state)))
        (setq +evil--mc-compat-evil-prev-state nil)
        (setq +evil--mc-compat-mark-was-active nil))))

  (add-hook 'multiple-cursors-mode-enabled-hook '+evil|mc-compat-switch-to-emacs-state)
  (add-hook 'multiple-cursors-mode-disabled-hook '+evil|mc-compat-back-to-previous-state)

  (defun +evil|mc-evil-compat-rect-switch-state ()
    (if rectangular-region-mode
        (+evil|mc-compat-switch-to-emacs-state)
      (setq +evil--mc-compat-evil-prev-state nil)))

  ;; When running edit-lines, point will return (position + 1) as a
  ;; result of how evil deals with regions
  (defadvice mc/edit-lines (before change-point-by-1 activate)
    (when (+evil--visual-or-normal-p)
      (if (> (point) (mark))
          (goto-char (1- (point)))
        (push-mark (1- (mark))))))

  (add-hook 'rectangular-region-mode-hook '+evil|mc-evil-compat-rect-switch-state)

  (defvar mc--default-cmds-to-run-once nil))
