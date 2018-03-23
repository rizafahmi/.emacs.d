;;; private/riza/init.el -*- lexical-binding: t; -*-
(message "Open: private/riza/init.el")
;; I've swapped these keys on my keyboard
(setq x-super-keysym 'alt
      x-alt-keysym   'meta

      user-mail-address "rizafahmi@gmail.com"
      user-full-name    "Riza Fahmi")
(pcase (system-name)
  ;; ("triton")
  ((or "proteus" "halimede")
   ;; smaller screen, smaller fonts
   (set! :font "Fira Mono" :size 18)
   (set! :variable-font "Fira Sans" :size 18)
   (set! :unicode-font "DejaVu Sans Mono" :size 18)
   (setq +doom-modeline-height 25))
  ;; ("nereid")
  ;; ("io")
  ;; ("sao")
)
;; An extra measure to prevent the flash of unstyled mode-line while Emacs is
;; booting up (when Doom is byte-compiled).
(setq-default mode-line-format nil)

(map! :nv ";" #'evil-ex)
(add-to-list 'default-frame-alist '(fullscreen . maximized))


(set-frame-font "Fira Code 20" nil t)
(defun term-send-up () (interactive) (term-send-raw-string "\e[A"))
(defun term-send-down () (interactive) (term-send-raw-string "\e[B"))
(defun term-send-right () (interactive) (term-send-raw-string "\e[C"))
(defun term-send-left () (interactive) (term-send-raw-string "\e[D"))

(add-to-list 'auto-mode-alist '("\\.jsx$" . web-mode))
(require 'flycheck)
(add-hook 'after-init-hook #'global-flycheck-mode)
(flycheck-add-mode 'javascript-eslint 'web-mode)

