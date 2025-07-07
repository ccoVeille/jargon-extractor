#!/bin/bash

if [ $# -eq 0 ]; then
	echo "Usage: $0 <directory-or-file> [more-directories-or-files...]"
	echo "Scans markdown files for jargon candidates based on word capitalization."
	exit 1
fi

# Ensure required commands are installed
for cmd in fd awk grep wc xargs tr md5sum; do
	if ! command -v "$cmd" &>/dev/null; then
		echo "$cmd command not found. Please install $cmd"
		exit 1
	fi
done

script=$(dirname "$0")

paths=""
for arg in "$@"; do
	if [ -e "$arg" ]; then
		paths="$paths "$(realpath "$arg")
	fi
done
hash=$(echo "$paths" | md5sum | awk '{print substr($1,1,8)}')

date_str=$(date +%Y%m%d)
work_dir="/tmp/jargon-${date_str}-${hash}"
cache_dir="$work_dir/cache"
mkdir -p "$work_dir" "$cache_dir"

echo "Using work directory: $work_dir"

analyzed_files="$cache_dir/analyzed_files.txt"
words_file="$cache_dir/all_words.txt"
uppercase_words_file="$cache_dir/uppercase_words.txt"
candidate_file="$cache_dir/candidate_words.txt"
cleaned_candidate_file="$work_dir/candidate_words.txt"
known_volume_file="$work_dir/known_words.txt"
ignored_volume_file="$work_dir/ignored_words.txt"

if [ ! -f "$analyzed_files" ]; then
	echo "Looking for markdown files ..."
	fd -t f -0 '\.(md)' "$@" >"$analyzed_files.tmp"
	mv "$analyzed_files.tmp" "$analyzed_files"
fi

tr -cd '\0' <"$analyzed_files" | wc -c | awk '{print $1 " Markdown files found"}'

if [ ! -f "$words_file" ]; then
	echo "Computing words used in these files..."
	cat "$analyzed_files" | xargs -0 -r -I X grep -I -oE '\w+' X >"$words_file.tmp"
	mv "$words_file.tmp" "$words_file"
fi

wc -l "$words_file" | awk '{print $1 " words found"}'

# This is faster than using sort and uniq
awk '{words[$0]++} END {print length(words) " unique words found"}' "$words_file"

if [ ! -f "$uppercase_words_file" ]; then
	echo "Computing words with uppercase letters..."

	# This pattern matches words that contain at least 2 uppercase letters
	awk '/[A-Z].*[A-Z]/ { word=tolower($0); if (!seen[word]++) print $0 }' "$words_file" >"$uppercase_words_file.tmp"
	mv "$uppercase_words_file.tmp" "$uppercase_words_file"
fi

nbCandidate=$(wc -l <"$uppercase_words_file")
echo "$nbCandidate words with at least 2 uppercase letters found"

if [ ! -f "$candidate_file" ]; then
	echo "Computing candidate words..."
	echo >"$candidate_file.tmp"

	i=0
	while read -r word; do
		i=$((i + 1))
		if [ $((i % 200)) -eq 0 ]; then
			echo -n "Processed $i/$nbCandidate words: "
			wc -l "$candidate_file.tmp" | awk '{print $1 " candidates found"}'
		fi

		matches=$(grep -i -w "$word" "$words_file" | sort | uniq -c)
		count=$(echo "$matches" | wc -l)
		# Here we are assuming that a candidate word is one that appears with more than one way to write it
		if [ "$count" -gt 1 ]; then
			awk '{sum += $1; words = (words ? words " " $2 : $2)} END {print sum, words}' <<<"$matches" >>"$candidate_file.tmp"
		fi
	done <"$uppercase_words_file"

	sort -rn "$candidate_file.tmp" >"$candidate_file"
	rm "$candidate_file.tmp"
fi
wc -l "$candidate_file" | awk '{print $1 " candidate words found"}'

ignored_words_file="$script/ignore.txt"
if [ ! -f "$ignored_words_file" ]; then
	touch "$ignored_words_file"
fi
echo "The following file contains the words to ignore:"
echo "$ignored_words_file"

known_words_file="$script/known.txt"
if [ ! -f "$known_words_file" ]; then
	touch "$known_words_file"
fi
echo "The following file contains the known words:"
echo "$known_words_file"

echo "Removing words that are already identified ..."
grep -v -w -f "$known_words_file" "$candidate_file" >"$cleaned_candidate_file.tmp"
mv "$cleaned_candidate_file.tmp" "$cleaned_candidate_file"

wc -l "$cleaned_candidate_file" | awk '{print $1 " candidate remains"}'

echo "Removing words that are in the ignore file..."
grep -v -w -f "$ignored_words_file" "$cleaned_candidate_file" >"$cleaned_candidate_file.tmp"
mv "$cleaned_candidate_file.tmp" "$cleaned_candidate_file"

wc -l "$cleaned_candidate_file" | awk '{print $1 " candidate remains"}'

echo "The following file contains the candidate words with their counts:"
echo "$cleaned_candidate_file"
