;;; asdf.lisp --- ASDF items documentation

;; Copyright (C) 2010 Didier Verna

;; Author:        Didier Verna <didier@lrde.epita.fr>
;; Maintainer:    Didier Verna <didier@lrde.epita.fr>
;; Created:       Thu Sep  9 11:59:59 2010
;; Last Revision: Thu Sep  9 12:06:16 2010

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
;; Components
;; ==========================================================================

;; -----------------------
;; Documentation protocols
;; -----------------------

(defgeneric document-component (component relative-to)
  (:documentation "Render COMPONENT's documentation.")
  (:method :around ((component asdf:component) relative-to)
    "Index COMPONENT and enclose its documentation in a @table environment."
    (index component relative-to)
    (@table ()
      (call-next-method)))
  (:method ((component asdf:component) relative-to)
    (format t "~@[@item Version~%~A~%~]"
      (escape (component-version component)))
    ;; #### NOTE: currently, we simply extract all the dependencies regardless
    ;; of the operations involved. We also assume that dependencies are of the
    ;; form (OP (OP DEP...) ...), but I'm not sure this is always the case.
    (let ((in-order-tos (slot-value component 'asdf::in-order-to))
	  dependencies)
      (when in-order-tos
	(dolist (in-order-to in-order-tos)
	  (dolist (op-dependency (cdr in-order-to))
	    (dolist (dependency (cdr op-dependency))
	      (pushnew dependency dependencies))))
	(format t "@item Dependencies~%")
	(@itemize-list dependencies :format "@t{~(~A}~)" :key #'escape)))
    (let ((parent (component-parent component)))
      (when parent
	(format t "@item Parent~%")
	(index parent relative-to)
	(format t "@t{~A}~%" (escape parent))))
    (if (eq (type-of component) 'asdf:system) ;; Yuck!
	(when *link-files*
	  (format t "@item Source Directory~%~
		      @url{file://~A, ignore, @t{~A}}~%"
	    (escape (component-pathname component))
	    (escape (component-pathname component)))
	  (let ((directory (escape
			    (directory-namestring
			     (system-definition-pathname component)))))
	    (format t "@item Installation Directory~%~
			@url{file://~A, ignore, @t{~A}}~%"
	      directory directory)))
      (render-location component relative-to))))



;; ==========================================================================
;; Files
;; ==========================================================================

;; -----
;; Nodes
;; -----

(defun file-node (file relative-to)
  "Create and return a FILE node."
  (make-node :name (format nil "The ~A file"
		     (escape (relative-location file relative-to)))
	     :section-name (format nil "@t{~A}"
			     (escape (relative-location file relative-to)))
	     :before-menu-contents
	     (render-to-string (document-component file relative-to))))

(defun add-files-node
    (node system &aux (system-directory (system-directory system))
		      (lisp-files (lisp-components system))
		      (other-files
		       (mapcar (lambda (type) (components system type))
			       '(asdf:c-source-file
				 asdf:java-source-file
				 asdf:doc-file
				 asdf:html-file
				 asdf:static-file)))
		      (files-node
		       (add-child node
			 (make-node :name "Files"
				    :synopsis "The files documentation"
				    :before-menu-contents (format nil "~
Files are sorted by type and then listed depth-first from the system
components tree."))))
		      (lisp-files-node
		       (add-child files-node
			 (make-node :name "Lisp files"
				    :section-name "Lisp"))))
  "Add SYSTEM's files node to NODE."
  (let ((system-base-name (escape (system-base-name system))))
    (add-child lisp-files-node
      (make-node :name (format nil "The ~A file" system-base-name)
		 :section-name (format nil "@t{~A}" system-base-name)
		 :before-menu-contents
		 (render-to-string
		   (format t "@lispfileindex{~A}@c~%~
			      @table @strong~%~
			      @item Location~%~
			      ~@[@url{file://~A, ignore, ~]@t{~A}~:[~;}~]~%"
		     system-base-name
		     (when *link-files*
		       (escape (make-pathname
				:name (system-file-name system)
				:type (system-file-type system)
				:directory (pathname-directory
					    (component-pathname system)))))
		     system-base-name
		     *link-files*)
		   (format t "@end table~%")))))
  (dolist (file lisp-files)
    (add-child lisp-files-node (file-node file system-directory)))
  (loop :with other-files-node
    :for files :in other-files
    :for name :in '("C files" "Java files" "Doc files" "HTML files"
		    "Other files")
    :for section-name :in '("C" "Java" "Doc" "HTML" "Other")
    :when files
    :do (setq other-files-node
	      (add-child files-node
		(make-node :name name :section-name section-name)))
    :and :do (dolist (file files)
	       (add-child other-files-node
		 (file-node file system-directory)))))



;; ==========================================================================
;; Modules
;; ==========================================================================

;; -----------------------
;; Documentation protocols
;; -----------------------

(defmethod document-component ((module asdf:module) relative-to)
  (call-next-method)
  (format t "@item Components~%")
  (@itemize-list (asdf:module-components module)
    :renderer (lambda (component)
		(reference component relative-to))))


;; -----
;; Nodes
;; -----

(defun module-node (module relative-to)
  "Create and return a MODULE node."
  (let ((name (escape (relative-location module relative-to))))
    (make-node :name (format nil "The ~A module" name)
	       :section-name (format nil "@t{~A}"name)
	       :before-menu-contents
	       (render-to-string (document-component module relative-to)))))

(defun add-modules-node
    (node system &aux (system-directory (system-directory system))
		      (modules (module-components system)))
  "Add SYSTEM's modules node to NODE."
  (when modules
    (let ((modules-node
	   (add-child node (make-node :name "Modules"
				      :synopsis "The modules documentation"
				      :before-menu-contents
				      (format nil "~
Modules are listed depth-first from the system components tree.")))))
      (dolist (module modules)
	(add-child modules-node (module-node module system-directory))))))



;; ==========================================================================
;; System
;; ==========================================================================

;; -----------------------
;; Documentation protocols
;; -----------------------

(defmethod document-component ((system asdf:system) relative-to)
  (format t "@item Name~%@t{~A}~%" (escape system))
  (when (system-description system)
    (format t "@item Description~%")
    (render-string (system-description system))
    (fresh-line))
  (when (system-long-description system)
    (format t "@item Long Description~%")
    (render-string (system-long-description system))
    (fresh-line))
  (multiple-value-bind (author email)
      (parse-author-string (system-author system))
    (when (or author email)
      (format t "@item Author~%~@[~A~]~:[~; ~]~@[<@email{~A}>~]~%"
	(escape author) (and author email) (escape email))))
  (multiple-value-bind (maintainer email)
      (parse-author-string (system-maintainer system))
    (when (or maintainer email)
      (format t "@item Maintainer~%~@[~A~]~:[~; ~]~@[<@email{~A}>~]~%"
	(escape maintainer) (and maintainer email) (escape email))))
  (format t "~@[@item License~%~A~%~]" (escape (system-license system)))
  (call-next-method)
  (format t "@item Packages~%")
  (@itemize-list (system-packages system) :renderer #'reference))


;; -----
;; Nodes
;; -----

(defun system-node (system)
  "Create and return the SYSTEM node."
  (make-node :name "System"
	     :synopsis "The system documentation"
	     :before-menu-contents
	     (render-to-string
	       (document-component system (system-directory system)))))

(defun add-system-node (node system)
  "Add SYSTEM's system node to NODE."
  (add-child node (system-node system)))


;;; asdf.lisp ends here
