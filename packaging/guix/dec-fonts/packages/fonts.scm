(define-module (dec-fonts packages fonts)
  #:use-module (guix build-system gnu)
  #:use-module (guix gexp)
  #:use-module (guix git-download)
  #:use-module (guix packages)
  #:use-module ((guix licenses) #:prefix license:))

(define-public dec-fonts
  (package
    (name "dec-fonts")
    (version "0+git.local")
    ;; This local/manual package is meant to be built from the repository root:
    ;;   guix build -L packaging/guix dec-fonts
    ;; It packages the generated, committed dist/ font artifacts rather than
    ;; regenerating them in Guix.
    (source (local-file "." "dec-fonts-checkout"
                        #:recursive? #t
                        #:select? (git-predicate ".")))
    (build-system gnu-build-system)
    (arguments
     (list
      #:tests? #f
      #:phases
      #~(modify-phases %standard-phases
          (delete 'configure)
          (delete 'build)
          (replace 'install
            (lambda* (#:key outputs #:allow-other-keys)
              (use-modules (guix build utils))
              (let* ((out (assoc-ref outputs "out"))
                     (bdf-dir (string-append out "/share/fonts/dec-fonts/bdf"))
                     (otb-dir (string-append out "/share/fonts/dec-fonts/otb"))
                     (psf-dir (string-append out
                                             "/share/consolefonts/dec-fonts"))
                     (conf-dir (string-append out "/share/fontconfig/conf.avail"))
                     (enabled-dir (string-append out "/etc/fonts/conf.d"))
                     (conf-file (string-append conf-dir "/75-dec-fonts.conf")))
                (for-each mkdir-p
                          (list bdf-dir otb-dir psf-dir conf-dir enabled-dir
                                (string-append out "/share/doc/dec-fonts")
                                (string-append out "/share/dec-fonts")))
                (for-each (lambda (file) (install-file file bdf-dir))
                          (find-files "dist/fonts/bdf" "\\.bdf$"))
                (install-file "dist/fonts/bdf/fonts.dir" bdf-dir)
                (install-file "dist/fonts/bdf/fonts.scale" bdf-dir)
                (for-each (lambda (file) (install-file file otb-dir))
                          (find-files "dist/fonts/otb" "\\.otb$"))
                (for-each (lambda (file) (install-file file psf-dir))
                          (find-files "dist/fonts/psf" "\\.psf$"))
                (install-file "README.org" (string-append out "/share/doc/dec-fonts"))
                (install-file "dist/dec.set" (string-append out "/share/dec-fonts"))
                (call-with-output-file conf-file
                  (lambda (port)
                    (format port "<?xml version=\"1.0\"?>~%")
                    (format port "<!DOCTYPE fontconfig SYSTEM ~s>~%"
                            "urn:fontconfig:fonts.dtd")
                    (format port "<fontconfig>~%")
                    (format port "  <description>DEC VT220 bitmap fonts</description>~%")
                    (format port "  <dir>~a/share/fonts/dec-fonts</dir>~%" out)
                    (format port "  <dir>~a/share/fonts/dec-fonts/bdf</dir>~%" out)
                    (format port "  <dir>~a/share/fonts/dec-fonts/otb</dir>~%" out)
                    (format port "  <selectfont>~%")
                    (format port "    <acceptfont>~%")
                    (format port "      <pattern>~%")
                    (format port "        <patelt name=\"family\">")
                    (format port "<string>vt220</string></patelt>~%")
                    (format port "      </pattern>~%")
                    (format port "    </acceptfont>~%")
                    (format port "  </selectfont>~%")
                    (format port "</fontconfig>~%")))
                (symlink conf-file (string-append enabled-dir "/75-dec-fonts.conf"))))))))
    (synopsis "DEC VT220 bitmap fonts")
    (description
     "DEC-Fonts provides bitmap fonts generated from a DEC VT220 ROM
recreation.  The package includes BDF and OTB fonts for fontconfig/Xft and
X core-font users, plus PSF fonts for the Linux console.")
    (home-page "https://github.com/htayj/DEC-Fonts")
    (license license:expat)))
