for filename in ./dist/fonts/bdf/*.bdf; do
    # echo "$(basename "$filename" .bdf)"
    echo "making bold $filename"
    mkbold $filename > $(echo $filename | sed s/col/col-Bold/ )
    echo "making italic $filename"
    mkitalic $filename > $(echo $filename | sed s/col/col-Italic/ )
    echo "making bolditalic $filename"
    mkbolditalic $filename > $(echo $filename | sed s/col/col-BoldItalic/ )
    echo "converting $filename to otb"
    fonttosfnt -o "./dist/fonts/otb/$(basename "$filename" .bdf).otb" "$filename"
    echo "converting $filename to psf"
    bdf2psf --fb "$filename" /usr/share/bdf2psf/standard.equivalents ./dist/dec.set 256 "./dist/fonts/psf/$(basename "$filename" .bdf).psf"  > /dev/null 2>&1
done
