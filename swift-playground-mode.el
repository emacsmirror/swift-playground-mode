;;; swift-playground-mode.el --- Run Apple's playgrounds in Swift buffers -*- lexical-binding: t -*-
;;
;; Copyright 2018 Michael Sanders
;;
;; Authors: Michael Sanders <michael.sanders@fastmail.com>
;; URL: https://gitlab.com/msanders/swift-playground-mode
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.4"))
;; Keywords: languages swift
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Description:
;;
;; Run Apple's playgrounds in Swift buffers.
;;
;; License:
;;
;; This program is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 3 of the License, or (at your option) any later
;; version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along with
;; this program. If not, see <http://www.gnu.org/licenses/>.
;;

;;; Code:

(declare-function pkg-info-version-info "pkg-info" (package))

(defgroup swift-playground nil
  "A Swift playground Emacs client."
  :link '(url-link :tag "GitLab"
                   "https://gitlab.com/michael.sanders/swift-playground-mode")
  :group 'tools
  :group 'programming)

(defvar swift-playground-buffer nil
  "Stores the name of the current swift playground buffer, or nil.")

;;; Keymap

(defvar swift-playground-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map prog-mode-map)
    (easy-menu-define swift-playground-menu map "Swift Mode menu"
      `("Swift Playground"
        :help "Swift playground specific features"
        ["Run playground" swift-playground-run
         :help "Run Swift Playground"]))
    map)
  "Swift playground mode key map.")

(defun swift-playground--populate-playground-buffer (doc &optional keep-default)
  "Populate a new playground buffer with the given contents from DOC.
If KEEP-DEFAULT is not set, `swift-playground-buffer' is updated
to the new buffer."
  (let* ((original-buffer (current-buffer))
         (buffer-name (or swift-playground-buffer "*Playground*"))
         (buffer (get-buffer-create buffer-name)))
    (display-buffer-in-side-window buffer '((side . right)))
    (with-current-buffer buffer
      (unless (comint-check-proc buffer-name)
        (save-excursion
          (read-only-mode 0)
          (erase-buffer)
          (insert doc)
          (read-only-mode t)))
      (setq-local swift-playground-buffer buffer-name))
    (with-current-buffer original-buffer
      (setq-local swift-playground-buffer buffer-name)
      (unless keep-default
        (setq-default swift-playground-buffer
                      swift-playground-buffer)))))

;;;###autoload
(defun swift-playground-close-buffer ()
    "Closes the current playground buffer if it is being displayed."
  (when swift-playground-buffer
    (delete-windows-on swift-playground-buffer)
    (kill-buffer swift-playground-buffer)
    (setq swift-playground-buffer nil)))

;; The next two function are taken from swift-mode-repl.el
;; https://github.com/swift-emacs/swift-mode
(defun swift-playground--call-process (executable &rest args)
  "Call EXECUTABLE synchronously in separate process.
EXECUTABLE may be a string or a list. The string is splitted by
spaces, then unquoted. ARGS are rest arguments, appended to the
argument list. Returns the exit status."
  (swift-playground--do-call-process executable nil t nil args))

(defun swift-playground--do-call-process (executable infile destination display args)
  "Wrapper for `call-process'.
EXECUTABLE may be a string or a list. The string is splitted by
spaces, then unquoted. For INFILE, DESTINATION, DISPLAY, see
`call-process'. ARGS are rest arguments, appended to the argument
list. Returns the exit status."
  (let ((command-list
         (append (swift-playground--command-string-to-list executable) args)))
    (apply 'call-process
           (append
            (list (car command-list))
            (list infile destination display)
            (cdr command-list)))))

(defun swift-playground--call-process-with-output (executable &rest args)
  "Call EXECUTABLE synchronously in separate process.
EXECUTABLE may be a string or a list. The string is splitted by
spaces, then unquoted. ARGS are rest arguments, appended to the
argument list. Returns the exit status."
  (with-temp-buffer
    (unless (zerop
             (apply 'swift-mode:call-process executable args))
      (error "%s: %s" "Cannot invoke executable" (buffer-string)))
    (buffer-string)))

(defun swift-playground--command-string-to-list (cmd)
  "Split the CMD unless it is a list.
This function respects quotes."
  (if (listp cmd) cmd (split-string-and-unquote cmd)))

(defconst swift-playground--script-directory
  (if load-file-name (file-name-directory load-file-name))
  "Directory which contains swift-playground-mode.el.")

;;;###autoload
(defun swift-playground-current-buffer-is-playground ()
  "Return true if the current swift buffer is a playground."
  (and (buffer-file-name)
       (string-suffix-p "playground/Contents.swift" (buffer-file-name))))

;;;###autoload
(defun swift-playground-run ()
  "Run the current swift buffer as a playground."
  (interactive)
  (let* ((result (swift-playground--call-process-with-output
                  "bash"
                  (expand-file-name "runner.sh"
                                    swift-playground--script-directory)
                  (buffer-file-name)))
         (lines (split-string result "[\n\r]+"))
         ;; Track the line values, for they may be recorded multiple times by
         ;; the runtime.
         (set-lines (make-hash-table :test 'equal))
         (line-num 0)
         (doc ""))
    (dolist (line lines)
      (unless (gethash line set-lines)
        ;; Logs come in looking like [1:__range__] $builtin_log LogMessage.
        (let ((split-value (split-string line "\\$builtin_log ")))
          (unless (< (length split-value) 2)
            (let* ((target-str (car (split-string
                                     (cadr (split-string line "\\["))
                                     ":")))
                   (target (string-to-number target-str)))
              (while (< line-num (- target 1))
                (setq doc (concat doc "\n"))
                (setq line-num (+ 1 line-num)))

              (let ((line-value (nth 1 split-value)))
                (puthash line 1 set-lines)
                (setq doc (concat doc line-value "\n"))
                (setq line-num (+ 1 line-num)))
              )))))
    (swift-playground--populate-playground-buffer doc)))

;;;###autoload
(define-minor-mode swift-playground-mode
  "Minor mode for editing/running Swift playgrounds.

  \\{swift-playground-mode-map}

When called interactively, toggle `swift-playground-mode'. With
prefix ARG, enable `swift-playground-mode' if ARG is positive,
otherwise disable it.

When called from Lisp, enable `swift-playground-mode' if ARG is
omitted, nil or positive. If ARG is `toggle', toggle
`swift-playground-mode'. Otherwise behave as if called
interactively."
  :init-value nil
  :group 'swift-playground
  :lighter "Playground"
  (if swift-playground-mode
      (add-hook 'after-save-hook #'swift-playground--run-hook)
    (remove-hook 'after-save-hook #'swift-playground--run-hook))
  (swift-playground--run-hook))

(defun swift-playground--run-hook ()
  "A hook to run the Swift playground as needed.
If variable `swift-playground-mode' is enabled, runs the current
playground, otherwise closes it."
  (if swift-playground-mode
      (swift-playground-run)
    (swift-playground-close-buffer)))

(defun swift-playground-toggle-if-needed ()
  "Setup to be run after Swift mode hook."
  (when (swift-playground-current-buffer-is-playground)
    (swift-playground-mode)))

(defun swift-playground-setup ()
  "Initialize Swift playground mode hooks."
  (add-hook 'swift-mode-hook #'swift-playground-toggle-if-needed))

(provide 'swift-playground-mode)

;;; swift-playground-mode.el ends here
