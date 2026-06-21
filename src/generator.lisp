;;;; src/generator.lisp

(in-package #:dec-fonts.generator)

(defparameter +hexes+
  '( ("0020" "space")
        ("25C6" "diamond")
        ("2592" "blit/medium-shade") ;; could also be 25A6, but nethack wants 2592
        ("2409" "HT")
        ("240C" "FF")
        ("240D" "CR")
        ("240A" "LF")
        ("00B0" "degree")
        ("00B1" "plusminus")
        ("2424" "NL")
        ("240B" "VT")
        ("2518" "box-upper-left")
        ("2510" "box-lower-left")
        ("250C" "box-lower-right")
        ("2514" "box-upper-right")
        ("253C" "box-cross")
        ;; col 
        ("23BA" "1/5 line")
        ("23BB" "2/5 line")
        ("2500" "box-draw-line")
        ("23BC" "4/5 line")
        ("23BD" "5/5 line")
        ("251C" "box-T-right")
        ("2524" "box-T-left")
        ("2534" "box-T-up")
        ("252C" "box-T-down")
        ("2502" "box-vetical-line")
        ("2264" "less-equal")
        ("2265" "greater-equal")
        ("03C0" "pi")
        ("2260" "not-equal")
        ("00A3" "pound")
        ("00b7" "dot")
        ;; col 
        ("2E2E" "reverse question mark")
        ("0021" "exclamation")
        ("0022" "quote")
        ("0023" "pound")
        ("0024" "dollar")
        ("0025" "percent")
        ("0026" "ampersand")
        ("0027" "appostrophe")
        ("0028" "open paren")
        ("0029" "close paren")
        ("002A" "astrisk")
        ("002B" "plus")
        ("002C" "comma")
        ("002D" "dash")
        ("002E" "period")
        ("002F" "forward slash")
        ;; col 
        ("0030" "0")
        ("0031" "1")
        ("0032" "2")
        ("0033" "3")
        ("0034" "4")
        ("0035" "5")
        ("0036" "6")
        ("0037" "7")
        ("0038" "8")
        ("0039" "9")
        ("003A" ":")
        ("003B" ";")
        ("003C" "<")
        ("003D" "=")
        ("003E" ">")
        ("003F" "?")
        ;; col 
        ("0040" "@")
        ("0041" "A")
        ("0042" "B")
        ("0043" "C")
        ("0044" "D")
        ("0045" "E")
        ("0046" "F")
        ("0047" "G")
        ("0048" "H")
        ("0049" "I")
        ("004A" "J")
        ("004B" "K")
        ("004C" "L")
        ("004D" "M")
        ("004E" "N")
        ("004F" "O")
        ;; col 
        ("0050" "P")
        ("0051" "Q")
        ("0052" "R")
        ("0053" "S")
        ("0054" "T")
        ("0055" "U")
        ("0056" "V")
        ("0057" "W")
        ("0058" "X")
        ("0059" "Y")
        ("005A" "Z")
        ("005B" "[")
        ("005C" "backslash")
        ("005D" "]")
        ("005E" "^")
        ("005F" "_")
        ;; col 
        ("0060" "`")
        ("0061" "a")
        ("0062" "b")
        ("0063" "c")
        ("0064" "d")
        ("0065" "e")
        ("0066" "f")
        ("0067" "g")
        ("0068" "h")
        ("0069" "i")
        ("006a" "j")
        ("006b" "k")
        ("006c" "l")
        ("006d" "m")
        ("006e" "n")
        ("006f" "o")
        ;; col 
        ("0070" "p")
        ("0071" "q")
        ("0072" "r")
        ("0073" "s")
        ("0074" "t")
        ("0075" "u")
        ("0076" "v")
        ("0077" "w")
        ("0078" "x")
        ("0079" "y")
        ("007A" "z")
        ("007B" "{")
        ("007C" "|")
        ("007D" "}")
        ("007E" "~")
        ("007F" "DEL")
        ;; col
        ;;dashes
        ("2010" "hyphen")
        ("2011" "nb hyphen")
        ("2012" "figure dash")
        ("2013" "en dash")
        ("2014" "em dash")
        ("2015" "horizontal bar")
        ;;general punct
        ("2016" "doulbe vertical line")
        ("2017" "doulbe low line")
        ;;quotation marks and apostrophies
        ("2018" "left single quotation mark")
        ("2019" "right single quotation mark")
        ("201A" "single low-9 quotation mark")
        ("201B" "single high-reversed-9 quotation mark")
        ("201C" "left double quotation mark")
        ("201D" "right double quotation mark")
        ("201E" "double low-9 quotation mark")
        ("201F" "double high-reserved-9 quotation mark")
        ;; col
        ()
        ()
        ()
        ()
        ()
        ()
        ()
        ()
        ()
        ()
        ()
        ()
        ()
        ()
        ()
        ()
        ;; col
        ()
        ("00A1" "Inverted exclamation mark")
        ("00A2" "Cent sign")
        ()
        ("00A8" "Diaeresis")
        ("00A5" "Yen sign")
        ("00A6" "Broken bar")
        ("00A7" "Section sign")
        ("00A4" "Currency sign")
        ("00A9" "Copyright sign")
        ("00AA" "Feminine ordinal indicator")
        ("00AB" "Left-pointing double angle quotation mark")
        ("00AC" "Not sign")
        ("00D7" "multiplication sign")
        ("00AE" "Registered sign")
        ("00AF" "Macron")
        ;; col
        ()
        ()
        ("00B2" "Superscript two")
        ("00B3" "Superscript three")
        ("00B4" "Acute accent")
        ("00B5" "Micro sign")
        ("00B6" "Pilcrow sign")
        ("2022" "Bullet")
        ("00B8" "Cedilla  CUSTOM")
        ("00B9" "Superscript one")
        ("00BA" "Masculine ordinal indicator")
        ("00BB" "Right-pointing double-angle quotation mark")
        ("00BC" "Vulgar fraction one quarter")
        ("00BD" "Vulgar fraction one half")
        ("00BE" "Vulgar fraction three quarters")
        ("00BF" "Inverted question mark")
        ;; col
        ("00C0" "Latin Capital Letter A with grave")
        ("00C1" "Latin Capital letter A with acute")
        ("00C2" "Latin Capital letter A with circumflex")
        ("00C3" "Latin Capital letter A with tilde")
        ("00C4" "Latin Capital letter A with diaeresis")
        ("00C5" "Latin Capital letter A with ring above")
        ("00C6" "Latin Capital letter AE")
        ("00C7" "Latin Capital letter C with cedilla")
        ("00C8" "Latin Capital letter E with grave")
        ("00C9" "Latin Capital letter E with acute")
        ("00CA" "Latin Capital letter E with circumflex")
        ("00CB" "Latin Capital letter E with diaeresis")
        ("00CC" "Latin Capital letter I with grave")
        ("00CD" "Latin Capital letter I with acute")
        ("00CE" "Latin Capital letter I with circumflex")
        ("00CF" "Latin Capital letter I with diaeresis")
        ("00D0" "Latin Capital letter Eth")
        ("00D1" "Latin Capital letter N with tilde")
        ("00D2" "Latin Capital letter O with grave")
        ("00D3" "Latin Capital letter O with acute")
        ("00D4" "Latin Capital letter O with circumflex")
        ("00D5" "Latin Capital letter O with tilde")
        ("00D6" "Latin Capital letter O with diaeresis")
        ("0152" "Capital OE")
        ("00D8" "Latin Capital letter O with stroke")
        ("00D9" "Latin Capital letter U with grave")
        ("00DA" "Latin Capital letter U with acute")
        ("00DB" "Latin Capital Letter U with circumflex")
        ("00DC" "Latin Capital Letter U with diaeresis")
        ("0178" "Latin Capital Letter Y with diaeresis")
        ("00DE" "Latin Capital Letter Thorn")
        ("00DF" "Latin Small Letter sharp S")
        ("00E0" "Latin Small Letter A with grave")
        ("00E1" "Latin Small Letter A with acute")
        ("00E2" "Latin Small Letter A with circumflex")
        ("00E3" "Latin Small Letter A with tilde")
        ("00E4" "Latin Small Letter A with diaeresis")
        ("00E5" "Latin Small Letter A with ring above")
        ("00E6" "Latin Small Letter AE")
        ("00E7" "Latin Small Letter C with cedilla")
        ("00E8" "Latin Small Letter E with grave")
        ("00E9" "Latin Small Letter E with acute")
        ("00EA" "Latin Small Letter E with circumflex")
        ("00EB" "Latin Small Letter E with diaeresis")
        ("00EC" "Latin Small Letter I with grave")
        ("00ED" "Latin Small Letter I with acute")
        ("00EE" "Latin Small Letter I with circumflex")
        ("00EF" "Latin Small Letter I with diaeresis")
        ("00F0" "Latin Small Letter Eth")
        ("00F1" "Latin Small Letter N with tilde")
        ("00F2" "Latin Small Letter O with grave")
        ("00F3" "Latin Small Letter O with acute")
        ("00F4" "Latin Small Letter O with circumflex")
        ("00F5" "Latin Small Letter O with tilde")
        ("00F6" "Latin Small Letter O with diaeresis")
        ("0153" "small OE")
        ("00F8" "Latin Small Letter O with stroke")
        ("00F9" "Latin Small Letter U with grave")
        ("00FA" "Latin Small Letter U with acute")
        ("00FB" "Latin Small Letter U with circumflex")
        ("00FC" "Latin Small Letter U with diaeresis")
        ("00FF" "Latin Small Letter Y with diaeresis")
        ("00FE" "Latin Small Letter Thorn")
        ("25A1" "white square")
        ("00FD" "Latin Small Letter Y with acute")))

(defparameter +grid-columns+ 18)
(defparameter +grid-rows+ 16)
(defparameter +cell-height+ 10)
(defparameter +cell-width+ 8)
(defparameter +cell-column-padding+ 2)
(defparameter +cell-row-padding+ 2)
(defparameter +x-offset+ 1)
(defparameter +y-offset+ 2)

(defparameter +output-sizes+
  '((1 2 50)
    (2 4 50)
    (3 6 50)
    (4 8 50)
    (5 10 50)))

(defparameter +default-source-image+ "./rom-separated_extended.png")
(defparameter +default-dist-root+ "./dist")
(defparameter +y-resolution+ 75)
(defparameter +default-character-code+ 9670)

(defun directory-pathname (pathname-designator)
  "Return PATHNAME-DESIGNATOR as a directory pathname."
  (let ((pathname (pathname pathname-designator)))
    (if (or (pathname-name pathname) (pathname-type pathname))
        (make-pathname :directory (append (or (pathname-directory pathname)
                                               '(:relative))
                                           (list (file-namestring pathname)))
                       :name nil
                       :type nil
                       :defaults pathname)
        pathname)))

(defun dist-path (dist-root relative-pathname)
  "Resolve RELATIVE-PATHNAME underneath DIST-ROOT."
  (merge-pathnames relative-pathname (directory-pathname dist-root)))

(defun map-indexed-vector (function vector
                           &optional (result (make-array (array-dimensions vector))))
  "Map FUNCTION over VECTOR-like one-dimensional ARRAY, passing element and index."
  (dotimes (index (array-dimension vector 0) result)
    (setf (aref result index)
          (funcall function (aref vector index) index))))

(defun map-array-elements (function array
                           &optional (result (make-array (array-dimensions array))))
  "Return an array with FUNCTION applied to each element of ARRAY."
  (dotimes (index (array-total-size array) result)
    (setf (row-major-aref result index)
          (funcall function (row-major-aref array index)))))

(defun map-array-rows (function array)
  "Return a new two-dimensional array by applying FUNCTION to each row of ARRAY."
  (aops:combine
   (map-indexed-vector function (aops:split array 1))))

(defun append-arrays-by-row (left right)
  "Append two arrays horizontally, row by row."
  (let ((right-rows (aops:split right 1)))
    (map-array-rows
     (lambda (row index)
       (concatenate 'vector row (aref right-rows index)))
     left)))

(defun array-to-lists (array)
  "Convert a two-dimensional array to nested lists."
  (loop for row below (array-dimension array 0)
        collect (loop for column below (array-dimension array 1)
                      collect (aref array row column))))

(defun red-to-pixel-type (red)
  "Map a red-channel byte from the source PNG to the generator's pixel codes."
  (cond
    ((> red 245) 2)
    ((> red 200) 0)
    (t 1)))

(defun pixel-type-to-visible-character (type)
  "Return a block character useful for debugging a pixel TYPE."
  (cond
    ((= type 1) '▉)
    ((= type 0) '░)
    ((= type 2) '▒)))

(defun color-red (color)
  (aref color 0))

(defun image-to-ternary-array (input-pathname)
  "Read INPUT-PATHNAME and return a 2D array of source pixel codes.

The codes preserve the original script's meanings:
0 is spacing, 1 is an ink pixel, and 2 is a separator/background marker."
  (with-open-file (input input-pathname :element-type '(unsigned-byte 8))
    (let ((image (png:decode input)))
      (map-array-elements #'red-to-pixel-type
                          (map-array-elements #'color-red
                                              (aops:split image 2))))))

(defun pretty-glyph-string (glyph)
  "Return a human-readable block-character rendering of GLYPH."
  (format nil "~{~A~%^~}"
          (coerce
           (map-array-elements
            (lambda (cells)
              (format nil "~{~A~^~}" cells))
            (map-array-elements (lambda (row) (coerce row 'list))
                                (aops:split
                                 (map-array-elements #'pixel-type-to-visible-character glyph)
                                 1)))
           'list)))

(defun spacing-row-p (row)
  (every (lambda (cell) (= cell 2)) row))

(defun extract-cell (image start-x start-y width height)
  "Return the WIDTH by HEIGHT cell in IMAGE at START-X, START-Y."
  (aops:combine
   (map-array-elements
    (lambda (row)
      (aops:partition row start-x (+ start-x width)))
    (aops:split
     (aops:partition image start-y (+ start-y height))
     1))))

(defun y-coordinate (row &key (cell-height +cell-height+)
                          (cell-row-padding +cell-row-padding+)
                          (y-offset +y-offset+))
  (+ y-offset (* row (+ cell-height cell-row-padding))))

(defun x-coordinate (column &key (cell-width +cell-width+)
                             (cell-column-padding +cell-column-padding+)
                             (x-offset +x-offset+))
  (+ x-offset (* column (+ cell-width cell-column-padding))))

(defun cell-at (image column row
                &key
                  (cell-height +cell-height+)
                  (cell-width +cell-width+)
                  (cell-column-padding +cell-column-padding+)
                  (cell-row-padding +cell-row-padding+)
                  (x-offset +x-offset+)
                  (y-offset +y-offset+))
  "Extract one glyph cell from IMAGE by grid COLUMN and ROW."
  (extract-cell image
                (x-coordinate column
                              :cell-width cell-width
                              :cell-column-padding cell-column-padding
                              :x-offset x-offset)
                (y-coordinate row
                              :cell-height cell-height
                              :cell-row-padding cell-row-padding
                              :y-offset y-offset)
                cell-width
                cell-height))

(defun character-cells (image
                        &key
                          (columns +grid-columns+)
                          (rows +grid-rows+)
                          (cell-height +cell-height+)
                          (cell-width +cell-width+)
                          (cell-column-padding +cell-column-padding+)
                          (cell-row-padding +cell-row-padding+)
                          (x-offset +x-offset+)
                          (y-offset +y-offset+))
  "Return all character cells from IMAGE in the DEC ROM grid order."
  (loop for index below (* columns rows)
        for column = (floor index rows)
        for row = (mod index rows)
        collect (cell-at image column row
                         :cell-height cell-height
                         :cell-width cell-width
                         :cell-column-padding cell-column-padding
                         :cell-row-padding cell-row-padding
                         :x-offset x-offset
                         :y-offset y-offset)))

(defun prepend-zero-column (glyph)
  (map-array-rows
   (lambda (row index)
     (declare (ignore index))
     (concatenate 'vector #(0) row))
   glyph))

(defun append-zero-column (glyph)
  (map-array-rows
   (lambda (row index)
     (declare (ignore index))
     (concatenate 'vector row #(0)))
   glyph))

(defun array-or (left right)
  "Return the element-wise binary OR of LEFT and RIGHT."
  (let ((result (make-array (array-dimensions left))))
    (dotimes (index (array-total-size left) result)
      (let ((left-pixel (row-major-aref left index))
            (right-pixel (row-major-aref right index)))
        (setf (row-major-aref result index)
              (if (or (= left-pixel 1) (= right-pixel 1))
                  1
                  0))))))

(defun stretch-glyph (glyph)
  "Apply the VT-style horizontal antialias/stretch operation to GLYPH."
  (array-or (prepend-zero-column glyph)
            (append-zero-column glyph)))

(defun append-last-column (glyph)
  "Duplicate GLYPH's last column on the right edge."
  (let ((last-column-index (1- (aops:ncol glyph))))
    (map-array-rows
     (lambda (row index)
       (declare (ignore index))
       (concatenate 'vector row (vector (aref row last-column-index))))
     glyph)))

(defun repeat-list (value count)
  (loop repeat count collect value))

(defun scale-vector (vector factor)
  "Repeat each element of VECTOR FACTOR times, returning a vector."
  (coerce (loop for value across vector
                append (repeat-list value factor))
          'vector))

(defun scale-width (glyph factor)
  "Scale GLYPH horizontally by integer FACTOR."
  (map-array-rows
   (lambda (row index)
     (declare (ignore index))
     (scale-vector row factor))
   glyph))

(defun double-width (glyph)
  (scale-width glyph 2))

(defun scale-height (glyph factor)
  "Scale GLYPH vertically by integer FACTOR."
  (aops:combine
   (coerce (loop for row across (aops:split glyph 1)
                 append (repeat-list row factor))
           'vector)))

(defun compose (&rest functions)
  "Compose FUNCTIONS right-to-left."
  (lambda (value)
    (reduce #'funcall functions
            :initial-value value
            :from-end t)))

(defun glyph-padding (glyph)
  "Return the original generator's right-padding array for GLYPH.

This intentionally preserves the old quirk of adding eight columns when the
width is already byte-aligned."
  (let ((padding-needed (- 8 (mod (aops:ncol glyph) 8)))
        (height (aops:nrow glyph)))
    (aops:zeros (list height padding-needed))))

(defun pad-glyph (glyph)
  (append-arrays-by-row glyph (glyph-padding glyph)))

(defun row-to-bit-string (row)
  (with-output-to-string (output)
    (loop for cell across row
          do (format output "~D" cell))))

(defun glyph-rows-to-bit-strings (glyph)
  (map-indexed-vector
   (lambda (row index)
     (declare (ignore index))
     (row-to-bit-string row))
   (aops:split glyph 1)))

(defun binary-string-to-hex (string index)
  (declare (ignore index))
  (format nil (format nil "~~~A,'0X" (floor (length string) 4))
          (parse-integer string :radix 2)))

(defun bit-strings-to-hex (strings)
  (map-indexed-vector #'binary-string-to-hex strings))

(defun glyph-to-bdf-bitmap (glyph)
  (bit-strings-to-hex (glyph-rows-to-bit-strings (pad-glyph glyph))))

(defun hex-string (entry)
  (car entry))

(defun encoded-hex-strings ()
  (remove nil (sort (mapcar #'hex-string +hexes+) #'string-lessp)))

(defun duplicate-adjacent-strings (strings &optional (duplicates '()))
  (let ((this-item (car strings))
        (next-item (cadr strings))
        (rest-items (cdr strings)))
    (if rest-items
        (duplicate-adjacent-strings
         rest-items
         (if (string-equal this-item next-item)
             (cons this-item duplicates)
             duplicates))
        duplicates)))

(defun validate-no-duplicate-hexes ()
  (let ((duplicates (duplicate-adjacent-strings
                     (remove nil (sort (mapcar #'hex-string +hexes+)
                                       #'string-lessp)))))
    (when duplicates
      (print (format nil "duplicates detected: ~A" duplicates)))))

(defun decimal-string-for-entry (entry)
  (format nil "~d" (parse-integer (hex-string entry) :radix 16)))

(defun zip-hexes-and-glyphs (hex-list glyphs &optional (pairs '()))
  "Pair HEX-LIST and GLYPHS, preserving the original reversed BDF order."
  (let ((glyph (car glyphs))
        (hex-entry (car hex-list)))
    (if (and (not glyph) (not hex-entry))
        pairs
        (zip-hexes-and-glyphs
         (cdr hex-list)
         (cdr glyphs)
         (cons (list (hex-string hex-entry) glyph)
               pairs)))))

(defun size-line (zipped-glyphs x-resolution y-resolution)
  (let ((height (aops:nrow (cadar zipped-glyphs))))
    (format nil "SIZE ~d ~d ~d" height x-resolution y-resolution)))

(defun bounding-box-line (zipped-glyphs)
  (let* ((width (aops:ncol (cadar zipped-glyphs)))
         (height (aops:nrow (cadar zipped-glyphs)))
         (descent (- (/ height 5))))
    (format nil "FONTBOUNDINGBOX ~d ~d ~d ~d" width height 0 descent)))

(defun descent-line (zipped-glyphs)
  (let* ((height (aops:nrow (cadar zipped-glyphs)))
         (descent (/ height 5)))
    (format nil "FONT_DESCENT ~d" descent)))

(defun ascent-line (zipped-glyphs)
  (let* ((height (aops:nrow (cadar zipped-glyphs)))
         (descent (/ height 5))
         (ascent (- height descent)))
    (format nil "FONT_ASCENT ~d" ascent)))

(defun chars-line (zipped-glyphs)
  (declare (ignore zipped-glyphs))
  (format nil "CHARS ~d" (length (encoded-hex-strings))))

(defun newline-joined-string (strings)
  (format nil "~{~A~^~%~}" strings))

(defun generate-file-name (foundry face width height width-type style-name xres
                           &optional relative-width)
  (declare (ignore relative-width))
  (format nil "~A-~A-~A-~A-~Ax~A-~Axres"
          foundry
          face
          width-type
          style-name
          width
          height
          xres))

(defun generate-font-name (foundry face width height width-type style-name xres
                           &optional relative-width)
  (format nil "-~A-~A-medium-r-~A-~A-~A-~A-~A-75-c-~A-iso10646-1~A"
          foundry
          face
          width-type
          style-name
          height
          (* 10 height)
          xres
          (* width 10)
          (if relative-width
              (format nil "-relwidth~A" relative-width)
              "")))

(defun string-property-line (key value)
  (format nil "~A \"~A\"" key value))

(defun property-line (key value)
  (format nil "~A ~A" key value))

(defun build-header (zipped-glyphs width-type style-name xres relative-width)
  "Return the exact BDF header used by the original generator."
  (let* ((width (aops:ncol (cadar zipped-glyphs)))
         (height (aops:nrow (cadar zipped-glyphs))))
    (newline-joined-string
     (list "STARTFONT 2.1"
           ;; The original XLFD FONT line omitted RELATIVE-WIDTH; keep that quirk.
           (format nil "FONT ~A"
                   (generate-font-name "DIGITAL" "VT220" width height
                                       width-type style-name xres))
           (size-line zipped-glyphs xres +y-resolution+)
           (bounding-box-line zipped-glyphs)
           "STARTPROPERTIES 21"
           (string-property-line "FOUNDRY" "DIGITAL")
           (string-property-line "FAMILY_NAME" "vt220")
           (string-property-line "WEIGHT_NAME" "medium")
           (property-line "RELATIVE_SETWIDTH" relative-width)
           (string-property-line "SLANT" "r")
           (string-property-line "SETWIDTH_NAME" width-type)
           (string-property-line "ADD_STYLE_NAME" style-name)
           (property-line "PIXEL_SIZE" height)
           (property-line "POINT_SIZE" (* 10 height))
           (property-line "RESOLUTION_X" xres)
           (property-line "RESOLUTION_Y" +y-resolution+)
           (string-property-line "SPACING" "c")
           (string-property-line "CHARSET_REGISTRY" "ISO10646")
           (string-property-line "CHARSET_ENCODING" "1")
           (property-line "CAP_HEIGHT" (- height (/ height 5) (/ height 10)))
           (property-line "X_HEIGHT" (/ height 2))
           (property-line "QUAD_WIDTH" width)
           (property-line "DEFAULT_CHAR" +default-character-code+)
           (ascent-line zipped-glyphs)
           (descent-line zipped-glyphs)
           (format nil "AVERAGE_WIDTH ~A" (* 10 width))
           "ENDPROPERTIES"
           (chars-line zipped-glyphs)))))

(defun character-start-line (unicode-hex)
  (format nil "STARTCHAR U+~A" unicode-hex))

(defun glyph-bbx-line (glyph)
  (let* ((width (aops:ncol glyph))
         (height (aops:nrow glyph))
         (descent (- (/ height 5))))
    (format nil "BBX ~d ~d ~d ~d" width height 0 descent)))

(defun swidth-value (device-width point-size x-resolution)
  "Return BDF SWIDTH for DEVICE-WIDTH at POINT-SIZE and X-RESOLUTION.

BDF stores scalable width in 1/1000ths of the point size.  The ideal
conversion back to device pixels is:
  swidth * point-size / 1000 * x-resolution / 72.
We choose the nearest integer scalable width for the generated cell advance."
  (floor (+ 1/2 (/ (* device-width 72000)
                   (* point-size x-resolution)))))

(defun build-character (zipped-glyph point-size x-resolution)
  (let* ((unicode-hex (hex-string zipped-glyph))
         (unicode-decimal (decimal-string-for-entry zipped-glyph))
         (glyph (cadr zipped-glyph))
         (device-width (aops:ncol glyph))
         (bitmap-lines (coerce (glyph-to-bdf-bitmap glyph) 'list)))
    (list (character-start-line unicode-hex)
          (format nil "ENCODING ~A" unicode-decimal)
          (format nil "SWIDTH ~d 0"
                  (swidth-value device-width point-size x-resolution))
          (format nil "DWIDTH ~d 0" device-width)
          (glyph-bbx-line glyph)
          "BITMAP"
          (newline-joined-string bitmap-lines)
          "ENDCHAR")))

(defun nil-hex-entry-p (zipped-glyph)
  (string-equal "NIL" (car zipped-glyph)))

(defun build-all-characters (zipped-glyphs point-size x-resolution)
  (newline-joined-string
   (mapcar #'newline-joined-string
           (mapcar (lambda (zipped-glyph)
                     (build-character zipped-glyph point-size x-resolution))
                   (remove-if #'nil-hex-entry-p zipped-glyphs)))))

(defun font-pathname (dist-root file-name)
  (dist-path dist-root
             (make-pathname :directory '(:relative "fonts" "bdf")
                            :name file-name
                            :type "bdf")))

(defun write-font (zipped-glyphs width-type style-name xres relative-width
                   &key (dist-root +default-dist-root+))
  (let* ((width (aops:ncol (cadar zipped-glyphs)))
         (height (aops:nrow (cadar zipped-glyphs)))
         (file-name (generate-file-name "DIGITAL" "VT220" width height
                                        width-type style-name xres
                                        relative-width))
         (pathname (font-pathname dist-root file-name)))
    (print (format nil "writing font: ~A" file-name))
    (ensure-directories-exist pathname)
    (with-open-file (stream pathname
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (format stream "~A"
              (newline-joined-string
               (list (build-header zipped-glyphs width-type style-name xres
                                   relative-width)
                     (build-all-characters zipped-glyphs height xres)
                     "ENDFONT"
                     ""))))))

(defun write-glyphs (glyphs width-type style-name xres relative-width
                     &key (dist-root +default-dist-root+))
  (write-font (zip-hexes-and-glyphs +hexes+ glyphs)
              width-type style-name xres relative-width
              :dist-root dist-root))

(defun scale-glyph-for-output (glyph size)
  (scale-height (scale-width glyph (car size))
                (cadr size)))

(defun write-glyphs-in-sizes (glyphs sizes width-type xres style-name
                              &key (dist-root +default-dist-root+))
  (dolist (size sizes)
    (write-glyphs (mapcar (lambda (glyph)
                            (scale-glyph-for-output glyph size))
                          glyphs)
                  width-type
                  style-name
                  xres
                  (caddr size)
                  :dist-root dist-root)))

(defun dec-set-pathname (dist-root)
  (dist-path dist-root "dec.set"))

(defun write-dec-set (&key (dist-root +default-dist-root+))
  (let ((pathname (dec-set-pathname dist-root)))
    (ensure-directories-exist pathname)
    (with-open-file (stream pathname
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create)
      (format stream "~A"
              (newline-joined-string
               (mapcar (lambda (hex-entry)
                         (format nil "U+~A # ~A"
                                 (car hex-entry)
                                 (cadr hex-entry)))
                       (remove-if (lambda (entry)
                                    (string-equal "NIL" (car entry)))
                                  +hexes+)))))))

(defun variant-glyphs (glyphs)
  "Return the four glyph variants written by the generator."
  (values
   (mapcar (compose #'stretch-glyph) glyphs)
   (mapcar (compose #'stretch-glyph #'double-width) glyphs)
   (mapcar (compose #'stretch-glyph #'append-last-column) glyphs)
   (mapcar (compose #'append-last-column
                    #'stretch-glyph
                    #'double-width
                    #'append-last-column)
           glyphs)))

(defun generate (&key (source-image +default-source-image+)
                   (dist-root +default-dist-root+))
  "Generate DEC font BDF files and dec.set using the original byte format."
  (validate-no-duplicate-hexes)
  (let* ((image (image-to-ternary-array source-image))
         (glyphs (character-cells image)))
    (multiple-value-bind (136-column-glyphs
                          136-column-double-glyphs
                          80-column-glyphs
                          80-column-double-glyphs)
        (variant-glyphs glyphs)
      (write-glyphs-in-sizes 136-column-glyphs +output-sizes+
                             "Normal" 75 "136col"
                             :dist-root dist-root)
      (write-glyphs-in-sizes 136-column-double-glyphs +output-sizes+
                             "Normal" 150 "136col"
                             :dist-root dist-root)
      (write-glyphs-in-sizes 80-column-glyphs +output-sizes+
                             "Normal" 75 "80col"
                             :dist-root dist-root)
      (write-glyphs-in-sizes 80-column-double-glyphs +output-sizes+
                             "Normal" 150 "80col"
                             :dist-root dist-root)
      (write-dec-set :dist-root dist-root)))
  (values))

(defun main (&key (source-image +default-source-image+)
               (dist-root +default-dist-root+))
  "Generate fonts with default repository-relative paths and print completion."
  (generate :source-image source-image :dist-root dist-root)
  (print "done")
  (values))
