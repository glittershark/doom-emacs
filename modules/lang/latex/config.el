;;; lang/latex/config.el -*- lexical-binding: t; -*-

(defvar +latex-bibtex-dir "~/work/writing/biblio/"
  "Where bibtex files are kept.")

(defvar +latex-bibtex-default-file "default.bib"
  "TODO")


;;
;; AucTex/LaTeX bootstrap
;;

;; Because tex-mode is built-in and AucTex has conflicting components, we need
;; to ensure that auctex gets loaded instead of tex-mode.
(load "auctex" nil t)
(load "auctex-autoloads" nil t)
(push '("\\.[tT]e[xX]\\'" . TeX-latex-mode) auto-mode-alist)

(add-hook! (latex-mode LaTeX-mode) #'turn-on-auto-fill)
(add-hook! 'LaTeX-mode-hook #'(LaTeX-math-mode TeX-source-correlate-mode))

(add-transient-hook! 'LaTeX-mode-hook
  (setq TeX-auto-save t
        TeX-parse-self t
        TeX-save-query nil
        TeX-source-correlate-start-server nil
        LaTeX-fill-break-at-separators nil
        LaTeX-section-hook
        '(LaTeX-section-heading
          LaTeX-section-title
          LaTeX-section-toc
          LaTeX-section-section
          LaTeX-section-label))

  (set! :popup " output\\*$" '((size . 15)))
  (map! :map LaTeX-mode-map "C-j" nil))


;;
;; Plugins
;;

(def-package! reftex ; built-in
  :commands (turn-on-reftex reftex-mode)
  :init
  (setq reftex-plug-into-AUCTeX t
        reftex-default-bibliography (list +latex-bibtex-default-file)
        reftex-toc-split-windows-fraction 0.2)

  (add-hook! (latex-mode LaTeX-mode) #'turn-on-reftex)

  :config
  (map! :map reftex-mode-map
        :localleader :n ";" 'reftex-toc)

  (add-hook! 'reftex-toc-mode-hook
    (reftex-toc-rescan)
    (map! :local
          :e "j"   #'next-line
          :e "k"   #'previous-line
          :e "q"   #'kill-buffer-and-window
          :e "ESC" #'kill-buffer-and-window)))


(def-package! bibtex ; built-in
  :defer t
  :config
  (setq bibtex-dialect 'biblatex
        bibtex-align-at-equal-sign t
        bibtex-text-indentation 20
        bibtex-completion-bibliography (list +latex-bibtex-default-file))

  (map! :map bibtex-mode-map "C-c \\" #'bibtex-fill-entry))


(def-package! ivy-bibtex
  :when (featurep! :completion ivy)
  :commands ivy-bibtex)


(def-package! helm-bibtex
  :when (featurep! :completion helm)
  :commands helm-bibtex)


(def-package! company-auctex
  :when (featurep! :completion company)
  :commands company-auctex-init
  :init
  ;; We can't use the (set! :company-backend ...) because Auctex reports its
  ;; major-mode as `latex-mode', but uses LaTeX-mode-hook for its mode, which is
  ;; :company-backend doesn't anticipate (and shouldn't have to!)
  (add-hook! LaTeX-mode
    (make-variable-buffer-local 'company-backends)
    (company-auctex-init)))
