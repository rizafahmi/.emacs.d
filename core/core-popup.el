;;; core-popup.el --- taming stray windows

;; I use a slew of hackery to get Emacs to treat 'pop-up' windows in a sane and "modern"
;; way (whatever that means). It goes through great lengths to tame helm, flycheck, help
;; buffers--*even* the beast that is org-mode.
;;
;; Be warned, an update could break any of this.

(use-package shackle
  :config
  (shackle-mode 1)
  (setq shackle-rules
        `(;; Debuggers
          ("\\`\\*\\(g\\|zsh\\|bash\\)db.*?\\*\\'" :align below :size 20 :regexp t)
          ("\\`\\*trepanjs.*?\\*\\'"               :align below :size 20 :regexp t)
          ("\\`\\*\\(debug:\\)haskell\\*\\'"       :align below :size 20 :regexp t)

          ;; Plugins
          ("\\` ?\\*[hH]elm.*?\\*\\'" :align below :size 20  :select t   :regexp t)
          (" ?\\*Flycheck.+\\*"       :align below :size 15  :noselect t :regexp t)
          ("*helm bookmarks*"         :align below :size 7   :select t)
          (" *NeoTree*"               :align left            :select t)
          ("*evil-registers*"         :align below :size 0.3)
          ("*quickrun*"               :align below :size 10)
          ("*nosetests*"              :align below :size 0.4 :noselect t)
          ("*esup*"                   :align below :size 30  :noselect t)
          ("*ert*"                    :align below :size 20  :noselect t)
          ;; vcs
          ("^\\*git-gutter.+\\*$"     :align below :size 0.4 :noselect t :regexp t)
          ("*vc-diff*"                :align below :size 0.4 :noselect t)
          ("*vc-change-log*"          :align below           :select t)
          (vc-annotate-mode           :same t)
          ;; Util
          ("*Apropos*"                :align below :size 0.3)
          ("*minor-modes*"            :align below :size 0.5 :noselect t)

          ;; Org
          ("^\\*Org Src .+\\*$"       :align below :size 0.4 :select t :regexp t)
          ("^\\*Org-Babel.*\\*$"      :align below :size 0.4 :regexp t)
          ("^\\*Org Agenda.+"         :align below :size 0.4 :regexp t)
          ("*Calendar*"               :align below :size 0.4)
          (" *Agenda Commands*"       :align below :size 30)
          (" *Org todo*"              :align below :size 5   :noselect t)
          ("*Org Links*"              :align below :size 5)

          ;; Emacs
          ("^\\*.+-Profiler-Report .+\\*$" :align below :size 0.3 :regexp t)
          ("*processing-compilation*"  :align below :size 10   :noselect t)
          ("*Backtrace*"               :align below :size 0.25 :noselect t)
          (,doom-buffer-name           :align below :size 0.3  :select t)
          ("*Help*"                    :align below :size 16   :select t)
          ("*Messages*"                :align below :size 15   :select t)
          ("*Warnings*"                :align below :size 10   :noselect t)
          ("*Completions*"             :align below :size 20   :noselect t)
          (debugger-mode               :align below :size 0.25 :noselect t)
          (compilation-mode                                    :noselect t)

          ;; Custom + REPLs
          ("*eval*" :align below :size 12)
          ("^\\*doom.+\\*$" :regexp t :align below :size 12 :noselect t)
          ((:custom (lambda (b &rest _)
                      (when (featurep 'repl-toggle)
                        (when (string-prefix-p "*" (buffer-name (get-buffer b)))
                          (with-current-buffer b repl-p)))))
           :popup t :align below :size 16)))

  (defvar doom-popup-windows '()
    "A list of windows that have been opened via shackle. Do not touch this!")
  (defvar-local doom-popup-protect nil
    "If non-nil, this popup buffer won't be killed when closed.")
  (defvar doom-last-popup nil
    "The last (important) popup buffer.")

  (defvar doom-popup-escapable-modes
    '(messages-buffer-mode esup-mode help-mode tabulated-list-mode)
    "A list of modes that can be closed with a single ESC.")
  (defvar doom-popup-protect-modes
    '(messages-buffer-mode esup-mode help-mode tabulated-list-mode comint-mode)
    "A list of modes that shouldn't be killed and can be revived.")

  ;; There is no shackle-popup hook, so I hacked one in
  (defvar doom-popup-hook '() "Hook run whenever a popup is opened.")
  (advice-add 'shackle-display-buffer :after 'doom|run-popup-hooks)
  (add-hook 'doom-popup-hook 'doom|popup-init)     ; Keep track of popups
  (add-hook 'doom-popup-hook 'doom|hide-mode-line) ; No mode line in popups

  ;; Prevents popups from messaging with windows-moving functions
  (defun doom*save-popups (orig-fun &rest args)
    (doom/popup-save (apply orig-fun args)))
  (advice-add 'doom/evil-window-move :around 'doom*save-popups))


;;
;; Hacks
;;

(after! help-mode
  ;; So that help buffer links do not open in the help popup, we need to redefine these
  ;; three button types to use `switch-to-buffer' rather than `pop-to-buffer'.
  ;; Instead of lambas these help-functions should be function symbols, so that
  ;; we could advise those instead of clumsify redefine these button types.
  (define-button-type 'help-function-def
    :supertype 'help-xref
    'help-function (lambda (fun file)
                     (require 'find-func)
                     (when (eq file 'C-source)
                       (setq file (help-C-file-name (indirect-function fun) 'fun)))
                     (let ((location
                            (find-function-search-for-symbol fun nil file)))
                       (doom/popup-save
                        (switch-to-buffer (car location)))
                       (if (cdr location)
                           (goto-char (cdr location))
                         (message "Unable to find location in file"))))
    'help-echo (purecopy "mouse-2, RET: find function's definition"))

  (define-button-type 'help-variable-def
    :supertype 'help-xref
    'help-function (lambda (var &optional file)
                     (when (eq file 'C-source)
                       (setq file (help-C-file-name var 'var)))
                     (let ((location (find-variable-noselect var file)))
                       (doom/popup-save
                        (switch-to-buffer (car location)))
                       (if (cdr location)
                           (goto-char (cdr location))
                         (message "Unable to find location in file"))))
    'help-echo (purecopy "mouse-2, RET: find variable's definition"))

  (define-button-type 'help-face-def
    :supertype 'help-xref
    'help-function (lambda (fun file)
                     (require 'find-func)
                     (let ((location
                            (find-function-search-for-symbol fun 'defface file)))
                       (doom/popup-save
                        (switch-to-buffer (car location)))
                       (if (cdr location)
                           (goto-char (cdr location))
                         (message "Unable to find location in file"))))
    'help-echo (purecopy "mouse-2, RET: find face's definition")))

(after! helm
  ;; This is a good alternative to either popwin or shackle, specifically for helm. If
  ;; either fail me (for the last time), this is where I'll turn.
  ;;(add-to-list 'display-buffer-alist
  ;;             `(,(rx bos "*helm" (* not-newline) "*" eos)
  ;;               (display-buffer-in-side-window)
  ;;               (inhibit-same-window . t)
  ;;               (window-height . 0.4)))

  ;; Helm tries to clean up after itself, but shackle has already done this. This fixes
  ;; that. To reproduce, add a helm rule in `shackle-rules', open two splits
  ;; side-by-side, move to the buffer on the right and invoke helm. It will close all
  ;; but the left-most buffer.
  (setq-default helm-reuse-last-window-split-state t
                helm-split-window-in-side-p t))

(after! helm-swoop
  (setq helm-swoop-split-window-function (lambda ($buf) (doom/popup-buffer $buf))))

(after! helm-ag
  ;; Helm-ag needs a little coaxing for it to cooperate with shackle. Mostly to prevent
  ;; it from switching between windows and buffers.
  (defadvice helm-ag--edit-abort (around helm-ag-edit-abort-popup-compat activate)
    (cl-letf (((symbol-function 'select-window) 'ignore)) ad-do-it)
    (doom/popup-close nil t t))
  (defadvice helm-ag--edit-commit (around helm-ag-edit-commit-popup-compat activate)
    (cl-letf (((symbol-function 'select-window) 'ignore)) ad-do-it)
    (doom/popup-close nil t t))
  (defadvice helm-ag--edit (around helm-ag-edit-popup-compat activate)
    (cl-letf (((symbol-function 'other-window) 'ignore)
              ((symbol-function 'switch-to-buffer) 'doom/popup-buffer))
      ad-do-it)))

(after! quickrun
  ;; This allows us to run code several times in a row without having to close the popup
  ;; window and move back to the code buffer.
  (defun doom*quickrun-close-popup (&optional _ _ _ _)
    (let* ((buffer (get-buffer quickrun/buffer-name))
           (window (and buffer (get-buffer-window buffer))))
      (when buffer
        (shut-up! (quickrun/kill-running-process))
        (doom/popup-close window nil t))))
  (advice-add 'quickrun :before 'doom*quickrun-close-popup)
  (advice-add 'quickrun-region :before 'doom*quickrun-close-popup)

  ;; Turns on `nlinum-mode', and ensures window is scrolled to EOF
  (defun doom|quickrun-after-run ()
    (let ((window (get-buffer-window quickrun/buffer-name)))
      (with-selected-window window
        (goto-char (point-min)))))
  (add-hook 'quickrun-after-run-hook 'doom|quickrun-after-run)
  (add-hook 'quickrun/mode-hook 'doom|hide-mode-line))

(add-hook! org-load
  ;; This ensures org-src-edit yields control of its buffer to shackle.
  (defun org-src-switch-to-buffer (buffer context)
    (pop-to-buffer buffer))

  ;; And these for org-todo, org-link and agenda
  (defun org-pop-to-buffer-same-window (&optional buffer-or-name norecord label)
    "Pop to buffer specified by BUFFER-OR-NAME in the selected window."
    (display-buffer buffer-or-name))

  (defun org-switch-to-buffer-other-window (&rest args)
    (mapc (lambda (b)
            (let ((buf (if (stringp b) (get-buffer-create b) b)))
              (pop-to-buffer buf t t)))
          args))

  ;; Taming Org-agenda!
  (defun doom/org-agenda-quit ()
    "Necessary to finagle org-agenda into shackle popups and behave properly on quit."
    (interactive)
    (if org-agenda-columns-active
        (org-columns-quit)
      (let ((buf (current-buffer)))
        (and (not (eq org-agenda-window-setup 'current-window))
             (not (one-window-p))
             (delete-window))
        (kill-buffer buf)
        (setq org-agenda-archives-mode nil
              org-agenda-buffer nil))))

  (map! :map org-agenda-mode-map
        :e "<escape>" 'doom/org-agenda-quit
        :e "ESC" 'doom/org-agenda-quit
        :e [escape] 'doom/org-agenda-quit
        "q" 'doom/org-agenda-quit
        "Q" 'doom/org-agenda-quit))

(after! realgud
  ;; This allows realgud debuggers to run in a popup.
  ;; TODO Find a more elegant advice-based solution
  ;; FIXME Causes realgud:cmd-* to focus popup on every invocation
  (defun realgud:run-process(debugger-name script-filename cmd-args minibuffer-history &optional no-reset)
    (let ((cmd-buf))
      (setq cmd-buf
            (apply 'realgud-exec-shell debugger-name script-filename
                   (car cmd-args) no-reset (cdr cmd-args)))
      (let ((process (get-buffer-process cmd-buf)))
        (if (and process (eq 'run (process-status process)))
            (progn
              (pop-to-buffer cmd-buf)
              (define-key evil-emacs-state-local-map (kbd "ESC ESC") 'doom/debug-quit)
              (realgud:track-set-debugger debugger-name)
              (realgud-cmdbuf-info-in-debugger?= 't)
              (realgud-cmdbuf-info-cmd-args= cmd-args)
              (when cmd-buf
                (switch-to-buffer cmd-buf)
                (when realgud-cmdbuf-info
                  (let* ((info realgud-cmdbuf-info)
                         (cmd-args (realgud-cmdbuf-info-cmd-args info))
                         (cmd-str  (mapconcat 'identity  cmd-args " ")))
                    (set minibuffer-history
                         (list-utils-uniq (cons cmd-str (eval minibuffer-history))))))))
          ;; else
          (progn
            (if cmd-buf (switch-to-buffer cmd-buf))
            (message "Error running command: %s" (mapconcat 'identity cmd-args " ")))))
      cmd-buf)))

(provide 'core-popup)
;;; core-popup.el ends here