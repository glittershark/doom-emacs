;; -*- no-byte-compile: t; -*-
;;; private/grfn/packages.el

;; Editor
(package! solarized-theme)
(package! fill-column-indicator)
(package! flx)
(package! general
  :recipe (general
           :fetcher github
           :repo "noctuid/general.el"))

;; Elisp
(package! dash)
(package! dash-functional)
(package! s)
(package! request)

;; Rust
(package! cargo)

;; Elixir
(package! flycheck-credo)
(package! flycheck-mix)
(package! flycheck-dialyxir)

;; Lisp
(package! paxedit)

