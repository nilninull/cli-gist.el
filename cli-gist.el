;;; cli-gist.el --- Listing Github Gist       -*- lexical-binding: t; -*-

;; Copyright (C) 2023  nilninull

;; Author: nilninull <nilninull@gmail.com>
;; Keywords: tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Display Github Gist by `tabulated-list-mode'.

;; This mode uses the github cli command.  If you do not have it,
;; please install it from https://github.com/cli/cli

;; To use, run M-x list-gist.

;;; Code:

(defun cli-gist--refresh ()
  "Update entries by gh gist list command."
  (let (description-length)
    (setq tabulated-list-entries
	  (with-temp-buffer
	    (call-process "gh" nil t nil "gist" "list")
	    (cl-loop for line in (split-string (buffer-string) "\n" t)
		     collect (let ((items (split-string line "\t")))
			       (push (length (cl-second items)) description-length)
			       (list (car items) (apply #'vector items)))))
	  tabulated-list-format (vector '("id" 32 t)
					`("description" ,(min (- (window-body-width) 32 7 6 20)
							      (apply #'max description-length))
					  t)
					'("number of files" 7 t)
					'("scope" 6 t)
					'("time" 20 t))))
  (tabulated-list-init-header))

(defvar cli-gist-list-mode-map (let ((map (make-sparse-keymap)))
				 (set-keymap-parent map tabulated-list-mode-map)
				 (define-key map "W" 'cli-gist-web-view)
				 (define-key map "E" 'cli-gist-edit)
				 (define-key map [return] 'cli-gist-edit)
				 (define-key map "D" 'cli-gist-delete)
				 (define-key map [delete] 'cli-gist-delete)
				 map))

(define-derived-mode cli-gist-list-mode tabulated-list-mode "Gist"
  "Major mode for listing the Github Gist files."
  (add-hook 'tabulated-list-revert-hook 'cli-gist--refresh nil t))

(defun cli-gist-edit ()
  "Edit gist file."
  (interactive)
  (unless server-mode
    (error "Please enable `server-mode'"))
  (dlet ((process-environment (cons "EDITOR=emacsclient" process-environment)))
    (when-let ((id (tabulated-list-get-id))
	       (entry (tabulated-list-get-entry)))
      (let (opts)
	(when-let* (((not (string= "1 file" (aref entry 2))))
		    (ret (shell-command-to-string (concat "gh gist view --files " id)))
		    (files (split-string ret "[[:space:]]" t))
		    (file (completing-read "[Choose file name] " files nil t)))
	  (setq opts `("-f" ,file)))
	(apply #'start-process "gist edit" nil "gh" "gist" "edit" `(,@opts ,id))))))

;; (defun cli-gist-edit-description ()
;;   ""
;;   (interactive)
;;   (when-let ((id (tabulated-list-get-id))
;;	     (entry (tabulated-list-get-entry)))
;;     (let* ((desc (aref entry 1))
;;	   (new (read-string "[Enter description] " desc)))
;;       (unless (string= desc new)
;;	(call-process "gh" nil nil nil "gist" "edit" "-d" new id)
;;	(revert-buffer)))))

(defun cli-gist-delete ()
  "Delete gist file."
  (interactive)
  (when-let ((id (tabulated-list-get-id))
	     ((yes-or-no-p (format "Delete `%s' entry? " id))))
    (call-process "gh" nil nil nil "gist" "delete" id)
    (revert-buffer)))

(defun cli-gist-web-view ()
  "Open gist in web browser."
  (interactive)
  (when-let ((id (tabulated-list-get-id)))
    (call-process "gh" nil nil nil "gist" "view" "-w" id)))

(declare-function dired-get-marked-files "dired")

;;;###autoload
(defun cli-gist-create ()
  "Create new gist.

If the region is activated, create new gist with marked strings.

In Dired mode, creates a new gist with the marked file or the
file under the cursor.

When the buffer has existed file, create new gist with the buffer
file."
  (interactive)
  (when-let (target (cond ((region-active-p)
			   'region)
			  ((eq 'dired-mode major-mode)
			   (dired-get-marked-files))
			  ((and (stringp buffer-file-name)
				(file-exists-p buffer-file-name))
			   (list buffer-file-name))))
    (let (opts)
      (when-let ((desc (read-string "description> "))
		 ((< 0 (length desc))))
	(setq opts (list "-d" desc)))
      (when (y-or-n-p "Public? ")
	(push "-p" opts))
      (if (eq 'region target)
	  (let ((file-name (read-string "file name? ")))
	    (when (< 0 (length file-name))
	      (setq opts `("-f" ,file-name ,@opts)))
	    (apply #'call-process-region (region-beginning) (region-end)
		   "gh" nil nil nil "gist" "create" opts))
	(apply #'call-process "gh" nil nil nil "gist" "create" (append opts target))))))

;;;###autoload
(defun list-gist ()
  "Display github gist."
  (interactive)
  (unless (executable-find "gh")
    (error "Please install `gh' from https://github.com/cli/cli"))
  (with-current-buffer (get-buffer-create "*Gist List*")
    (cli-gist-list-mode)
    (tabulated-list-print)
    (revert-buffer)
    (display-buffer (current-buffer))))

(provide 'cli-gist)
;;; cli-gist.el ends here
