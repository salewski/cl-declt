;;; package.lisp --- Common Lisp package definition

;; Copyright (C) 2010, 2011 Didier Verna

;; Author:        Didier Verna <didier@lrde.epita.fr>
;; Maintainer:    Didier Verna <didier@lrde.epita.fr>
;; Created:       Mon Aug 23 17:41:36 2010
;; Last Revision: Wed Jun 29 13:49:14 2011

;; This file is part of Declt.

;; Declt is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License version 3,
;; as published by the Free Software Foundation.

;; Declt is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.


;;; Commentary:

;; Contents management by FCM version 0.1.


;;; Code:

(in-package :cl-user)

(defpackage :com.dvlsoft.declt
  (:use :cl)
  (:import-from :com.dvlsoft.declt.asdf
    :define-constant
    :+release-major-level+
    :+release-minor-level+
    :+release-status+
    :+release-status-level+
    :+release-name+
    :version)
  (:import-from :asdf
    ;; Some slot-unbound proof accessors that we can import directly (see
    ;; src/util/asdf.lisp for wrappers around other ones).
    :system-definition-pathname
    :component-name
    :component-pathname
    :component-relative-pathname
    :component-parent
    :system-source-directory
    ;; Some functions that we can import directly.
    :find-system)
  (:export
   ;; From com.dvlsoft.declt.asd:
   :+release-major-level+
   :+release-minor-level+
   :+release-status+
   :+release-status-level+
   :+release-name+
   :version
   ;; From package.lisp:
   :nickname-package
   ;; From src/doc/asdf.lisp:
   :*link-files*
   ;; From src/declt.lisp:
   :declt))


(in-package :com.dvlsoft.declt)


;; -------------------
;; External utilities:
;; -------------------

(defun nickname-package (&optional (nickname :declt))
  "Add NICKNAME (:DECLT by default) to the :COM.DVLSOFT.DECLT package."
  (rename-package :com.dvlsoft.declt
		  (package-name :com.dvlsoft.declt)
		  (adjoin nickname (package-nicknames :com.dvlsoft.declt)
			  :test #'string-equal)))


;;; package.lisp ends here
