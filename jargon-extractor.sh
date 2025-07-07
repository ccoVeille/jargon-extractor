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

tr -cd '\0' <"$analyzed_files" | wc -c | awk '{printf "%\047.0f Markdown files found\n", $1}'

if [ ! -f "$words_file" ]; then
	echo "Computing words used in these files..."
	# simple words, we are not using \w on purpose to avoid matching underscore
	cat "$analyzed_files" | xargs -0 -r -I X grep -I -oE '[A-Za-z0-9]+' X >"$words_file.tmp"
	# add words separated by dashes
	cat "$analyzed_files" | xargs -0 -r -I X grep -I -oE '[A-Za-z0-9]+[-]+[A-Za-z0-9]*' X >>"$words_file.tmp"
	# add words ending with plus
	cat "$analyzed_files" | xargs -0 -r -I X grep -I -oE '[A-Za-z0-9]+[+]+' X >>"$words_file.tmp"
	# add words separated by underscores but not a trailing one
	cat "$analyzed_files" | xargs -0 -r -I X grep -I -oE '[A-Za-z0-9]+[_-]+[A-Za-z0-9]+' X >>"$words_file.tmp"

	echo "# This file contains all the words found in the markdown files" > "$words_file"
	cat "$words_file.tmp" >>"$words_file"
	rm "$words_file.tmp"
fi

wc -l "$words_file" | awk '{printf "%\047.0f words found\n", $1}'

# This is faster than using sort and uniq
awk '{words[$0]++} END {printf "%\047.0f unique words found\n", length(words)}' "$words_file"

if [ ! -f "$uppercase_words_file" ]; then
	echo "Computing words with uppercase letters..."

	echo "# This file contains words with at least 2 uppercase letters" > "$uppercase_words_file.tmp"

	# This pattern matches words that contain at least 2 uppercase letters
	# Here we are doing the strong hypothesis that a jargon word has at least 2 uppercase letters
	awk '/[A-Z].*[A-Z]/ { word=tolower($0); if (!seen[word]++) print $0 }' "$words_file" >>"$uppercase_words_file.tmp"
	mv "$uppercase_words_file.tmp" "$uppercase_words_file"
fi

wc -l "$words_file" | awk '{printf "%\047.0f words with at least 2 uppercase letters found\n", $1}'
nbCandidate=$(wc -l <"$uppercase_words_file")

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

		# Escape dashes and underscores for grep
		escaped_word=$(echo "$word" | sed 's/-/\\-\\?/g;s/_/\\_\\?/g;s/+/\\+\\?/g')

		# Use grep to find all occurrences of the word in the words file, ignoring case
		matches=$(grep -i "^$escaped_word$" "$words_file" | sort | uniq -c)

		# Count the number of matches
		count=$(echo "$matches" | wc -l)
		# Here we are assuming that a candidate word is one that appears with more than one way to write it
		if [ "$count" -gt 1 ]; then
			awk '{sum += $1; words = (words ? words " " $2 : $2)} END {print sum, words}' <<<"$matches" >>"$candidate_file.tmp"
		fi
	done <"$uppercase_words_file"

	echo "# This file contains candidate words with their counts" >"$candidate_file"
	sort -rn "$candidate_file.tmp" >> "$candidate_file"
	rm "$candidate_file.tmp"
fi
egrep -v '^#' "$candidate_file" > "$candidate_file.tmp"
wc -l "$candidate_file.tmp" | awk '{printf "%\047.0f candidate words found\n", $1}'

ignored_words_file="$script/ignore.txt"
if [ ! -f "$ignored_words_file" ]; then
	touch "$ignored_words_file"
fi

known_words_file="$script/known.txt"
if [ ! -f "$known_words_file" ]; then
	touch "$known_words_file"
fi

echo "Computing known and ignored words volumes..."

grep -w -f "$known_words_file" "$candidate_file.tmp" > "$known_volume_file.tmp"
echo "# This file contains known words with their counts" >"$known_volume_file"
cat "$known_volume_file.tmp" >>"$known_volume_file"
rm "$known_volume_file.tmp"

grep -w -f "$ignored_words_file" "$candidate_file.tmp" >"$ignored_volume_file.tmp"
echo "# This file contains ignored words with their counts" >"$ignored_volume_file"
cat "$ignored_volume_file.tmp" >>"$ignored_volume_file"
rm "$ignored_volume_file.tmp"

echo "Removing words that are in the known.txt file..."
grep -v -w -f "$known_words_file" "$candidate_file.tmp" >"$cleaned_candidate_file.tmp"
mv "$cleaned_candidate_file.tmp" "$cleaned_candidate_file"

wc -l "$cleaned_candidate_file" | awk '{printf "%\047.0f candidate remains\n", $1}'

echo "Removing words that are in the ignore file..."
grep -v -w -f "$ignored_words_file" "$cleaned_candidate_file" >"$cleaned_candidate_file.tmp"
echo "# This file contains candidate words with their counts, excluding known and ignored words" >"$cleaned_candidate_file"
cat "$cleaned_candidate_file.tmp" >>"$cleaned_candidate_file"
rm "$cleaned_candidate_file.tmp" "$candidate_file.tmp"

echo "The following file contains the candidate words with their counts:"
wc --total=never -l "$work_dir"/*.txt | awk '{printf "%s: %\047.0f\n", $2, $1}'
