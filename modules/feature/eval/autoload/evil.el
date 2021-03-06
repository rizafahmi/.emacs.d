;;; feature/eval/autoload/evil.el

;;;###autoload (autoload '+eval:region "feature/eval/autoload/evil" nil t)
(evil-define-operator +eval:region (beg end)
  "Send region to the currently open repl, if available."
  :move-point nil
  (interactive "<r>")
  (+eval/region beg end))

;;;###autoload (autoload '+eval:replace-region "feature/eval/autoload/evil" nil t)
(evil-define-operator +eval:replace-region (beg end)
  :move-point nil
  (interactive "<r>")
  (+eval/region-and-replace beg end))
