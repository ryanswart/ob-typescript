;;; ob-typescript.el --- org-babel functions for typescript evaluation

;; Copyright (C) 2015 KURASHIKI Satoru - 2018 Ryan Swart

;; Author: KURASHIKI Satoru
;; Keywords: literate programming, reproducible research, typescript
;; Package-Version: 20150804.1230
;; Homepage: https://github.com/lurdan/ob-typescript
;; Version: 0.1
;; Package-Requires: ((emacs "24") (org "8.0"))

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; Exec typescript in org-babel code blocks.

;;; Requirements:
;; You need to install node.js, ts-node and typescript to use this extension.

;;; Code:
(require 'ob)
;;(require 'ob-ref)
;;(require 'ob-comint)
;;(require 'ob-eval)

;;(require 'typescript)
;;(require 'org-check-external-command)

(add-to-list 'org-babel-tangle-lang-exts '("typescript" . "ts"))

;; optionally declare default header arguments for this language
(defvar org-babel-default-header-args:typescript '((:cmdline . "--noImplicitAny")))

(defun org-babel-typescript-var-to-typescript (var)
  "Convert an elisp var into a string of typescript source code
specifying a var of the same value."
  (format "%S" var))

;; This function expands the body of a source code block by doing
;; things like prepending argument definitions to the body, it should
;; be called by the `org-babel-execute:typescript' function below.
(defun org-babel-expand-body:typescript (body params &optional processed-params)
  "Expand BODY according to PARAMS, return the expanded body."
  (let ((vars (nth 1 (or processed-params (org-babel-process-params params)))))
    (concat
     (mapconcat ;; define any variables
      (lambda (pair)
        (format "%s=%S"
                (car pair) (org-babel-typescript-var-to-typescript (cdr pair))))
      vars "\n") "\n" body "\n")))

(defun org-babel-execute:typescript (body params)
  "Execute a block of Typescript code with org-babel.  This function is
called by `org-babel-execute-src-block'"
  (let* ((tmp-src-file (org-babel-temp-file "ts-src-" ".ts"))
         (tmp-out-file (org-babel-temp-file "ts-src-" ".js"))
         (cmdline (cdr (assoc :cmdline params)))
         (cmdline (if cmdline (concat " " cmdline) ""))
         (jsexec (if (assoc :wrap params) ""
                   (concat " ; node " (org-babel-process-file-name tmp-out-file))
                   )))
    (with-temp-file tmp-src-file (insert body))
    (let ((results (org-babel-eval (format (concat (executable-find "tsc") "%s -out %s %s %s")
                                           cmdline
                                           (org-babel-process-file-name tmp-out-file)
                                           (org-babel-process-file-name tmp-src-file)
                                           jsexec)
                                   ""))

          (tsnode (org-babel-eval (format (concat (executable-find "ts-node") " %s") (org-babel-process-file-name tmp-src-file)) ""))
          (jstrans (with-temp-buffer
                     (insert-file-contents tmp-out-file)
                     (buffer-substring-no-properties (point-min) (point-max))
                     )))
      (if (eq jsexec "") jstrans tsnode)
      )))

(provide 'ob-typescript)

;;; ob-typescript.el ends here
