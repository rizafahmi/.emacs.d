;;; bootstrap.el
(eval-when-compile (require 'cl-lib))

;; Global constants
(eval-and-compile
  (defconst emacs-start-time (current-time))
  (defconst emacs-end-time nil)

  (defconst doom-default-theme  'wombat)
  (defconst doom-terminal-theme 'wombat)
  (defconst doom-default-font  nil)

  (defconst doom-emacs-dir     (expand-file-name "." user-emacs-directory))
  (defconst doom-core-dir      (concat doom-emacs-dir "/core"))
  (defconst doom-modules-dir   (concat doom-emacs-dir "/modules"))
  (defconst doom-private-dir   (concat doom-emacs-dir "/private"))
  (defconst doom-packages-dir  (concat doom-emacs-dir "/.cask/" emacs-version "/elpa"))
  (defconst doom-script-dir    (concat doom-emacs-dir "/scripts"))
  (defconst doom-ext-dir       (concat doom-emacs-dir "/ext"))
  (defconst doom-snippet-dirs  (list (concat doom-private-dir "/snippets")
                                     (concat doom-private-dir "/templates")))
  ;; Hostname and emacs version-based elisp temp directories
  (defconst doom-temp-dir      (format "%s/cache/%s/%s.%s"
                                       doom-private-dir (system-name)
                                       emacs-major-version emacs-minor-version))

  (defconst IS-MAC     (eq system-type 'darwin))
  (defconst IS-LINUX   (eq system-type 'gnu/linux))
  (defconst IS-WINDOWS (eq system-type 'windows-nt)))

(eval-when-compile
  (defvar doom--load-path load-path)
  ;; Helper for traversing subdirectories recursively
  (defun --subdirs (path &optional include-self)
    (let ((result (if include-self (list path) (list))))
      (dolist (file (ignore-errors (directory-files path t "^[^.]" t)))
        (when (file-directory-p file)
          (push file result)))
      result)))


;;
;; Bootstrap
;;

;; Shut up byte-compiler!
(defvar doom-current-theme)
(defvar doom-current-font)

(defun doom (packages)
  "Bootstrap DOOM emacs and initialize PACKAGES"
  (setq-default gc-cons-threshold 4388608
                gc-cons-percentage 0.4)
  ;; prematurely optimize for faster startup
  (let ((gc-cons-threshold 339430400)
        (gc-cons-percentage 0.6)
        file-name-handler-alist)
    ;; Scan various folders to populate the load-paths
    (setq load-path
          (eval-when-compile
            (append (list doom-private-dir)
                    (--subdirs doom-core-dir t)
                    (--subdirs doom-modules-dir t)
                    (--subdirs doom-packages-dir)
                    (--subdirs (expand-file-name "../bootstrap" doom-packages-dir))
                    doom--load-path))
          custom-theme-load-path
          (append (list (expand-file-name "themes/" doom-private-dir))
                  custom-theme-load-path))

    (load "~/.emacs.local.el" t t)
    (setq doom-current-theme (if (display-graphic-p) doom-default-theme doom-terminal-theme)
          doom-current-font doom-default-font)
    (mapc 'require packages)
    (when (display-graphic-p)
      (require 'server)
      (unless (server-running-p)
        (server-start)))))

;;; bootstrap.el ends here