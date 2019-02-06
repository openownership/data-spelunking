# Duplicate companies

We have instances in the OO Register where what looks like the same company is
loaded in multiple times. On investigation, these companies had some
similarities, like missing a registered country.

I ran a few queries with [jq](https://stedolan.github.io/jq/) across a sample
download of the PSC data to see how common this was.

For all commands, precede them with:

```
cat persons-with-significant-control-snapshot-2019-01-16.txt |
```

to load the data and follow with:

```
| wc -l
```

to count the number of records returned.

How many PSC records state the parent is a corporate-entity and have no
`country_registered`?

```
jq -c 'select((.data.kind == "corporate-entity-person-with-significant-control") and (.data.identification.country_registered == null))'
```

How many of those have no company number either?

```
jq -c 'select((.data.kind == "corporate-entity-person-with-significant-control") and (.data.identification.country_registered == null) and (.data.identification.registration_number == null))'
```

What about no country in the address data either?

```
jq -c 'select((.data.kind == "corporate-entity-person-with-significant-control") and (.data.identification.country_registered == null) and (.data.identification.registration_number == null) and (.data.address.country == null))'
```
