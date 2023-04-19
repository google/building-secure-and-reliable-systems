#!/usr/bin/awk -f
#
# This script updates <a> href values and HTML text to replace #anchor
# raw values with the text matching what's in the publinhed PDF.  
#
# Usage:
# $ awk -f tools/href-updater.awk -- raw/ch08.html
# $ tools/find-html.sh | while read f; do awk -f tools/href-updater.awk $f > $f.upd; done
# $ tools/find-html.sh | while read f; do awk -f tools/href-updater.awk $f > $f.upd; mv $f.upd $f; done

# Expecting metadata to be in the local directory.
@include "html-metadata.awk"

BEGIN {
    RS = "</a>";  # Iterate over links rathar than lines of text.
    wrap_html = 0;  # We'll run this with 1 at most once, so default to 0.
    d = 0;  # debug
}
END { }


# Opportunistically insert into every HTML file the same HTML header and footer.
BEGINFILE {
    if (wrap_html) {
	print "<!DOCTYPE html>"
	print "<html lang=\"en\">"
	print "<head>"
	print "  <meta charset=\"utf-8\">"
	print "  <title>Building Secure and Reliable Systems</title>"
	print "  <link rel=\"stylesheet\" type=\"text/css\" href=\"theme/html/html.css\">"
	print "</head>"
	print "<body data-type=\"book\">"
    }
}
ENDFILE {
    if (wrap_html) {
	print "</body>";
	print "</html>";
    }
}

# Lines end with the <a> whose closing </a> is stored in RT.
{
    source = $0 RT;  # We'll printf this verbatim when not updating the block.

    if (wrap_html) { printf("%s", source); next; }  # For simplicity, wrap XOR edit.

    # Get just the <a>...</a>, for simplicity.
    match(source, /<a.+<\/a>/, matches);
    a = matches[0];
    if (d > 1) { print "<a>: " a; }

    # Get just the href= that point at #anchor (rather than anything else).
    match(a, /href=['"]#([^']+)['"]/, matches);
    href = matches[1];
    if (!href) {
	if (d > 1) { print "  skipping href isn't an #anchor: '" href "'"; }
	printf("%s", source); next;
    }
    # Confirm that we can proceed.
    match(a, />#([^\<]+)/, matches);
    text = matches[1];
    text_matched = (text != href)
    # Confirm we have the metadata.
    if (!(href in metadata)) {
	if (d) { print "  skipping href #" href " not in metadata"; }
	printf("%s", source); next;
    }

    id = href;  # A "rename", for convinience.
    if (d) { print "  found #" id " for updating " a; }

    updated = source;

    # First, an #anchor not to the local file needs to insert that file's name.
    # In the filename, omit any leading path since the HTML uses local directory references.
    filename_local = gensub(/(.*\/)([a-z]+[0-9]*\.html)/, "\\2", "g", FILENAME);
    if (d) { printf("filename='%s', local='%s'\n", metadata[id]["filename"], filename_local); }
    if (metadata[id]["filename"] != filename_local) {
        regexp = "href=['\"]#" id "['\"]";
	href_updated = "href='" metadata[id]["filename"] "#" id "'";
	updated = gensub(regexp,  href_updated, "g", updated);
    }
    # Second, replace the HTML text for the <a>; this happens only if text_matched.
    if (text_matched) {
	regexp    = ">#" id "<";
	text_updated = ">" metadata[id]["text"] "<"
	updated = gensub(regexp, text_updated, "g", updated);
    }

    printf("%s", updated);
}
