# SK - Companies that look like people

We noticed that some companies in Slovakia's Public Sector Partner data looked
more like people (they had first/last names and dates of birth instead of company
names). This broke our importing code (which hadn't been run regularly for a
year or more at this point)

Since the data set is quite small, I hacked our import code to just dump the
data to a local folder (not included so as not to cause any licensing issues)
combined it into one json file with combine_sk_results.rb and and then used
Apache drill to query the json directly.

The following snippets show the querystring used to answer various questions
about the data.

## Missing company names

- How many partners with no company name? 1108
    - {{select p.Id, p.flat_partners from (select Id, FLATTEN(PartneriVerejnehoSektora) as flat_partners FROM dfs.`sk-data.json`) p WHERE p.flat_partners.ObchodneMeno IS NULL ORDER BY p.Id;}}
    - Note: none with empty string for company name
- How many with no company name have full name/last name? 1108
    - {{select p.Id, p.flat_partners from (select Id, FLATTEN(PartneriVerejnehoSektora) as flat_partners FROM dfs.`sk-data.json`) p WHERE p.flat_partners.ObchodneMeno IS NULL AND (p.flat_partners.Meno IS NOT NULL AND p.flat_partners.Priezvisko IS NOT NULL) ORDER BY p.Id;}}
    - Note: None where either first name/last name are null too
        - {{select p.Id, p.flat_partners from (select Id, FLATTEN(PartneriVerejnehoSektora) as flat_partners FROM dfs.`sk-data.json`) p WHERE p.flat_partners.ObchodneMeno IS NULL AND (p.flat_partners.Meno IS NULL OR p.flat_partners.Priezvisko IS NULL) ORDER BY p.Id;}}
- How many partners with no company name have a company number? 129
    - {{select p.Id, p.flat_partners from (select Id, FLATTEN(PartneriVerejnehoSektora) as flat_partners FROM dfs.`sk-data.json`) p WHERE p.flat_partners.ObchodneMeno IS NULL AND p.flat_partners.Ico = '' ORDER BY p.Id;}}
    - Note: Ico is an empty string, not NULL in all cases
- How many partners with no company name have a D.O.B? 129
    - {{select p.Id, p.flat_partners from (select Id, FLATTEN(PartneriVerejnehoSektora) as flat_partners FROM dfs.`sk-data.json`) p WHERE p.flat_partners.ObchodneMeno IS NULL AND p.flat_partners.DatumNarodenia IS NOT NULL ORDER BY p.Id;}}
    - Note: exact same set that have no company number

## Child entity selection

- How many records with > 1 partners? 2670
    - {{SELECT t.Id, t.partner_count FROM (select p.Id, count(p.Id) AS partner_count FROM (SELECT Id, FLATTEN(PartneriVerejnehoSektora) AS flat_partners FROM dfs.`sk-data.json`) p GROUP By p.Id) t WHERE t.partner_count > 1;}}
- Are there records with > 1 partners where the first partner is expired? 2670 (all of them)
    - {{select t.Id, t.partner_count FROM (select p.Id, count(p.Id) as partner_count from (select Id, FLATTEN(PartneriVerejnehoSektora) as flat_partners FROM dfs.`sk-data.json`) p GROUP By p.Id) t WHERE t.partner_count > 1 AND t.Id IN (SELECT Id FROM dfs.`sk-data.json` WHERE PartneriVerejnehoSektora[0].PlatnostDo IS NOT NULL);}}
- Are there records with more than one partner who is not expired? No
    - Note: did this in irb:
    ```JSON
    json = JSON.parse(open('sk-data.json').read)
    results_with_multiple_partners = json.select { |r| r['PartneriVerejnehoSektora'].length > 1 }
    results_with_multiple_non_expired_partners = results_with_multiple_partners.select { |r| r['PartneriVerejnehoSektora'].select { |p| p['PlatnostDo'].nil? }.length > 1 }
    Note: There are 2617 records with multiple partners that have exactly 1 valid partner, and 53 with no valid partner
    ```
- How many records have useful dates (e.g. a start date and a nil end date)? 17921
    - {{json.select { |r| r['PartneriVerejnehoSektora'].select { |p| !p['PlatnostOd'].nil? && p['PlatnostDo'].nil? }.length > 0 }.length}}
- How many records have no start date? None
    - {{json.select { |r| r['PartneriVerejnehoSektora'].select { |p| p['PlatnostOd'].nil? }.length == 0 }.length}}
- How many records have no current parters (e.g. they have a start date and an end date)? 7558
    - {{json.select { |r| r['PartneriVerejnehoSektora'].select { |p| p['PlatnostDo'].nil? }.length == 0 }.length}}

