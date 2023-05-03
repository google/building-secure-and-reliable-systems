#!/usr/bin/awk -f
#
# This script generates HTML content for the book's Index.
#
# Usage:
#   $ awk -f tools/index-updater.awk -- raw/ch08.html > raw/ix.html
#   $ awk -f tools/index-updater.awk -- $(tools/find-html.sh) > raw/ix.html
# (in edit mode):
#   $ awk -f tools/index-updater.awk -- raw/ch08.html > raw/ch08.html.upd
#   $ tools/find-html.sh | while read f; do awk -f tools/index-updater.awk $f > $f.upd; mv $f.upd $f; done

# Empirical observations about indexterm entries in the HTML content:
#  (1) primary with or without secondary are a norm.
#    - with id (339) vs. without id (1181).
#    - without secondary (657) and also without id (555).
#  (2) none of secondary without primary.
#  (3) id and startref are originally mutually exclusive (XOR).
#    - either way (339), meaning there's a match (start and end?).
#    - (!!) but our edit mode will change this XOR.
#

BEGIN {
    RS = "</a>";
    eot[""] = "";  # The end-of-term map.

    e = 0;  # edit
    d = 0;  # debug
}

BEGINFILE {
    # In the filename, omit any leading path since the HTML uses local directory references.
    filename = gensub(/(.*\/)([a-z_]+[0-9]*\.html)/, "\\2", "g", FILENAME);
    id_new_counter = 1;  # When we make new id= values, use this counter (per-file).
}

{
    source = $0 RT  # We'll printf this verbatim when not updating the block. 

    match(source, /(<a .+<\/a>)/, matches);
    a = matches[1];
    # Skip <a> that aren't indexterm.
    if (!match(a, /data-type="indexterm"/, foos)) {
	if (e) { printf("%s", source); }
	next;
    }  
    if (d > 1) { print "  *** D: " a; }

    # Find the indexterm's attributes we are tracking.
    data_pri = "";
    data_sec = "";
    data_sta = "";
    data_id = "";
    if (match(a, / data-primary="([^"]+)"/, parts)) { data_pri = parts[1]; }
    if (match(a, / data-secondary="([^"]+)"/, parts)) { data_sec = parts[1]; }
    if (match(a, / data-startref="([^"]+)"/, parts)) { data_sta = parts[1]; }
    if (match(a, / id="([^"]+)"/, parts)) { data_id = parts[1]; }

    if (d) {
	printf("  *** D: a=%20s, b=%20s, c=%60s, d=%60s \n", data_id, data_sta, data_pri, data_sec);
    }

    if (e) {
	updated = source;
	# For startref entries without an id, insert id="$x-eot" for $x from data-startxref.
	if (data_sta && !data_id) {
	    # If we haven't upgraded startref-only indexterm to add id=, we'll do so now.
	    # This way, HTML will have #anchors for the "ending place for an indexed term".
	    regexp = " data-startref=\"" data_sta "\"";
	    text_updated = " id=\"" data_sta "-eot\"" regexp  # Append "-eot" (end-of-term).
	    updated = gensub(regexp, text_updated, "g", updated);
	}
	# For primary (with or without secondary) entries that have no id (!data_sta indicates
	# such entries), generate an id to make the indexterm addressable via an #anchor.
	if (!data_sta && !data_id) {
	    # If we haven't upgraded startref-only indexterm to add id=, we'll do so now.
	    # This way, HTML will have #anchors for the "ending place for an indexed term".
	    # New id= values are similar to the existing ones, but use "_ix" to separate
	    # the counter and avoid collisions with the existing id= values.
	    regexp = "data-type=\"indexterm\"";
	    text_updated = regexp " id=\"" filename "_ix" id_new_counter "\""
	    updated = gensub(regexp, text_updated, "g", updated);
	    id_new_counter += 1;
	}
	printf("%s", updated);
	next;
    }

    # Enable lookup of the EOT id by the intexterm's main id.
    if (data_sta && data_id) {
	eot[data_sta] = data_id  # This "id" has the "-eot" suffix, per the edit mode.
    }

    # The same indexterm may pount at multiple page ranges, so dedup them.
    seen_count = 1;
    order = data_pri "/" seen_count "/" data_sec;
    while (order in ref) {
	seen_count += 1;
	order = data_pri "/" seen_count "/" data_sec;
    }

    # Store in the ref map this indexterm's details needed for generating ix.html.
    # Because indexterm never have a secondary without a primary, concatenate for sorting.
    ref[order]["id"] = data_id;
    ref[order]["startref"] = data_sta;
    ref[order]["filename"] = filename;
    ref[order]["primary"] = data_pri;
    ref[order]["secondary"] = data_sec;
    ref[order]["order"] = order;  # For the sorting function.
}

END {
    if (e) { exit; }  # We don't write anything extra while in edit mode.

    asort(ref, ordered, "compare_by_order");

    print "<!DOCTYPE html>"
    print "<html lang=\"en\">"
    print "<head>"
    print "  <meta charset=\"utf-8\">"
    print "  <title>Building Secure and Reliable Systems</title>"
    print "  <link rel=\"stylesheet\" type=\"text/css\" href=\"theme/html/html.css\">"
    print "</head>"
    print "<body data-type=\"book\">"
    print "<section data-type=\"index\" id=\"index\" xmlns=\"http://www.w3.org/1999/xhtml\">";
    print "<h1>Index</h1>";

    # First, generate the header that links to individual letters.
    # Letters A-Z (ASCII codes 65-90 decimal) split into two rows.
    print "<p class=\"ix_toc\">";
    for (l = 65; l <= 90; l++) {
	printf("  <a href=\"#ix_%c\">%c</a>\n", l, l);
    }
    print "</p>";

    letter = "";  # Separate index sections by the starting letter.
    primary = "";  # So we know whether to indent indexterm with the same primary, as
    secondary = "";  # well as whether we have a repeat references for the last term.
    level = 0;  # Level of indenting (1 for each secondary with the same primary).
    entries = 0;

    for (i in ordered) {
	data_pri = ordered[i]["primary"];
	data_sec = ordered[i]["secondary"];
	data_sta = ordered[i]["startref"];
	data_id = ordered[i]["id"];

	# As explained above, indexterm entries without both primary and secondary
	# labels are used only as markers of the end of an indexterm's mention.
	if (data_pri == "" && data_sec == "") { continue; }

	same_term = (data_pri == primary && data_sec == secondary);
	# Closing <li> from the most recent term needs done before possibly starting
	# a new section for a new letter.
	if (entries && !same_term) {
	    if (entries) { print "</li>"; }
	}

	if (data_pri) {
	    letter_new = toupper(substr(data_pri, 1, 1));
	    if (letter_new != letter) {  # Advance the letter to the new letter.
		while (level > 0) {
		    print "  </ul>";
		    level = level - 1;
		}
		print "";
		print "  <h3 id=\"ix_" letter_new "\">" letter_new "</h3>";
		print "";
		letter = letter_new;
	    }
	}

	text = "FIXME";  # Helps spot weird issues in the generated content.

	# Determint indent level, and handle its changes.
	if (data_pri != primary) {
	    level_new = 0;  # Reset level when a primary changes.
	    text = data_pri;
	} else {
	    if (data_sec) {
		level_new = 1;  # Indent under a primary only if we have a secondary.
		text = data_sec;
	    } else {
		text = data_pri;  # We have a second instance of the previous term.
	    }
	}  
	while (level > level_new) {  # e.g. when level_new chapter follows level sect2.
	    print "  </ul>";
	    level = level - 1;
	}
	while (level < level_new) {  # e.g. when level_new sect2 follows level sect1.
	    print "  <ul>";
	    level = level + 1;
	}

	# Print the index entry.
	if (!same_term) {
	    if (level) printf("  ");
	    printf("  <li>%s", text);
	}
	if (data_id) {
	    a_href = ordered[i]["filename"] "#" ordered[i]["id"];
	    a_text = "start"  # gensub(/\.html/, "-", "g", ordered[i]["id"]);  # Replace ".html" in the middle.
	} else {
	    # Note: with the most recent edit mode changes, this branch won't be needed.
	    a_href = ordered[i]["filename"]  # Not anchor, unless we add id="" to all such indexterms.
	    a_text = "see"  # gensub(/\.html/, " ", "g", ordered[i]["filename"]);  # Trim ".html".
	}
	# Append the <a> referencing to where the indexterm is defined.
	# If there's an EOT entry, add the " - [end]" to point at the end-of-term.
	printf(", <a href='%s'>%s</a>", a_href, a_text);
	if (data_id && (data_id in eot)) {
	    a_href = ordered[i]["filename"] "#" eot[data_id];
	    printf("-<a href='%s'>end</a>", a_href);
	}

	primary = data_pri;
	secondary = data_sec;
	entries += 1;
    }
    print "</li>";  # The lazy assumption that the index is not empty.

    print ""
    print "<!-- Index generated by tools/index-updater.awk, has " entries " entries. -->";
    print ""
    print "</body>";
    print "</html>";
}

function compare_by_order(i1, v1, i2, v2, l, r)
{
    l = (tolower(v1["order"]))
    r = (tolower(v2["order"]))

    if (l < r)
	return -1
    else if (l == r)
	return 0
    else
	return 1
}
