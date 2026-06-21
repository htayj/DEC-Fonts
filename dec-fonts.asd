;;;; dec-fonts.asd

(asdf:defsystem #:dec-fonts
    :description "Generate DEC VT220 bitmap fonts from the ROM glyph image."
    :author "Taylor Hardy"
    :license "MIT"
    :serial t
    :depends-on (#:png #:array-operations)
    :components ((:file "package")
                 (:module "src"
                          :serial t
                          :components ((:file "generator")))))
