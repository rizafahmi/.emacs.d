;;; lang/emacs-lisp/autoload.el

;;;###autoload
(defun +emacs-lisp/repl ()
  "Open the Emacs Lisp REPL (`ielm')."
  (interactive)
  (pop-to-buffer
   (or (get-buffer "*ielm*")
       (progn (ielm)
              (let ((buf (get-buffer "*ielm*")))
                (bury-buffer buf)
                buf)))))

;;;###autoload
(defun +emacs-lisp-eval (beg end)
  "Evaluate a region and print it to the echo area (if one line long), otherwise
to a pop up buffer."
  (require 'pp)
  (let ((result (eval (read (buffer-substring-no-properties beg end))))
        (buf (get-buffer-create "*eval*"))
        (inhibit-read-only t)
        lines)
    (with-current-buffer buf
      (read-only-mode +1)
      (setq-local scroll-margin 0)
      (emacs-lisp-mode)
      (prin1 result buf)
      (pp-buffer)
      (setq lines (count-lines (point-min) (point-max)))
      (goto-char (point-min))
      (when (<= lines 1)
        (message "%s" (buffer-substring (point-min) (point-max)))
        (kill-buffer buf)))
    (when (> lines 1)
      (doom-popup-buffer buf))))
