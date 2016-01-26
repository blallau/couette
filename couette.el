;;; pycoverage.el --- Support for coverage stats on Python 2.X  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  bertrand

;; Author: bertrand LALLAU <bertrand.lallau@gmail.com>
;; URL: https://github.com/blallau/couette
;; Package-Version: 20160104
;; Keywords: project, convenience
;; Version: 0.0.2

(defconst couette-mode-text " couette(I)")
;; Need to figure out how to use these without errors
(defconst couette-cov2emacs-cmd "cov2emacs")
(defvar-local couette-binary-installed nil)
(defvar-local couette-debug-message t)

(make-variable-buffer-local 'couette-data)

;;;###autoload
(define-minor-mode couette-mode
  "Allow annotating the file with coverage information"
  :lighter couette-mode-text
  (if couette-mode
      (progn
         (add-hook 'after-save-hook 'couette-on-change)
         (setq couette-binary-installed (couette-exe-found couette-cov2emacs-cmd))
         (if (not couette-binary-installed)
             (error "Missing cov2emacs in PATH")
           )
	 (linum-mode t)
         (setf linum-format 'couette-line-format)
	 (couette-on-change))
    (setf linum-format 'dynamic)
    (remove-hook 'after-save-hook 'couette-on-change)
    (linum-delete-overlays)))

(defun couette-exe-found (path)
  ;; spliting and taking last item in order to support something like this:
  ;; "PYTHONPATH=cov2emacs
  (couette-message (format "Looking for %s" path))
  (executable-find path))

(defun couette-message (txt)
  (if couette-debug-message
      (message txt)))

(defun couette-on-change ()
  (progn
    (couette-message "Running couette")
    (couette-get-data (buffer-file-name))))

(defun couette-get-data (filename)
  (let* ((result (couette-launch-pycov filename))
         (lines (split-string result "[\n]+")))
    (setq couette-data nil)
    (if result
        (progn
          ;; take status from first line
          (couette-process-status (car lines))
          (mapcar (lambda (line)
                    (if (not (equal line ""))
                        (couette-process-script-line line)))
                  (cdr lines))))))

(defun couette-process-status (line)
  ;; status like looks like this: SUCCESS:23
  ;; where 23 is percent of coverage
  (let* ((data (split-string line ":"))
         (stat (first data)))
    (cond
     ((string= stat "SUCCESS")
      (progn
        ;; update mode-line
        (setq couette-mode-text (format " couette:%s%%" (second data)))
        (force-mode-line-update)))
     ((string= stat "FILE_TOO_OLD")
      (progn
        ;; update mode-line
        (setq couette-mode-text " couette(.coverage file too old)")
        (force-mode-line-update)))
     ((string= stat "NO_FILE")
      (progn
        ;; update mode-line
        (setq couette-mode-text " couette(no .coverage file)")
        (force-mode-line-update))))))

(defun couette-process-script-line (line)
  ;; line looks like this filepath:103:MISSING
  (let* ((data (split-string line ":"))
         (path (first data))
         (number (string-to-number (second data)))
         (status (third data)))
    (when (equal status "MISSING")
      ;; add linenum to couette-data
      (add-to-list 'couette-data number))))

(defun couette-line-format (linenum)
  (cond
   ((member linenum couette-data)
    (propertize " " 'face '(:background "red" :foreground "red")))
   (couette-data
    ;; covered data
    (propertize " " 'face '(:background " " :foreground " ")))))

(defun couette-launch-pycov (filename)
  (let* ((command (format "%s --python-file %s" couette-cov2emacs-cmd filename)))
    (message command)
    (shell-command-to-string command)))

(provide 'couette)

;;; couette.el ends here
