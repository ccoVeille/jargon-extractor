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

Using work directory: /tmp/jargon-20250707-d529abdf
2766 Markdown files found
2546888 words found
112152 unique words found
16885 words with at least 2 uppercase letters found
5056 candidate words found
Removing known words ...
4747 candidate remains
Removing words that are in the ignore file...
3969 candidate remains
The following file contains the candidate words with their counts:
/tmp/jargon-20250707-d529abdf/cleaned_candidate_words.txt
```

The cleaned_candidate_words.txt file can then be reviewed by you to get words that are
commonly used in your projects, but that might be incorrectly written.

Here is an example of the content of cleaned_candidate_words.txt file

```
46863 github Github GithuB GitHub GitHuB GItHub GITHUB
3751 json Json JSON
3533 yaml Yaml YAML
3177 api Api API
3166 git Git GIT
2909 url Url URL
2049 cli Cli CLi CLI
1758 linux Linux LINUX
1536 youtube Youtube YouTube
1493 dns Dns DNS
1434 javascript javaScript Javascript JavaScript
1328 golang Golang GoLang
1238 google Google GOOGLE
1144 mit MIT
1135 markdown Markdown MarkDown MARKDOWN
1015 sql Sql SQL
```

Note: This example is what you could get from an empty known.txt file by keeping the provided ignore.txt one.

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