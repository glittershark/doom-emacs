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

;; Lisp utils
(package! dash)

;; Rust
(package! cargo)

;; Elixir
(package! flycheck-credo)
(package! flycheck-mix)
(package! flycheck-dialyxir)

;; Lisp
(package! paxedit)

