# CCE-Objects-Deletion

This script was written for NEWSCYCLE Solutions. The purpose of this stored procedure is to give to give NCS Support the ability (and a database job) the ability to target and delete certain CCE Objects. This stored procedure finds the CCE Objects that need to be deleted and passes their ID to a another stored procedure called CCE_DeleteObject (see line 167) which was written by NEWSCYCLE Digital developers. 

 based on the following criteria:

1. Site Code (or multiple site codes by passing in 'XX' instead of a site code.)

2. Expiration Day - The user can pass in '120', for example, if they want the stored procedure to find objects that are older than 120 days and delete those objects.

3. Module ID - The user can pass in a numeric value for the module ID such as '1' if they want to delete all of the objects that have a module ID of 1.

##Example 1:  

exec exec custom.dbo.CCECleanup 'XX', 120, 39, 0

The above version of the stored procedure will do the following:

 1. Look up a list of sites in the customer's SiteInfo table. The SiteInfo  table is a table that contains records for each of the site codes in a customer's database. The 'XX' parameter value should only be used if the customer has their own read/write database server. If not, then an individual site could should be used.

 2. For each site code (This doesn't apply if an individual site code is passed), a lookup will occur for CCE Objects stored under that site code. The lookup is against the CCE_Status table.

 3. For each lookup, the objects selected will be objects that are 120 days old and that have a module ID of 39.

 4. The last parameter in the stored procedure is a debug parameter. It could either be set to 0 or 1. 1 enables debug mode which means the stored procedure will print out extra information about what is going to be delete and/or exception messages.


##Example 2: 

exec exec custom.dbo.CCECleanup 'SW', 120, 39, 0

1. This example means the stored procedure will only delete objects under the SW site code. 


##Example 3: 

exec custom.dbo.CCECleanup 'SW', 0, 1, 0

1. This example means the stored procedure will look up objects that are under the SW site and code ones that are 60 days old (The default days lookup value for the stored procedure) because the second parameter is set to 0. Furtheremo, it will target objects that have a module ID of 1 and debug mode is disabled for it. 

