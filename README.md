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

Simply launch

## Project structure

- [jargon-extractor.sh](jargon-extractor.sh) - the tool itself
- [known.txt](known.txt) - the list of words that were identified manually as valid words
- [ignore.txt](ignore.txt) - the list of words that could be considered as stop words or noise

## Contributions

Contributions are welcome.

## License

MIT