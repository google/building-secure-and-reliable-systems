#!/usr/bin/awk -f
#
# This script generates HTML content for the book's Index.
#
# Usage:
#   $ awk -f tools/index-updater.awk -- raw/ch08.html > raw/ix.html
#   $ awk -f tools/index-updater.awk -- $(tools/find-html.sh) > raw/ix.html

# Expecting metadata to be in the local directory.
@include "html-metadata.awk"

BEGIN {
    figure_id = "";
    section_id = "";

    order_id = 0;  # Combined with find-html.sh, tracks the ordering for TOC.

    filename = "";

    d = 0;  # debug

    RS = "</a>";
}

BEGINFILE {
    # In the filename, omit any leading path since the HTML uses local directory references.
    filename = gensub(/(.*\/)([a-z_]+[0-9]*\.html)/, "\\2", "g", FILENAME);
}

{
    source = $0 RT  # We'll printf this verbatim when not updating the block. 

    match(source, /(<a .+<\/a>)/, matches);
    a = matches[1];

    if (!match(a, /data-type="indexterm"/, foos)) {
	next;  # Skip <a> that aren't indexterm.
    }  
    if (d > 1) { print "  *** A: " a; }

    data_pri = "";
    data_sec = "";
    data_sta = "";
    data_id = "";
    
    # Find the indexterm's attributes we are tracking.
    if (match(a, / data-primary="([^"]+)"/, parts)) { data_pri = parts[1]; }
    if (match(a, / data-secondary="([^"]+)"/, parts)) { data_sec = parts[1]; }
    if (match(a, / data-startref="([^"]+)"/, parts)) { data_sta = parts[1]; }
    if (match(a, / id="([^"]+)"/, parts)) { data_id = parts[1]; }
    # Empirical observations about the content:
    #  - primary with or without secondary are a norm.
    #    - with id (339) vs. without id (1181).
    #    - without secondary (657) and also without id (555).
    #  - none of secondary without primary.
    #  - id and startref are mutually exclusive when set.
    #    - either way (339), meaning there's a match (start and end?). 

    if (d) {
	if (!data_pri && data_sec) {
	    printf("  ** a=%20s, b=%20s, c=%60s, d=%60s \n", data_id, data_sta, data_pri, data_sec);
	}
    }

    # Because secondary newer appear without primary, concatenate them for sorting.
    ref[data_pri "/" data_sec]["id"] = data_id;
    ref[data_pri "/" data_sec]["startref"] = data_sta;
    ref[data_pri "/" data_sec]["filename"] = filename;
    ref[data_pri "/" data_sec]["primary"] = data_pri;
    ref[data_pri "/" data_sec]["secondary"] = data_sec;
    ref[data_pri "/" data_sec]["order"] = data_pri "/" data_sec;
}

END {
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

    # The loop below creates <li> within the global <ul>, and indents section
    # headers within each file with additional levels of <ul>.

    #print "<ul>"

    level = 0;
    letter = "";
    primary = "";
    
    for (i in ordered) {
	data_pri = ordered[i]["primary"];
	data_sec = ordered[i]["secondary"];
	data_sta = ordered[i]["startref"];
	data_id = ordered[i]["id"];
	if (d) {
	    printf("  @@ level=%s,  a=%20s, b=%20s, c=%60s, d=%60s \n", level, data_id, data_sta, data_pri, data_sec);
	}
	
	if (data_pri) {
	    letter_new = toupper(substr(data_pri, 1, 1));
	    if (letter_new != letter) {
		# Advance the letter to the new letter.
		while (level > 0) {
		    print "  </ul>";
		    level = level - 1;
		}
		print "  <h3>" letter_new "</h3>";
		letter = letter_new;
	    }
	}

	text = "FIXME";
	if (data_pri != primary) {
	    level_new = 0;  # Reset level when primary changes.
	    text = data_pri;
	} else {
	    if (data_sec) {
		level_new = 1;  # Indent under primary only if we have secondary.
		text = data_sec;
	    }
	}  
	if (d) { print " ** level_new=" level_new; }
	while (level > level_new) {  # e.g. when level_new chapter follows level sect2.
	    print "  </ul>";
	    level = level - 1;
	}
	while (level < level_new) {  # e.g. when level_new sect2 follows level sect1.
	    print "  <ul>";
	    level = level + 1;
	}
	print "  <li>" text "</li>";

	primary = data_pri;
    }
    #print "</ul>";

    print "</body>";
    print "</html>";
}

function compare_by_order(i1, v1, i2, v2, l, r)
{
    l = (v1["order"])
    r = (v2["order"])

    if (l < r)
	return -1
    else if (l == r)
	return 0
    else
	return 1
}
