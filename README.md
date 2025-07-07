# jargon-extractor

## Methodology

This project is about extracting words from a large corpus.
The corpus could be a simple project or dozens of project.

The extractor looks for words that are used in Markdown files.
Only the words that are used with different cases are kept.
The idea behind this is to look for words that are written with the wrong case.

For example, Github should be written GitHub. Mysql should be MySQL.

All these words are terms or brands that should be written with a specific case.
The aim of this tool is to extract them all.

# How to use the tool

Simply launch the tool with folders or files

```console
$ ./jargon-extractor.sh <directory-or-file> [more-directories-or-files...]
```

## Examples

```console
$ ./jargon-extractor.sh ~/dev
Using work directory: /tmp/jargon-20250707-cadd1674
Looking for Markdown files ...
7,938 Markdown files found
Computing words used in these files...
6,081,968 words found
161,095 unique words found
29,682 words with at least 2 uppercase letters found
Computing candidate words...
Processed 200/29,682: 145 candidates found
Processed 400/29,682: 269 candidates found
(...)
Processed 29,600/29,682: 8,817 candidates found
8,835 candidate words found
Computing known and ignored words volumes...
Removing words that are in the known.txt file...
8,261 candidate remains
Removing words that are in the ignore.txt file...
The following file contains the candidate words with their counts:
/tmp/jargon-20250707-cadd1674/candidate_words.txt: 6,472
/tmp/jargon-20250707-cadd1674/ignored_words.txt: 1,863
/tmp/jargon-20250707-cadd1674/known_words.txt: 575
```

Here are an extract of the result files

* `known_words.txt`

```
# This file contains known words with their counts
61141 github Github GithuB GitHub GitHub- GitHuB GitHUb GItHub GITHUB
10382 json json- Json JSON JSON-
8626 api Api API API-
6011 url url- Url URL URL-
4866 html Html HTML HTML-
4390 yaml Yaml YAML
4331 git Git GIT
3656 docker Docker DOCKER
3110 javascript javaScript Javascript JavaScript JAVASCRIPT
3044 cli Cli CLi CLI CLI-
2332 sql sql- Sql SQL SQL-
```

* `ignore_words.txt`

```
# This file contains ignored words with their counts
154640 the The THE
112302 to To TO
71092 com COM
65607 and And AND
59917 of Of OF
56702 in In IN ın
53368 is Is IS
52747 for For FOR
29085 with With WITH
28275 this This THis THIS
27971 be Be BE BE-
27951 be Be BE
23369 that That THAT
```

* `candidate_words.txt`

```
# This file contains candidate words with their counts, excluding known and ignored words
5731 md MD
5078 td TD
4389 c C cr CR crrr
4373 i I ig IG
4096 ref Ref REF
3808 null Null NULL
3749 ci CI
3596 err Err ERR
3592 callback Callback CALLBACK
3030 blob Blob BLOB
2648 travis Travis TRAVIS
2432 const Const CONST
2191 fixer Fixer FIXER
1847 bot Bot BOT
1839 apache Apache APACHE
1714 socket Socket SOCKET
1558 diff Diff DIFF
```

The `candidate_words.txt` file can then be reviewed by you to get words that are
commonly used in your projects, but that might be incorrectly written.

Here:
- `Travis` and `Apache` could be added to `known.txt`
- `callback`, `socket`, `callback`, `fixer`, and `const` could be added to `ignore.txt`


## Why such tool ?

The idea is to provide list of words I could release under MIT license.

So these words could be reused in other projects like:

- [jargonLint](https://github.com/jargonLint/jargonLint)
- [cspell-dicts](https://github.com/streetsidesoftware/cspell-dicts/)
- [textlint-rule-terminology](https://github.com/sapegin/textlint-rule-terminology)

## Why using shell only ?

The idea is to be language agnostic, shell is everywhere, it works.

## Why only looking at Markdown files ?

All files could be used, but then it would bring a lot of noise as code commonly use camelCase, PascalCase, ... for identifiers.

Markdown files are written by human, they content less code, so less noise.
Also, Markdown are commonly available no matter the project. They content technical terms.
These are the terms that jargon-extractor is looking for.

## What is the code about ?

- Look for Markdown files.
- Extract all words in them by using simple regexp and store it in a cache.
- Look for words that are written with different cases.
- Compute how often a word is used no matter the cases used.
- Exclude words in ignore.txt that are considered as noise.
- Exclude words in known.txt that are considered as already identified.
- The result is a file with the number of occurrence and the different cases used for the words.

## Project structure

- [jargon-extractor.sh](jargon-extractor.sh) - the tool itself
- [known.txt](known.txt) - the list of words that were identified manually as valid words
- [ignore.txt](ignore.txt) - the list of words that could be considered as stop words or noise

## Contributions

Contributions are welcome.

## License

MIT