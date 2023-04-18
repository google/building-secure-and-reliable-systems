#!/usr/bin/bash
#
# This script orders HTML files to match what's in the publushed book's TOC.
#
# Usage:
#   $ tools/find-html.sh

# The list below was copied from atlas.json, with the following omitted
# because they don't need auto-editing or being listed in the TOC.
    # "cover.html" \
    # "titlepage.html" \
    # "copyright.html" \
    # "toc.html" \
    # "colo.html" \

for f in \
    "praise.html" \
    "dedication.html" \
    "foreword01.html" \
    "foreword02.html" \
    "pr01.html" \
    "part1.html" \
    "ch01.html" \
    "ch02.html" \
    "part2.html" \
    "ch03.html" \
    "ch04.html" \
    "ch05.html" \
    "ch06.html" \
    "ch07.html" \
    "ch08.html" \
    "ch09.html" \
    "ch10.html" \
    "part3.html" \
    "ch11.html" \
    "ch12.html" \
    "ch13.html" \
    "ch14.html" \
    "ch15.html" \
    "part4.html" \
    "ch16.html" \
    "ch17.html" \
    "ch18.html" \
    "part5.html" \
    "ch19.html" \
    "ch20.html" \
    "ch21.html" \
    "ch22.html" \
    "appa.html" \
    "ix.html" \
    "author_bio.html"; do
    echo "raw/$f";
done

# To see files missing in the above list, run:
#   $ find raw/ -type f -name '*.html' | sort | wc -l
