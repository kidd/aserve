;; load in iServe
;;
;; $Id: load.cl,v 1.12.2.1 2000/02/08 19:48:37 jkf Exp $
;;

(defvar *loadswitch* :compile-if-needed)
;(require :defftype)

(defparameter *iserve-files* 
    '("htmlgen/htmlgen"
      "macs"
      "main"
      "parse"
      "decode"
      "publish"
      "log" ))

(defparameter *iserve-other-files*
    ;; other files that make up the neo dist
    '("readme.txt"
      "examples.cl"
      "foo.txt"
      "fresh.jpg"
      "load.cl"
      "neo.html"
      "prfile9.jpg"
      "htmlgen/htmlgen.html"
      ))

(defparameter *iserve-examples*
    '("examples"))


(with-compilation-unit  nil
  (dolist (file (append *iserve-files* *iserve-examples*))
    (case *loadswitch*
      (:compile-if-needed (compile-file-if-needed (format nil "~a.cl" file)))
      (:compile (compile-file (format nil "~a.cl" file)))
      (:load nil))
    (load (format nil "~a.fasl" file))))

      

(defun makeapp ()
  (run-shell-command "rm -fr iserveserver")
  (generate-application
   "iserveserver"
   "iserveserver/"
   '(:sock :process :defftype :foreign :ffcompat "loadonly.cl" "load.cl")
   :restart-init-function 'net.iserve::start-cmd
   :application-administration '(:resource-command-line
				 ;; Quiet startup:
				 "-Q")
   :read-init-files nil
   :print-startup-message nil
   :purify nil
   :include-compiler nil
   :include-devel-env nil
   :include-debugger t
   :include-tpl t
   :include-ide nil
   :discard-arglists t
   :discard-local-name-info t
   :discard-source-file-info t
   :discard-xref-info t
 
   :ignore-command-line-arguments t
   :suppress-allegro-cl-banner t))


(defun make-distribution ()
  ;; make a distributable version of iserve
  (run-shell-command "rm -fr iserve-dist")
  (run-shell-command "mkdir iserve-dist")
  (copy-files-to *iserve-files* "iserve.fasl")
  (copy-files-to '("htmlgen/htmlgen.html")
		 "iserve-dist/htmlgen.html")
  (dolist (file '("iserve.fasl"
		  "iserve.html"
		  "readme.txt"
		   "examples.cl"
		   "examples.fasl"
		   "foo.txt"
		   "fresh.jpg"
		   "prfile9.jpg"))
    (copy-files-to (list file)
		   (format nil "iserve-dist/~a" file))))
		

(defun make-src-distribution ()
  ;; make a source distribution of iserve
  ;;
  (run-shell-command "rm -fr iserve-src")
  (run-shell-command "mkdir iserve-src iserve-src/iserve iserve-src/iserve/htmlgen")
  (dolist (file (append (mapcar #'(lambda (file) (format nil "~a.cl" file))
				*iserve-files*)
			*iserve-other-files*))
    (copy-files-to
     (list file)
     (format nil "iserve-src/iserve/~a" file))))

  
  

(defun copy-files-to (files dest)
  ;; copy the contents of all files to the file named dest.
  ;; append .fasl to the filenames (if no type is present)
  
  (let ((buffer (make-array 4096 :element-type '(unsigned-byte 8))))
    (with-open-file (p dest :direction :output
		     :if-exists :supersede
		     :element-type '(unsigned-byte 8))
      (dolist (file files)
	(if* (null (pathname-type file))
	   then (setq file (concatenate 'string file  ".fasl")))
	(with-open-file (in file :element-type '(unsigned-byte 8))
	  (loop
	    (let ((count (read-sequence buffer in)))
	      (if* (<= count 0) then (return))
	      (write-sequence buffer p :end count))))))))
