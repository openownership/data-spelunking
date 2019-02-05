# Etag and self_link consistency

We were suspicious whether the etags present in UK PSC data could be relied on
to signify changes in the data or not. Relatedly, we wanted to check whether the
kinds of changes that happened were 'minor' or whether larger changes of control
were happening under the guise of edits to existing owners when they should have
been reported as new owners entirely.

## Setup
Install the gem requirements with bundler:

```
cd etags
bundle
```

Download some data from http://download.companieshouse.gov.uk/en_pscdata.html
and extract the `.txt` from the zips. You need at least two files, though the
code is written such that we can potentially compare more (memory permitting).

## Etag consistency

`etag_consistency_checker.rb` is a script to process two downloads from
[Companies House](http://download.companieshouse.gov.uk/en_pscdata.html) and
compare the etags within them. It works by looping over every line, calculating
its own digest of the data therein and then comparing whether our digests and the
etags agree across snapshots. i.e. whether our digest changes when the etag
changes and vice-versa. It needs quite a lot of memory to run, because it stores
all this data in a Hash in memory to allow easy lookup later, but it writes
out the intermediate calculations so that the digests etc can be reloaded
without re-parsing every line and re-calculating the digests.

To process the data for the first time, or re-calculate saved data:

```shell
bundle exec etag_consistency_checker.rb
```

To use cached digests:

```shell
bundle exec etag_consistency_checker.rb --cached
```

Since this takes a very long time to run (several hours) you can terminate the
data file processing early to get some intermediate results by hitting ctrl+c
during the file processing. The code will trap that signal and abort the file its
on, moving onto the next in the list, but keep whatever it has processed so far.

# Name changes

One particular example of significant data changes we were interested in is when
people change the name of an owner entirely. `etag_name_checker.rb` extracts all
the `name_elements` from PSC records and then produces a set of diffs,
outputting a count of the records where 2 or more elements changed. We weren't
sure how much data this would be, so at the end it drops you into a `pry`
debugging console so you can explore the diffs in more detail. I used this to
just dump the diffs as json and then used `reformat_diff.rb` to turn that into
a csv file for analysis.
