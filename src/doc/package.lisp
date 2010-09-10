;;; package.lisp --- Package documentation

;; Copyright (C) 2010 Didier Verna

;; Author:        Didier Verna <didier@lrde.epita.fr>
;; Maintainer:    Didier Verna <didier@lrde.epita.fr>
;; Created:       Wed Sep  1 16:04:00 2010
;; Last Revision: Sun Sep  5 21:54:36 2010

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

(in-package :com.dvlsoft.declt)


;; ==========================================================================
;; Documentation Protocols
;; ==========================================================================

(defmethod title ((package package) &optional relative-to)
  (declare (ignore relative-to))
  (format nil "The ~(~A~) package" (escape package)))

;; Since node references are boring in Texinfo, we prefer to create custom
;; anchors for ASDF components and link to them instead.
(defmethod anchor ((package package) &optional relative-to)
  (declare (ignore relative-to))
  (format nil "~A anchor" (title package)))

(defmethod index ((package package) &optional relative-to)
  (declare (ignore relative-to))
  (format t "@packageindex{~(~A~)}@c~%" (escape package)))

(defmethod reference ((package package) &optional relative-to)
  (declare (ignore relative-to))
  (format t "@ref{~A, , @t{~(~A}~)}~%" (anchor package) (escape package)))

(defun document-package (package relative-to)
  "Render PACKAGE's documentation."
  (format t "@anchor{~A}@c~%" (anchor package))
  (index package)
  (@table ()
    (let* ((nicknames (package-nicknames package))
	   (length (length nicknames)))
      (when nicknames
	(format t "@item Nickname~p~%" length)
	(if (eq length 1)
	    (format t "@t{~(~A~)}" (escape (first nicknames)))
	  (@itemize-list nicknames
	    :format "@t{~(~A~)}"
	    :key #'escape))))
    (let* ((use-list (package-use-list package))
	   (length (length use-list)))
      (when use-list
	(format t "@item Use List~%")
	(if (eq length 1)
	    (format t "@t{~(~A~)}" (escape (first use-list)))
	  (@itemize-list (package-use-list package)
	    :format "@t{~(~A~)}"
	    :key #'escape))))
    (render-source package relative-to)))



;; ==========================================================================
;; Package Nodes
;; ==========================================================================

(defun add-packages-node
    (node system
     &aux (packages-node
	   (add-child node
	     (make-node :name "Packages"
			:synopsis "The packages documentation"
			:before-menu-contents (format nil "~
Packages are listed by definition order."))))
	  (packages (system-packages system)))
  "Add SYSTEM's packages node to NODE."
  (dolist (package packages)
    (add-child packages-node
      (make-node :name (title package)
		 :section-name (format nil "@t{~(~A~)}" (escape package))
		 :before-menu-contents
		 (render-to-string
		   (document-package package (system-directory system)))))))


;;; package.lisp ends here