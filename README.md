# CurrencyCrusher

Documentation/Post Install Instructions - https://docs.google.com/document/d/1g1BvKgOX-a3r1JPlOFPwhdqvmvrdImVLkf_YC4XYMrg/edit#heading=h.s465oykqj3xs

Sandbox Install Link: https://test.salesforce.com/packaging/installPackage.apexp?p0=04t3C000000EcQj

Production Install Link: https://login.salesforce.com/packaging/installPackage.apexp?p0=04t3C000000EcQj

Overview: 
Currency Crusher is designed to help Salesforce owners keep their non corporate currency price book entries aligned with their corporate currency price book entries by using the latest exchange rates. 

How Currency Crusher Works: 
Currency Crusher uses sophisticated logic to ensure your non corporate currency Price Book Entries always reflect the latest exchange rates. Below is the high level logic:
Automatically detects the organization's corporate currency
For every active Price Book in the org, it goes through each active Product in that Price Book one at a time. 
It finds the Price Book Entry using the Corporate Currency and uses that as the Base Price. 
It then updates all of the active non Corporate Currency Price Book entries using the base price found in step 3 and the latest Currency Exchange Rates. 

Currency Crusher would also be applicable in the scenario above if the base USD price was changed, and you wanted to automatically update the CAD price without having to do it manually. 
