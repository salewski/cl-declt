;;; item.lisp --- Items subject to documentation

;; Copyright (C) 2010 Didier Verna

;; Author:        Didier Verna <didier@lrde.epita.fr>
;; Maintainer:    Didier Verna <didier@lrde.epita.fr>
;; Created:       Wed Sep  8 21:10:37 2010
;; Last Revision: Thu Sep  9 15:24:31 2010

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


(defgeneric location (item)
  (:documentation "Return ITEM's pathname.")
  (:method ((pathname pathname))
    pathname))

(defun relative-location (item relative-to)
  "Return ITEM's location RELATIVE-TO."
  (let ((location (location item)))
    (when location
      (enough-namestring location relative-to))))

(defvar *link-files* t
  "Whether to create links to files or directories in the reference manual.
When true (the default), pathnames are made clickable although the links are
specific to this particular installation.

Setting this to NIL is preferable for creating reference manuals meant to put
online, and hence independent of any specific installation.")

(defun render-location (item relative-to)
  "Render an itemized location line for ITEM RELATIVE-TO."
  (let ((location (location item)))
    (when location
      (format t "@item Location~%~
		 ~@[@url{file://~A, ignore, ~]@t{~A}~:[~;}~]~%"
	(when *link-files*
	  (escape location))
	(escape (relative-location location relative-to))
	*link-files*))))


;;; item.lisp ends here
