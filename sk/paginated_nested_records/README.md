# Paginated nested records

Whilst testing an update to our Slovakian importer that added older, 'invalid'
(in google translate terms) beneficial owners, we noticed that our site displayed
fewer Beneficical owners than the official one. On closer inspection, we noticed
that some api results had a 'pagination' link on their lists of people, so we
were only getting the first page of 20.

This is an undocumented and to the best of our knowledge un-controllable feature
of the api, so we had to do some analysis to figure out how to work around it and
make sure we were getting all the data.

## count-nested-records.rb
First, we wanted to know how many records had this pagination:

```
$ grep 'KonecniUzivateliaVyhod@odata.nextLink' sk-data.json | wc -l
142
```

sk-data.json in this is my old sample of the whole dataset from the
`company_people` episode, but represents a complete snapshot of the data.

Next, we need to know whether our approach to get them all will work. The
`odata.nextlink` results in a 404, so we have to query a different endpoint.
Initially I picked: https://rpvs.gov.sk/OpenData/Partneri({id})?$expand=KonecniUzivateliaVyhod($expand=*)
which is the endpoint for a single 'Partneri' (identified by their id number)
with the list of 'Konecni' (and all it's subresources) expanded, i.e. nested
inline.

`count-nested-records.rb` is a simple script to load that endpoint for each of
the 142 records with pagination links and count the number of results inside
the KonecniUzivateliaVyhod array.
