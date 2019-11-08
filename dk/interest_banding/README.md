# DK - banded interests

In the DK CVR data, legal ownership interest percentages are described as being
in bands, rather than exact values (http://datahub.virk.dk/dataset/system-til-system-adgang-til-cvr-data).

We've assumed the same is true for beneficial ownership percentages, but we have
examples where this is incorrect (comparing our results to those on the
register's own pages). In order to figure out what to do, we did some analysis to
see if we could figure out from the data what was happening.

Since the register now stores raw data, I used this dataset to do the analysis,
writing a custom class to load them all, parse the json and extract the same
interest values that our import code does. This last bit is important because we
do various filtering to (for example) make sure we only get the most recent
beneficial owner.

To run it, I just opened a new rails console with a dump of the production
database connnected and then called ``DkInterestsExplorer.new.call`. This prints
some of the headline stats (as well as progress), then drops you into an IRB
session so you can explore all the data.
