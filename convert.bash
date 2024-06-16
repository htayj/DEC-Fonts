for filename in ./dist/fonts/bdf/*.bdf; do
    # echo "$filename"
    # echo "$(basename "$filename" .bdf)"
    fonttosfnt -o "./dist/fonts/otb/$(basename "$filename" .bdf).otb" "$filename"
    bdf2psf --fb "$filename" /usr/share/bdf2psf/standard.equivalents ./dist/dec.set 256 "./dist/fonts/psf/$(basename "$filename" .bdf).psf" 
done
