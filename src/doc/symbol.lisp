;;; symbol.lisp --- Symbol based documentation

;; Copyright (C) 2010, 2011, 2012 Didier Verna

;; Author:        Didier Verna <didier@lrde.epita.fr>
;; Maintainer:    Didier Verna <didier@lrde.epita.fr>

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
(in-readtable :com.dvlsoft.declt)


;; ==========================================================================
;; Utilities
;; ==========================================================================

(defun render-internal-definitions-references (definitions)
  "Render references to a list of internal DEFINITIONS."
  (render-references definitions "Internal Definitions"))

(defun render-external-definitions-references (definitions)
  "Render references to a list of external DEFINITIONS."
  (render-references definitions "Exported Definitions"))

(defun render-definition-core (definition context)
  "Render DEFINITION's documentation core in CONTEXT.
The documentation core includes all common definition attributes:
  - docstring,
  - package,
  - source location.

Each element is rendered as a table item."
  (@tableitem "Package"
    (reference (symbol-package (definition-symbol definition))))
  (render-source definition context))

(defmacro render-@defvaroid (kind varoid context &body body)
  "Render VAROID's definition of KIND in CONTEXT."
  (let ((|@defform| (intern (concatenate 'string "@DEF" (symbol-name kind))
			    :com.dvlsoft.declt))
	(the-varoid (gensym "varoid")))
    `(let ((,the-varoid ,varoid))
       (,|@defform| (string-downcase (name ,the-varoid))
	 (anchor-and-index ,the-varoid)
	 (render-docstring ,the-varoid)
	 (@table ()
	   (render-definition-core ,the-varoid ,context)
	   ,@body)))))

(defun render-@defconstant (constant context)
  "Render CONSTANT's documentation in CONTEXT."
  (render-@defvaroid :constant constant context))

(defun render-@defspecial (special context)
  "Render SPECIAL variable's documentation in CONTEXT."
  (render-@defvaroid :special special context))

;; #### NOTE: see comment on the DOCSTRING method in ../item/symbol.lisp.
(defmacro render-@defsymbolmacro (symbol-macro context &body body)
  "Render SYMBOL-MACRO's documentation in CONTEXT."
  `(render-@defvaroid :symbolmacro ,symbol-macro ,context ,@body))

(defmacro render-@defunoid (kind (funcoid &rest funcoids) context &body body)
  "Render FUNCOID's definition of KIND in CONTEXT.
When FUNCOIDS, render their definitions jointly."
  (let ((|@defform| (intern (concatenate 'string "@DEF" (symbol-name kind))
			    :com.dvlsoft.declt))
	(|@defformx| (intern (concatenate 'string
			       "@DEF" (symbol-name kind) "X")
			     :com.dvlsoft.declt))
	(the-funcoid (gensym "funcoid")))
    `(let ((,the-funcoid ,funcoid))
       (,|@defform| (string-downcase (name ,the-funcoid))
		    (lambda-list ,the-funcoid)
	 (anchor-and-index ,the-funcoid)
	 (render-docstring ,the-funcoid)
	 ,@(mapcar (lambda (funcoid)
		     (let ((the-funcoid (gensym "funcoid")))
		       `(let ((,the-funcoid ,funcoid))
			  (,|@defformx|
			   (string-downcase (name ,the-funcoid))
			   (lambda-list ,the-funcoid))
			  (anchor-and-index ,the-funcoid))))
		   funcoids)
	 (@table ()
	   (render-definition-core ,the-funcoid ,context)
	   ,@body)))))

(defun render-@defun (function context)
  "Render FUNCTION's definition in CONTEXT."
  (render-@defunoid :un (function) context))

(defun render-@defunx (reader writer context)
  "Render READER and WRITER's definitions jointly in CONTEXT."
  (render-@defunoid :un (reader writer) context))

(defun render-@defmac (macro context)
  "Render MACRO's definition in CONTEXT."
  (render-@defunoid :mac (macro) context))

(defun render-@defcompilermacro (compiler-macro context)
  "Render COMPILER-MACRO's definition in CONTEXT."
  (render-@defunoid :compilermacro (compiler-macro) context))

(defmacro %render-@defmethod ((method &rest methods) context)
  "Render METHOD's definition in CONTEXT.
When METHODS, render their definitions jointly."
  (let ((the-method (gensym "method")))
    `(let ((,the-method ,method))
       (@defmethod (string-downcase (name ,the-method))
	   (lambda-list ,the-method)
	   (specializers ,the-method)
	   (qualifiers ,the-method)
	 (anchor-and-index ,the-method)
	 (render-docstring ,the-method)
	 ,@(mapcar (lambda (method)
		     (let ((the-method (gensym "method")))
		       `(let ((,the-method ,method))
			  (@defmethodx
			   (string-downcase (name ,the-method))
			   (lambda-list ,the-method)
			   (specializers ,the-method)
			   (qualifiers ,the-method))
			  (anchor-and-index ,the-method))))
		   methods)
	 (@table ()
	   (render-source ,the-method ,context))))))

(defun render-@defmethod (method context)
  "Render METHOD's definition in CONTEXT."
  (%render-@defmethod (method) context))

(defun render-@defmethodx (reader writer context)
  "Render READER and WRITER methods'definitions jointly in CONTEXT."
  (%render-@defmethod (reader writer) context))

(defmacro render-@defgeneric (generic context &body body)
  "Render GENERIC's definition in CONTEXT."
  `(render-@defunoid :generic (,generic) ,context ,@body))

(defmacro render-@defgenericx (reader writer context &body body)
  "Render generic READER and WRITER's definitions jointly in CONTEXT."
  `(render-@defunoid :generic (,reader ,writer) ,context ,@body))

(defun render-slot-property
    (slot property
	  &key (renderer (lambda (value)
			   (format t "@t{~A}~%"
			     (escape (format nil "~(~S~)" value)))))
	  &aux (value (slot-property (slot-definition-slot slot) property)))
  "Render SLOT definition's PROPERTY value as a table item."
  (when value
    (@tableitem (format nil "~@(~A~)" (symbol-name property))
      (funcall renderer value))))

(defun render-@defslot (slot)
  "Render SLOT's documentation."
  (@defslot (string-downcase (name slot))
    (index slot)
    (render-docstring slot)
    (@table ()
      (render-slot-property slot :type)
      (render-slot-property slot :allocation)
      (render-slot-property slot :initargs
	:renderer (lambda (value)
		    (let ((values (mapcar (lambda (val)
					    (escape
					     (format nil "~(~S~)" val)))
					  value)))
		      (format t "@t{~A}~{, @t{~A}~}"
			(first values)
			(rest values)))))
      (render-slot-property slot :initform)
      (let ((readers (slot-definition-readers slot)))
	(when readers
	  (@tableitem "Readers"
	    (@itemize-list readers :renderer #'reference))))
      (let ((writers (slot-definition-writers slot)))
	(when writers
	  (@tableitem "Writers"
	    (@itemize-list writers #|:renderer #'reference|#)))))))

(defun render-slots
    (classoid &aux (slots (classoid-definition-slots classoid)))
  "Render CLASSOID's direct slots documentation."
  (when slots
    (@tableitem "Direct slots"
      (dolist (slot slots)
	(render-@defslot slot)))))

(defmacro render-@defclassoid (kind classoid context &body body)
  "Render CLASSOID's definition of KIND in CONTEXT."
  (let ((|@defform| (intern (concatenate 'string "@DEF" (symbol-name kind))
			    :com.dvlsoft.declt))
	(the-classoid (gensym "classoid")))
    `(let ((,the-classoid ,classoid))
       (,|@defform| (string-downcase (name ,the-classoid))
	 (anchor-and-index ,the-classoid)
	 (render-docstring ,the-classoid)
	 (@table ()
	   (render-definition-core ,the-classoid ,context)
	   (render-references
	    (classoid-definition-parents ,the-classoid)
	    "Direct superclasses")
	   (render-references
	    (classoid-definition-children ,the-classoid)
	    "Direct subclasses")
	   (render-references
	    (classoid-definition-methods ,the-classoid)
	    "Direct methods")
	   (render-slots ,the-classoid)
	   ,@body)))))

;; #### PORTME.
(defun render-initargs
    (classoid
     &aux (initargs (sb-mop:class-direct-default-initargs
		     (find-class (classoid-definition-symbol classoid)))))
  "Render CLASSOID's direct default initargs."
  (when initargs
    (@tableitem "Direct Default Initargs"
      ;; #### FIXME: we should rather compute the longest initarg name and use
      ;; that as a template size for the @headitem specification.
      (@multitable (.3 .5)
	(format t "@headitem Initarg @tab Value~%")
	(dolist (initarg initargs)
	  (format t "@item @t{~A}~%@tab @t{~A}~%"
	    (escape (format nil "~(~S~)" (first initarg)))
	    (escape (format nil "~(~S~)" (second initarg)))))))))

(defun render-@defcond (condition context)
  "Render CONDITION's definition in CONTEXT."
  (render-@defclassoid :cond condition context
     (render-initargs condition)))

(defun render-@defstruct (structure context)
  "Render STRUCTURE's definition in CONTEXT."
  (render-@defclassoid :struct structure context))

(defun render-@defclass (class context)
  "Render CLASS's definition in CONTEXT."
  (render-@defclassoid :class class context
     (render-initargs class)))



;; ==========================================================================
;; Documentation Protocols
;; ==========================================================================

(defmethod title ((constant constant-definition) &optional relative-to)
  "Return CONSTANT's title."
  (declare (ignore relative-to))
  (format nil "the ~(~A~) constant" (name constant)))

(defmethod title ((special special-definition) &optional relative-to)
  "Return SPECIAL's title."
  (declare (ignore relative-to))
  (format nil "the ~(~A~) special variable" (name special)))

(defmethod title ((symbol-macro symbol-macro-definition) &optional relative-to)
  "Return SYMBOL-MACRO's title."
  (declare (ignore relative-to))
  (format nil "the ~(~A~) symbol macro" (name symbol-macro)))

(defmethod title ((macro macro-definition) &optional relative-to)
  "Return MACRO's title."
  (declare (ignore relative-to))
  (format nil "the ~(~A~) macro" (name macro)))

(defmethod title
    ((compiler-macro compiler-macro-definition) &optional relative-to)
  "Return COMPILER-MACRO's title."
  (declare (ignore relative-to))
  (format nil "the ~(~A~) compiler macro" (name compiler-macro)))

(defmethod title ((function function-definition) &optional relative-to)
  "Return FUNCTION's title."
  (declare (ignore relative-to))
  (format nil "the ~(~A~) function" (name function)))

(defmethod title ((method method-definition) &optional relative-to)
  "Return METHOD's title."
  (declare (ignore relative-to))
  (format nil "the ~(~A~{ ~A~^~}~{ ~A~^~}~) method"
    (name method)
    (mapcar #'pretty-specializer (specializers method))
    (qualifiers method)))

(defmethod title ((generic generic-definition) &optional relative-to)
  "Return GENERIC's title."
  (declare (ignore relative-to))
  (format nil "the ~(~A~) generic function" (name generic)))

(defmethod title ((condition condition-definition) &optional relative-to)
  "Return CONDITION's title."
  (declare (ignore relative-to))
  (format nil "the ~(~A~) condition" (name condition)))

;; #### NOTE: no TITLE method for SLOT-DEFINITION

(defmethod title ((structure structure-definition) &optional relative-to)
  "Return STRUCTURE's title."
  (declare (ignore relative-to))
  (format nil "the ~(~A~) structure" (name structure)))

(defmethod title ((class class-definition) &optional relative-to)
  "Return CLASS's title."
  (declare (ignore relative-to))
  (format nil "the ~(~A~) class" (name class)))

;; #### NOTE: the INDEX methods below only perform sub-indexing because the
;; main index entries are created automatically in Texinfo by the @defXXX
;; routines.

(defmethod index ((constant constant-definition) &optional relative-to)
  "Render CONSTANT's indexing command."
  (declare (ignore relative-to))
  (format t "@constantsubindex{~(~A~)}@c~%" (escape constant)))

(defmethod index ((special special-definition) &optional relative-to)
  "Render SPECIAL's indexing command."
  (declare (ignore relative-to))
  (format t "@specialsubindex{~(~A~)}@c~%" (escape special)))

(defmethod index ((symbol-macro symbol-macro-definition) &optional relative-to)
  "Render SYMBOL-MACRO's indexing command."
  (declare (ignore relative-to))
  (format t "@symbolmacrosubindex{~(~A~)}@c~%" (escape symbol-macro)))

(defmethod index ((macro macro-definition) &optional relative-to)
  "Render MACRO's indexing command."
  (declare (ignore relative-to))
  (format t "@macrosubindex{~(~A~)}@c~%" (escape macro)))

(defmethod index
    ((compiler-macro compiler-macro-definition) &optional relative-to)
  "Render COMPILER-MACRO's indexing command."
  (declare (ignore relative-to))
  (format t "@compilermacrosubindex{~(~A~)}@c~%" (escape compiler-macro)))

(defmethod index ((function function-definition) &optional relative-to)
  "Render FUNCTION's indexing command."
  (declare (ignore relative-to))
  (format t "@functionsubindex{~(~A~)}@c~%" (escape function)))

(defmethod index ((method method-definition) &optional relative-to)
  "Render METHOD's indexing command."
  (declare (ignore relative-to))
  (format t "@methodsubindex{~(~A~)}@c~%" (escape method)))

(defmethod index ((generic generic-definition) &optional relative-to)
  "Render GENERIC's indexing command."
  (declare (ignore relative-to))
  (format t "@genericsubindex{~(~A~)}@c~%" (escape generic)))

(defmethod index ((slot slot-definition) &optional relative-to)
  "Render SLOT's indexing command."
  (declare (ignore relative-to))
  (format t "@slotsubindex{~(~A~)}@c~%" (escape slot)))

(defmethod index ((condition condition-definition) &optional relative-to)
  "Render CONDITION's indexing command."
  (declare (ignore relative-to))
  (format t "@conditionsubindex{~(~A~)}@c~%" (escape condition)))

(defmethod index ((structure structure-definition) &optional relative-to)
  "Render STRUCTURE's indexing command."
  (declare (ignore relative-to))
  (format t "@structuresubindex{~(~A~)}@c~%" (escape structure)))

(defmethod index ((class class-definition) &optional relative-to)
  "Render CLASS's indexing command."
  (declare (ignore relative-to))
  (format t "@classsubindex{~(~A~)}@c~%" (escape class)))

(defmethod reference ((definition definition) &optional relative-to)
  "Render DEFINITION's reference."
  (declare (ignore relative-to))
  (format t "@ref{~A, , @t{~(~A}~)} (~A)~%"
    (escape (anchor-name definition))
    (escape definition)
    (type-name definition)))

(defmethod reference ((method method-definition) &optional relative-to)
  "Render METHOD's reference."
  (declare (ignore relative-to))
  (if (method-definition-foreignp method)
      (format t "@t{~(~A}~)~%" (escape method))
    (call-next-method)))

(defmethod reference ((generic generic-definition) &optional relative-to)
  "Render GENERIC function's reference."
  (declare (ignore relative-to))
  (if (generic-definition-foreignp generic)
      (format t "@t{~(~A}~)~%" (escape generic))
    (call-next-method)))

(defmethod reference ((classoid classoid-definition) &optional relative-to)
  "Render CLASSOID's reference."
  (declare (ignore relative-to))
  (if (classoid-definition-foreignp classoid)
      (format t "@t{~(~A}~)~%" (escape classoid))
    (call-next-method)))

(defmethod document ((constant constant-definition) context)
  "Render CONSTANT's documentation in CONTEXT."
  (render-@defconstant constant context))

(defmethod document ((special special-definition) context)
  "Render SPECIAL variable's documentation in CONTEXT."
  (render-@defspecial special context))

(defmethod document ((symbol-macro symbol-macro-definition) context)
  "Render SYMBOL-MACRO's documentation in CONTEXT."
  (render-@defsymbolmacro symbol-macro context
    (@tableitem "Expansion"
      (format t "@t{~(~A~)}~%"
	(escape
	 (format nil "~S" (macroexpand (definition-symbol symbol-macro))))))))

(defmethod document ((funcoid funcoid-definition) context)
  "Render FUNCOID's documentation in CONTEXT."
  (render-@defun funcoid context))

(defmethod document ((macro macro-definition) context)
  "Render MACRO's documentation in CONTEXT."
  (render-@defmac macro context))

(defmethod document ((compiler-macro compiler-macro-definition) context)
  "Render COMPILER-MACRO's documentation in CONTEXT."
  (render-@defcompilermacro compiler-macro context))

(defmethod document ((accessor accessor-definition) context)
  "Render ACCESSOR's documentation in CONTEXT."
  (cond ((and (equal (source accessor)
		     (source (accessor-definition-writer accessor)))
	      (equal (lambda-list accessor)
		     ;; #### NOTE: the writer has a first additional
		     ;; lambda-list argument of NEW-VALUE that we must skip
		     ;; before comparing.
		     (cdr (lambda-list (accessor-definition-writer accessor))))
	      (let ((docstring (docstring accessor))
		    (writer-docstring
		      (docstring (accessor-definition-writer accessor))))
		(or (and docstring writer-docstring
			 (string= docstring writer-docstring))
		    (null writer-docstring)
		    (and (not (null writer-docstring)) (null docstring)))))
	 (render-@defunx
	  accessor (accessor-definition-writer accessor) context))
	(t
	 (call-next-method)
	 (document (accessor-definition-writer accessor) context))))

(defmethod document ((method method-definition) context)
  "Render METHOD's documentation in CONTEXT."
  (render-@defmethod method context))

(defmethod document ((method accessor-method-definition) context)
  "Render accessor METHOD's documentation in CONTEXT."
  (cond ((and (equal (source method)
		     (source (accessor-method-definition-writer method)))
	      (equal (lambda-list method)
		     ;; #### NOTE: the writer has a first additional
		     ;; lambda-list argument of NEW-VALUE that we must skip
		     ;; before comparing.
		     (cdr (lambda-list
			   (accessor-method-definition-writer method))))
	      (let ((docstring (docstring method))
		    (writer-docstring
		      (docstring (accessor-method-definition-writer method))))
		(or (and docstring writer-docstring
			 (string= docstring writer-docstring))
		    (null writer-docstring)
		    (and (not (null writer-docstring)) (null docstring)))))
	 (render-@defmethodx
	  method (accessor-method-definition-writer method) context))
	(t
	 (call-next-method)
	 (document (accessor-method-definition-writer method) context))))

(defmethod document ((generic generic-definition) context)
  "Render GENERIC's documentation in CONTEXT."
  (render-@defgeneric generic context
    (@tableitem "Methods"
      (dolist (method (generic-definition-methods generic))
	(document method context)))))

(defmethod document ((accessor generic-accessor-definition) context)
  "Render generic ACCESSOR's documentation in CONTEXT."
  (cond ((and (equal (source accessor)
		     (source (generic-accessor-definition-writer accessor)))
	      (equal (lambda-list accessor)
		     ;; #### NOTE: the writer has a first additional
		     ;; lambda-list argument of NEW-VALUE that we must skip
		     ;; before comparing.
		     (cdr (lambda-list
			   (generic-accessor-definition-writer accessor))))
	      (let ((docstring (docstring accessor))
		    (writer-docstring
		      (docstring
		       (generic-accessor-definition-writer accessor))))
		(or (and docstring writer-docstring
			 (string= docstring writer-docstring))
		    (null writer-docstring)
		    (and (not (null writer-docstring)) (null docstring)))))
	 (render-@defgenericx
	  accessor (generic-accessor-definition-writer accessor) context
	  (@tableitem "Methods"
	    (dolist (method (generic-accessor-definition-methods accessor))
	      (document method context))
	    (dolist (method (generic-writer-definition-methods
			     (generic-accessor-definition-writer accessor)))
	      (document method context)))))
	(t
	 (call-next-method)
	 (document (generic-accessor-definition-writer accessor) context))))

;; #### NOTE: no DOCUMENT method for SLOT-DEFINITION

(defmethod document ((condition condition-definition) context)
  "Render CONDITION's documentation in CONTEXT."
  (render-@defcond condition context))

(defmethod document ((structure structure-definition) context)
  "Render STRUCTURE's documentation in CONTEXT."
  (render-@defstruct structure context))

(defmethod document ((class class-definition) context)
  "Render CLASS's documentation in CONTEXT."
  (render-@defclass class context))



;; ==========================================================================
;; Definition Nodes
;; ==========================================================================

(defun add-category-node (parent context status category definitions)
  "Add the STATUS CATEGORY node to PARENT for DEFINITIONS in CONTEXT."
  (add-child parent
    (make-node :name (format nil "~@(~A ~A~)" status category)
	       :section-name (format nil "~@(~A~)" category)
	       :before-menu-contents
	       (render-to-string
		 (dolist (definition (sort definitions #'string-lessp
					   :key #'definition-symbol))
		   (document definition context))))))

(defun add-categories-node (parent context status definitions)
  "Add the STATUS DEFINITIONS categories nodes to PARENT in CONTEXT."
  (dolist (category +categories+)
    (let ((category-definitions
	    (category-definitions (first category) definitions)))
      (when category-definitions
	(add-category-node parent context status (second category)
			   category-definitions)))))

(defun add-definitions-node
    (parent context
     &aux (definitions-node
	   (add-child parent
	     (make-node :name "Definitions"
			:synopsis "The symbols documentation"
			:before-menu-contents(format nil "~
Definitions are sorted by export status, category, package, and then by
lexicographic order.")))))
  "Add the definitions node to PARENT in CONTEXT."
  (loop	:for status :in '("exported" "internal")
	:for definitions :in (list
			      (context-external-definitions context)
			      (context-internal-definitions context))
	:unless (zerop (definitions-pool-size definitions))
	  :do (let ((node (add-child definitions-node
			    (make-node
			     :name (format nil "~@(~A~) definitions"
				     status)))))
		(add-categories-node node context status definitions))))


;;; symbol.lisp ends here
