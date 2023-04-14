#!/usr/bin/awk -f
#
# This script updates <figcaption> HTML text to insert "Figure X-Y" in
# front of the of existing caption, matching what's in the publinhed PDF.  
#
# Usage:
# $ awk -f tools/figcaption-updater.awk -- raw/ch08.html
# $ tools/find-html.sh | while read f; do awk -f tools/figcaption-updater.awk $f > $f.upd; done
# $ tools/find-html.sh | while read f; do awk -f tools/figcaption-updater.awk $f > $f.upd; mv $f.upd $f; done

# Expecting metadata to be in the local directory.
@include "html-metadata.awk"

BEGIN {
    RS = "</figure>"  # Iterate over links rathar than lines of text.
    d = 0;  # debug
}
END { }

# Match blocks ending with the </figure>, so we can be sure to find <figcaption>.
{
    source = $0 RT  # We'll printf this verbatim when not updating the block. 

    # Get the id= of the figure, so we can lookup metadata.
    match(source, /\<figure id="([^"]+)"/, matches);
    id = matches[1];
    if (d > 1) { print "  figure id found: '" id "' in " source; print "O:"; print ""; } 
    # Confirm we have the metadata.
    if (!(id in metadata)) {
	if (d) { print "  skipping figure id '" id "' not in metadata (OK when RT is empty: '" RT "')"; }
	printf("%s", source); next;
    }

    updated = source

    # Replace the HTML text in the <figcaption>; this happens unconditionally. 
    regexp    = "<figcaption>";
    text_updated = regexp metadata[id]["text"] ": ";
    updated = gensub(regexp, text_updated, "g", updated);

    # Replace the alt text in the <img>; this happens unconditionally. 
    regexp    = "<img src=\"" metadata[id]["filename"] "\" alt=\"";
    text_updated = regexp metadata[id]["text"] ": ";
    updated = gensub(regexp, text_updated, "g", updated);
    regexp    = "<img alt=\"";  # A more sloppy option for cases where src= comes last.
    text_updated = regexp metadata[id]["text"] ": ";
    updated = gensub(regexp, text_updated, "g", updated);

    printf("%s", updated);
}
