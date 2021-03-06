;;; feature/version-control/autoload.el

;;;###autoload
(defun +vcs-root ()
  "Get git url root."
  (let ((remote (git-link--select-remote)))
    (if (git-link--remote-host remote)
        (format "https://%s/%s"
                (git-link--remote-host remote)
                (git-link--remote-dir remote))
      (error  "Remote `%s' is unknown or contains an unsupported URL" remote))))

;;;###autoload
(defun +vcs/git-browse ()
  "Open the website for the current version controlled file. Fallback to
repository root."
  (interactive)
  (let ((git-link-open-in-browser t))
    (call-interactively 'git-link)))

;;;###autoload
(defun +vcs/git-browse-issues ()
  "Open the github issues page for current repo."
  (interactive)
  (if-let (root (+vcs-root))
      (browse-url (concat root "/issues"))
    (user-error "No git root found!")))
