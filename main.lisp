(ql:quickload "png")
(ql:quickload :array-operations)
;; https://man.archlinux.org/man/xterm.1#forceBoxChars
;; need unicode points: 0x00d7, 0x2019 0x252C, 201c, 201d
(defvar hexes '())
(setq hexes
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

(defun 2d-array-to-list (array)
  (loop for i below (array-dimension array 0)
        collect (loop for j below (array-dimension array 1)
                      collect (aref array i j))))



;; requires split/combine
(defun mapa (function array &optional (retval (make-array (array-dimensions array))))
  (dotimes ( i (array-dimension array 0) retval )
    (setf (aref retval i)
          (funcall function (aref array i) i))))

;; maps over first dimension of an array
(defun maparray (function array )
  (aops:combine (mapa function 
                      (aops:split array 1 ))))

;; concat arrays
(defun cona (array array2) (let ((a2vec (aops:split array2 1))) (maparray #'(lambda (a i) (concatenate 'vector a (aref a2vec  i))) array) ))


(defun array-element-map (function array
                          &optional (retval (make-array (array-dimensions array))))
  "Apply FUNCTION to each element of ARRAY.
Return a new array, or write into the optional 3rd argument."
  (dotimes (i (array-total-size array) retval)
    (setf (row-major-aref retval i)
          (funcall function (row-major-aref array i)))))

(defun red-to-type (red)
  (cond
    ((> red 245) 2 )
    ((> red 200) 0)
    (t 1)))
(defun type-to-vis (type)
  (cond
    ((= type 1 ) '▉)
    ((= type 0 ) '░)
    ((= type 2 ) '▒)))

(defun colors-to-red (colors)
  (aref colors 0))

(defun imageToTernArray (input-pathname)
  "reads in an image and turns it into an array of 0, 1, or 2
0: spacing
1: background
2: letter"
  (let* ((image
           (with-open-file
               (input input-pathname :element-type '(unsigned-byte 8))
             (png:decode input))))
    (array-element-map #'red-to-type (array-element-map #'colors-to-red (aops:split image 2)))))

(defun pretty-print (type2d)
  (format nil "~{~A~%^~}"
          (coerce 
           (array-element-map
            #'(lambda (cells)
                (format nil "~{~A~^~}" cells))
            (array-element-map #'(lambda (arr) (coerce arr 'list))
                               (aops:split
                                (array-element-map
                                 #'type-to-vis
                                 type2d) 
                                1)))
           'list)))


;;; ==================================
;;; test data for reference
;;; ==================================
;; "
;; ░░░░░░░░
;; ▉░░░░░░░
;; ▉░░░░░░░
;; ▉░▉▉▉▉░░
;; ▉▉░░░░▉░
;; ▉░░░░░▉░
;; ▉▉░░░░▉░
;; ▉░▉▉▉▉░░
;; ░░░░░░░░
;; ░░░░░░░░"

;; '(
;;   '(0 0 0 0 0 0 0 0)
;;   '(1 0 0 0 0 0 0 0)
;;   '(1 0 0 0 0 0 0 0)
;;   '(1 0 1 1 1 1 0 0)
;;   '(1 1 0 0 0 0 1 0)
;;   '(1 0 0 0 0 0 1 0)
;;   '(1 1 0 0 0 0 1 0)
;;   '(1 0 1 1 1 1 0 0)
;;   '(0 0 0 0 0 0 0 0)
;;   '(0 0 0 0 0 0 0 0)
;;   )

;; (defvar b (make-array '(11 8) :initial-contents '(
;;                                                   (2 2 2 2 2 2 2 2)
;;                                                   (0 0 0 0 0 0 0 0)
;;                                                   (1 0 0 0 0 0 0 0)
;;                                                   (1 0 0 0 0 0 0 0)
;;                                                   (1 0 1 1 1 1 0 0)
;;                                                   (1 1 0 0 0 0 1 0)
;;                                                   (1 0 0 0 0 0 1 0)
;;                                                   (1 1 0 0 0 0 1 0)
;;                                                   (1 0 1 1 1 1 0 0)
;;                                                   (0 0 0 0 0 0 0 0)
;;                                                   (0 0 0 0 0 0 0 0)
;;                                                   )
;;                       ))
;; (setq b (make-array '(11 8) :initial-contents '(
;;                                                 (2 2 2 2 2 2 2 2)
;;                                                 (0 0 0 0 0 0 0 0)
;;                                                 (1 0 0 0 0 0 0 0)
;;                                                 (1 0 0 0 0 0 0 0)
;;                                                 (1 0 1 1 1 1 0 0)
;;                                                 (1 1 0 0 0 0 1 0)
;;                                                 (1 0 0 0 0 0 1 0)
;;                                                 (1 1 0 0 0 0 1 0)
;;                                                 (1 0 1 1 1 1 0 0)
;;                                                 (0 0 0 0 0 0 0 0)
;;                                                 (0 0 0 0 0 0 0 0)
;;                                                 )
;;                     ))

(defun spacingp (row)
  (every #'(lambda (cell) (= cell 2) ) row))



;;; ============================================
;;; Time to extract the cells from the image
;;; ============================================
;; file is 16 char tall
;; 18 char wide
;; top pad 2px
;; left pad 1px
;; 2 px pad between rows
;; 2px pad between cols
(defvar numcol 18)
(defvar numrow 16)
(defvar cell-height 10)
(defvar cell-width 8)
(defvar cell-col-pad 2)
(defvar cell-row-pad 2)
(defvar y-offset 2)
(defvar x-offset 1)
(setq x-offset 1)
(defun get-cell (array startx starty width height)
  (aops:combine (array-element-map
                 #'(lambda
                       (row)
                     (aops:partition row startx (+ startx width)))
                 (aops:split
                  (aops:partition array  starty (+ starty height))
                  1 ))))
(defun y-coords (yindex cell-height cell-row-pad y-offset)
  (+ y-offset (* yindex (+ cell-height cell-row-pad))))

(defun x-coords (xindex cell-width cell-col-pad y-offset)
  (+ x-offset (* xindex (+ cell-width cell-col-pad))))


(defun get-cell-by-xy (x y cell-height cell-width cell-col-pad cell-row-pad x-offset y-offset)
  (get-cell (imagetoternarray "./rom-separated_extended.png")
            (x-coords x cell-width cell-col-pad y-offset)
            (y-coords y cell-height cell-row-pad y-offset)
            8
            10))

(defun get-cell-by-index (i numcol numrow cell-height cell-width cell-col-pad cell-row-pad x-offset y-offset)
  (let ((colnum (floor i numrow))
        (rownum (mod i numrow)))
    (get-cell-by-xy colnum rownum cell-height cell-width cell-col-pad cell-row-pad x-offset y-offset)))

(defvar char-list (loop for i below (* numcol numrow)
                        collect (get-cell-by-index i numcol numrow cell-height cell-width cell-col-pad cell-row-pad x-offset y-offset)))

(defun get-char-list (numcol numrow cell-height cell-width cell-col-pad cell-row-pad x-offset y-offset)
  (loop for i below (* numcol numrow)
        collect (get-cell-by-index i numcol numrow cell-height cell-width cell-col-pad cell-row-pad x-offset y-offset)))


;;; =============================================================
;;; Now do the bit operations to make the characters look right
;;; =============================================================
(defun make-antishifted (char)
  (maparray #'(lambda (vec i)
                (concatenate 'vector  vec #(0) )) 
            char))
(defun make-shifted (char)
  (maparray #'(lambda (vec i)
                (concatenate 'vector #(0) vec )) 
            char))
(defun arr-or (big-arr little-arr)
  (maparray #'(lambda (vec i)
                (maparray #'(lambda (b j)
                              (let
                                  ( (pixp (or (= b 1) (= 1 (aref little-arr i j) )) )
                                    )
                                (if pixp
                                    1 0)))
                          vec )) 
            big-arr))

;; stretch using the bit-stretching of vt100
;; TODO: should not make the size change
(defun stretch-char (char)
  (arr-or (make-shifted char) (make-antishifted char )))


;; discrepency between instructions, vt100.net says to repeat x2.
;; But that would result in 11x10 instead of 10x10
;; Norbert Landsteiner says to repeat by 1,
;; which would result in 10x10, the correct dimensions
(defun fix-end (char)
  (let*
      ((flip-split 
         (aops:split 
          (flip char )
          1))
       (last-col
         (aref
          flip-split
          (- (aops:ncol char) 1))))
    (flip (aops:stack-rows (aops:combine flip-split)
                           last-col))))

(defun scale (x i &optional (counter 1) (acc '()))
  (if (> counter   i )
      acc
      (scale x
             i
             (+ counter 1) (if acc
                               (cons x acc)
                               (list x)))))
;; scale character by integer
(defun scale-width-vec (char fac)
  (reduce
   #'(lambda (acc curr)
       (concatenate 'vector acc curr))
   (maparray #'(lambda (x i) (scale x fac)) char)
   :initial-value #()))

(defun flip (matrix)
  (aops:permute '(1 0) matrix))

(defun scale-width (char fac)
  (maparray #'(lambda (vec i) (scale-width-vec vec fac)) char) )

(defun double-width (char )
  (scale-width char 2 ))

(defun scale-height (char fac)
  (flip (maparray #'(lambda (vec i) (scale-width-vec vec fac)) (flip char )) ))

(defun double-height (char )
  (scale-height char 2 ))

;;;;order of operations
;; fix edge wrap -- repeat last row (x2?)
;; double width if double width mode
;; stretch
;; double height to approx aspect ratio

(defun compose (&rest functions)
  "Compose FUNCTIONS right-associatively, returning a function"
  #'(lambda (x)
      (reduce #'funcall functions
              :initial-value x
              :from-end t)))

(defvar 136-col-chars (mapcar (compose #'double-height #'stretch-char) char-list))
(defvar 136-col-double-chars (mapcar (compose #'double-height #'stretch-char #'double-width) char-list))
(defvar 80-col-chars (mapcar (compose #'double-height #'stretch-char #'fix-end) char-list))
(defvar 80-col-double-chars (mapcar (compose #'double-height #'fix-end #'stretch-char #'double-width #'fix-end) char-list))

;;needs to be padded to reach a multiple of 8bits
(defun get-padding (char)
  (let 
      ((pad-needed (- 8 (mod
                         (aops:ncol char)
                         8) ))
       (height (aops:nrow char)))
    (aops:zeros (list height pad-needed))))
(defun pad-char (char)
  (cona char (get-padding char)))
(defun rows-to-string (char)
  (mapa #'(lambda (row i)
            (reduce #'(lambda (acc curr)
                        (concatenate 'string acc (format nil "~D" curr)))
                    row :initial-value ""))
        (aops:split char 1)))
(defun binstr-to-hex (str i)
  (format nil ( format nil "~~~A,'0X"  (floor (length str ) 4)) (parse-integer str :radix 2)))
(defun binchar-to-hex (char ) (mapa #'binstr-to-hex char))
(defun array-char-to-bdf-char (char)
  (binchar-to-hex (rows-to-string (pad-char char))))

(defun get-hex-string (char-cons)
  (car char-cons ))

;; check for duplicates
(defun tay-duplicates (lst &optional (acc '()))
  (let* ((this-item (car lst))
         (next-item (cadr lst))
         (rest-items (cdr lst))
         (new-acc (if (string-equal this-item next-item)
                      (cons this-item acc)
                      acc) )
         )
    (if rest-items (tay-duplicates rest-items new-acc) new-acc )))

(let( 
     (dupes (tay-duplicates (remove nil  (sort (mapcar #'get-hex-string hexes) #'string-lessp ) )) ) )
  (if dupes
      (print (format nil "duplicates detected: ~A" dupes ) ))
  )
(sort (mapcar #'get-hex-string hexes) #'string-lessp)

;; convert to bdf format



(defun get-dec-string (char-cons)
  (format nil "~d" (parse-integer (get-hex-string char-cons) :radix 16 ) ))

(defun hex-string-to-dec-string (hex-string)
  (format nil "~d" (parse-integer hex-string :radix 16 ) ))

(defun zip-hex-and-char (hex-list char-list &optional (combo  '()))
  (let ((char (car char-list))
        (hex (car hex-list)))
    (if (and (not char) (not hex))
        combo
        (zip-hex-and-char
         (cdr hex-list)
         (cdr char-list)
         (cons (list (get-hex-string hex) char)
               combo)))))


;;accoring to https://www.vt100.net/docs/vt100-tm/chapter1.html the aspect ratio is
;; 3.35 x 2.0. Unsure if that is height to width or width to height, but it seems likely
;; that it is height to width

;;; defining functions to help print to file
;; STARTPROPERTIES 2
;; FONT_ASCENT 14
;; FONT_DESCENT 2
;; ENDPROPERTIES

(defun get-size ( zipped )
  (let*
      ((height (aops:nrow (cadar zipped))))
    (format nil "SIZE ~d 75 75"  height )))

(defun get-bounding-box ( zipped )
  (let*
      ((width (aops:ncol (cadar zipped)))
       (height (aops:nrow (cadar zipped)))
       (descent (- (/ height 5) )))
    (format nil "FONTBOUNDINGBOX ~d ~d ~d ~d" width height 0 descent)))


(defun get-descent ( zipped )
  (let*
      ((height (aops:nrow (cadar zipped)))
       (descent (/ height 5) ))
    (format nil "FONT_DESCENT ~d"  descent )))

(defun get-ascent ( zipped )
  (let*
      ((height (aops:nrow (cadar zipped)))
       (descent (/ height 5) )
       (ascent (- height descent)))
    (format nil "FONT_ASCENT ~d"  ascent )))

(defun get-chars (zipped)
  (format nil "CHARS ~d" (length zipped) ))

;; convert list to file string
(defun to-nl-string ( string-list )
  (format nil "~{~A~^~%~}" string-list))

(defun generate-file-name (foundry face width height width-type style-name &optional rel-width)
  (format nil
          "~A-~A-~A-~A-~Ax~A"
          foundry
          face
          width-type
          style-name
          width
          height))
(defun generate-font-name (foundry face width height width-type style-name &optional rel-width)
  (format nil
          "-~A-~A-medium-r-~A-~A-~A-~A-75-75-c-~A-iso10646-1~A"
          foundry
          face
          width-type
          style-name
          height
          (* 10 height)
          (* width 10)
          (if rel-width
              (format nil "-relwidth~A" rel-width)
              "")))

(defun create-string-prop (key val)
  (format nil "~A \"~A\"" key val))
(defun create-prop (key val)
  (format nil "~A ~A" key val))

;; build the font header
(defun build-header (zipped width-type style-name rel-width)
  (let* ((width (aops:ncol (cadar zipped)))
         (height (aops:nrow (cadar zipped)))
         (descent (- (/ height 5) )))
    (to-nl-string (list "STARTFONT 2.1"
                        (format nil "FONT ~A" (generate-font-name 'DIGITAL 'vt220 width height width-type style-name)) ;;fixme -medium-r-normal--16-160-75-75-c-80-iso10646-1
                        (get-size zipped)
                        (get-bounding-box zipped)
                        "STARTPROPERTIES 21"
                        ;; (create-string-prop 'fontname_registry "")
                        (create-string-prop 'foundry "DIGITAL")
                        ;; if the xlfd properties dont work correctly
                        ;;(create-string-prop 'family_name (format nil "vt220_~A_~A_rwidth~A" style-name width-type rel-width )) 
                        (create-string-prop 'family_name "vt220")
                        (create-string-prop 'weight_name "medium")
                        (create-prop 'relative_setwidth rel-width)
                        (create-string-prop 'slant "r")
                        (create-string-prop 'setwidth_name width-type)
                        (create-string-prop 'add_style_name style-name)
                        (create-prop 'pixel_size height)
                        (create-prop 'point_size (* 10 height ))
                        (create-prop 'resolution_x 75)
                        (create-prop 'resolution_y 75)
                        (create-string-prop 'spacing "c")
                        (create-string-prop 'charset_registry "ISO10646")
                        (create-string-prop 'charset_encoding "1")
                        (create-prop 'cap_height (- height (/ height 5) (/ height 10)))
                        (create-prop 'x_height (/ height 2))
                        (create-prop 'weight 10)
                        (create-prop 'quad_width width)
                        ;; (create-prop 'default_char 9670)
                        (get-ascent zipped)
                        (get-descent zipped)
                        (format nil "AVERAGE_WIDTH ~A" (* 10 width))
                        "ENDPROPERTIES"
                        (get-chars (remove nil  (sort (mapcar #'get-hex-string hexes) #'string-lessp ) ))) ) ))
(defun char-start (unihex)
  (format nil "STARTCHAR U+~A" unihex))

(defun get-bbx ( raw-char )
  (let*
      ((width (aops:ncol raw-char))
       (height (aops:nrow raw-char))
       (descent (- (/ height 5) )))
    (format nil "BBX ~d ~d ~d ~d" width height 0 descent)))

;;;; building character
(defun build-char (zipped-char)
  (let* ((unihex (get-hex-string zipped-char))
         (unidec (get-dec-string zipped-char))
         (char-raw (cadr zipped-char))
         (char-bit (coerce (array-char-to-bdf-char char-raw) 'list)))
    (list (char-start unihex)
          (format nil "ENCODING ~A" unidec)
          "SWIDTH 1000 0"
          (format nil "DWIDTH ~d 0" (aops:ncol char-raw))
          (get-bbx char-raw)
          "BITMAP"
          (to-nl-string char-bit)
          "ENDCHAR")))


;; build all characters
(defun build-all-chars (zipped-chars)
  (to-nl-string
   (mapcar #'to-nl-string (mapcar #'build-char
                                  (remove-if #'(lambda (x)
                                                 (string-equal "NIL"
                                                               (car x) ))
                                             zipped-chars)))))


;; build complete file
(defun write-font (zipped-hex-chars width-type style-name rel-width)
  (let* ((width (aops:ncol (cadar zipped-hex-chars)))
         (height (aops:nrow (cadar zipped-hex-chars)))
         (descent (- (/ height 5) )))
    (print (format nil "writing font: ~A" (generate-file-name 'DIGITAL 'vt220 width height width-type style-name rel-width)))
    (with-open-file (str (format nil "./dist/fonts/bdf/~A.bdf" (generate-file-name 'DIGITAL 'vt220 width height width-type style-name rel-width))
                         :direction :output
                         :if-exists :supersede
                         :if-does-not-exist :create)
      (format str "~A" (to-nl-string (list (build-header zipped-hex-chars width-type style-name rel-width)
                                           (build-all-chars zipped-hex-chars)
                                           "ENDFONT"
                                           ""))))))

(defun write-chars (chars width-type style-name rel-width)
  (write-font (zip-hex-and-char hexes chars) width-type style-name rel-width ))

;; size is (xscale yscale)
(defun write-chars-in-sizes (chars sizes width-type col-num)
  (mapcar #'(lambda (size)
              (write-chars (mapcar #'(lambda (char)
                                       (scale-height (scale-width char (car size))
                                                     ( cadr size ) ))
                                   chars)
                           width-type
                           col-num
                           (caddr size)))

          sizes))

;; read and process file
;; split into 136 vs 80 col
;; split into double and normal width
;; zip with unicode point
;; output to file

(defun get-relative-width (width height)
  (cond
    ((eq height width) 90)
    ((eq (/ height width) 2) 50)
    ((eq (/ height width) 3) 50)
    )
  )
(eq (/ 4 3) 2)
4/3
(caddr '(1 2 3 4))
(let* ((char-list (get-char-list numcol numrow cell-height cell-width cell-col-pad cell-row-pad x-offset y-offset ))
       ;; uncomment this line to get more sizes. However, I dont use them and they interferre with font selection enough to be annoying
       ;; (sizes '((1 1 90) (1 2 50) (1 3 10) 
       ;;          (2 2 90) (2 3 70) (2 4 50) (2 5 30) (2 6 10)
       ;;          (3 3 90) (3 4 80) (3 5 70) (3 6 50) (3 7 40) (3 9 30)
       ;;          (4 4 90) (4 5 80) (4 6 70) (4 7 60) (4 8 50) (4 9 40) (4 10 30) (4 11 20) (4 12 10)
       ;;          (5 5 90) (5 6 80) (5 8 70 ) (5 9 60) (5 10 50) (5 12 40) (5 15 30) (5 18 20) (5 20 10)))
       (sizes '((1 2 50)
                (2 4 50)
                (3 6 50)
                (4 8 50) 
                (5 10 50)))
       (136-col-chars (mapcar (compose #'stretch-char) char-list))
       (136-col-double-chars (mapcar (compose #'stretch-char #'double-width) char-list))
       (80-col-chars (mapcar (compose #'stretch-char #'fix-end) char-list))
       (80-col-double-chars (mapcar (compose #'fix-end #'stretch-char #'double-width #'fix-end) char-list)))
  (write-chars-in-sizes 136-col-chars sizes "Normal" "136col")
  (write-chars-in-sizes 136-col-double-chars sizes "Wide" "136col")
  (write-chars-in-sizes 80-col-chars sizes "Normal" "80col")
  (write-chars-in-sizes 80-col-double-chars sizes "Wide" "80col"))




;; (mapcar #'pretty-print (mapcar (lambda (char) (double-width char) )  char-list ))
;; (mapcar #'pretty-print  char-list)

;; write the char set
(with-open-file (str "./dist/dec.set" 
                     :direction :output
                     :if-exists :supersede
                     :if-does-not-exist :create)
  (format str "~A" (to-nl-string (mapcar #'(lambda (hex-pair) (format nil "U+~A # ~A" (car hex-pair) (cadr hex-pair))) (remove-if #'(lambda (x)
                                                                                                                                      (string-equal "NIL"
                                                                                                                                                    (car x) ))
                                                                                                                                  hexes))) ))

(print "done")
