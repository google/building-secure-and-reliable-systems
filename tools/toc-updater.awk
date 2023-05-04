#!/usr/bin/awk -f
#
# This script generates HTML content for the book's TOC.
#
# Usage:
#   $ awk -f tools/toc-updater.awk > raw/toc.html

# Expecting metadata to be in the local directory.
@include "html-metadata.awk"

BEGIN {
    d = 0;  # debug

    asort(metadata, ordered, "compare_by_order");

    print "<!DOCTYPE html>"
    print "<html lang=\"en\">"
    print "<head>"
    print "  <meta charset=\"utf-8\">"
    print "  <title>Building Secure and Reliable Systems</title>"
    print "  <link rel=\"stylesheet\" type=\"text/css\" href=\"theme/html/html.css\">"
    print "</head>"
    print "<body data-type=\"book\">"
    print "<nav xmlns=\"http://www.w3.org/1999/xhtml\" data-type=\"toc\">";
    print "<h1>Table of Contents</h1>";
    print "<p class=\"byline\">&nbsp;</p>";  # For vertical spacing consistent with other files.

    # The loop below creates <li> within the global <ul>, and indents section
    # headers within each file with additional levels of <ul>.
    print "<ul>"

    # Combine in this first static entry the two recognition pages the paper
    # book has before the TOC, so they weren't listed in the printed TOC.   
    print "  <li data-type=\"dedication\">";
    print "    <a href=\"praise.html\">Praise</a> and <a href=\"dedication.html\">Dedication</a>";
    print "  </li>";
    
    level = 0;
    for (i in ordered) {
	if (d) { print " ** level=" level ", order=" ordered[i]["order"]; }
	type = ordered[i]["type"];
	if (type ~ "sect") {
	    if (type ~ "sect[12]") {
		match(type, /[0-9]+/, matches);
		level_new = (matches[0] + 0);
	    } else {  # TOC omits sect3 and sect4, matching what's published.
		continue;
	    }
	} else if ("figure" == type || "indexterm" == type) {
	    continue;
	} else {
	    level_new = 0;
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
	anchor = "";  # For level 0 entries, link without anchors so docs open at the top.
	if (level_new > 0) { anchor = "#" ordered[i]["id"]; }
	print "  <li data-type=\"" ordered[i]["type"] "\">";
	print "    <a href=\"" ordered[i]["filename"] anchor "\">" ordered[i]["toc"] "</a>";
	print "  </li>";
    }
    print "</ul>";

    print "</nav>";
    print "</body>";
    print "</html>";
}

function compare_by_order(i1, v1, i2, v2, l, r)
{
    l = (v1["order"] + 0)
    r = (v2["order"] + 0)

    if (l < r)
	return -1
    else if (l == r)
	return 0
    else
	return 1
}
