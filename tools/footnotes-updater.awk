#!/usr/bin/awk -f
#
# This script moves footnotes from their inlined positions to the bottom
# of each file.
#
# Usage:
# $ awk -f tools/footnotes-updater.awk -- raw/ch08.html
# $ tools/find-html.sh | while read f; do awk -f tools/footnotes-updater.awk $f > $f.upd; done
# $ tools/find-html.sh | while read f; do awk -f tools/footnotes-updater.awk $f > $f.upd; mv $f.upd $f; done

# This script doen't rely on @include "html-metadata.awk".

BEGIN {
    RS = "</span>"  # Iterate over footnote <span>.
    d = 0;  # debug
}

BEGINFILE {
    # Footnote counters reset for each HTML file.
    footnote_next = 1
    if (isarray(footnotes)) { delete footnotes; }
}

# Match blocks ending with the </span>, so we can be sure to find <figcaption>.
{
    source = $0 RT  # We'll printf this verbatim when not updating the block. 

    # Get the id of the footnote, otherwise skip this <span>.
    if (!match(source, /\<span data-type="footnote" id="([^"]+)"/, matches)) {
	if (d) { print "  skipping span without data-type=footnote (OK when RT is empty: '" RT "')"; }
	printf("%s", source); next;
    }
    id = matches[1];

    # Prepare the noteref that will go in place of the footnote.
    noteref = sprintf("<sup><a data-type=\"noteref\" id=\"%s-marker\" href=\"#%s\">%s</a></sup>", id, id, footnote_next);
    if (d > 1) { print "  noteref : " noteref; } 

    # Find the footnote we'll be replacing with the noteref, but also editing and placing at HTML end.
    span_regexp = sprintf("<span data-type=\"footnote\" id=\"%s\">(.+)</span>$", id);
    match(source, span_regexp, matches);
    span = matches[0];
    text = matches[1];
    footnote = sprintf("<p data-type=\"footnote\" id=\"%s\"><sup><a href=\"#%s-marker\">%s</a></sup>%s</p>", id, id, footnote_next, text);
    if (d > 1) { print "  footnote: " footnote; } 

    footnotes[footnote_next] = footnote;
    
    updated = source

    # Replace the footnote HTML with the noteref HTML. 
    text_updated = regexp metadata[id]["text"] ": ";
    updated = gensub(span_regexp, noteref, "g", updated);

    printf("%s", updated);

    if (text ~ /\<span/) {
	# WARNING: The span_regexp approach doesn't work for footnotes with
	# <span> inside the footnote, but the book only few such footnotes,
	# and it's cheaper to just fix them manually. Tag such places.
	printf ("(FIXME:id=%s)", id);
    }

    footnote_next += 1;
}

ENDFILE {
    print "<div data-type=\"footnotes\">";
    for (i in footnotes) { print footnotes[i]; }
    print "</div>";
}

