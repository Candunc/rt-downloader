This file provides the content and reasoning behind the tables in the SQL Database. It is designed and tested for MariaDB, however all attempts will be made for compatibility with MySQL. 

---
<br>
###Metadata

| Column | Type | Explanation |
|---|---|---|
| processed | TINYINT SIGNED DEFAULT 0 | Representative of the current state of the video. See below addition.
| hash | CHAR(64) <br> NOT NULL | Hash of the video title, converted to all lowercase, non-alphanumeric characters and spaces are stripped. Algorithm is SHA-256.
| sponsor | TINYINT | Boolean value stored as integer as a holdover from SQLite3. If 0 the video is available to the general public; 1 if restricted to sponsors.
| channelURL | VARCHAR(32) | Base portion of the URL; used for selecting the channel in the frontend.
| slug | VARCHAR(100) | The remainder of the URL for the specified video.
| showName | VARCHAR(100) | The specified show the video belongs to.
| title | VARBINARY(800) | The specified title of the video. Specified as VARBINARY in the case that the supporting database forces characters into a simpler character set.
| caption | VARBINARY(4000) | The caption of the video, some videos use a simple line of text, while older videos have an identical entry to description.
| description | VARBINARY(4000) | The specified description of the video, with no HTML tags.
|  image | VARCHAR(200) | Full resolution version of the episode thumbnail.
| imageMedium | VARCHAR(200) | Reduced resolution version of the episode thumbnail. (960px x 540px)
| releaseDate | CHAR(10) | The date the video was added to the website, formatted as ISO 8601 Date.
| m3u8URL | VARCHAR(200) | If possible, extract the m3u8 file from webpage.
|   | UNIQUE(hash) | Prevent duplicate entries for the same video. Collision attacks are unlikely so no videos will be accidentally ignored.


**processed ints**

     0 – Not processed.
     1 – Processing complete; ready for download. This will lead to a second query, so that  can be optimized in the future.
    -1 – Video reserved and placed into Storage table.

---
<br>

###Storage

| Column | Type | Explanation |
|---|---|---|
| locked | TINYINT SIGNED DEFAULT 0 | Signifies whether a video is locked. If locked, assumes that the remainder of the fields are filled out. See below table for possible values.
| hash | CHAR(64) <br> NOT NULL | Hash of the video; inherited from Metadata.
| added | CHAR(19) <br> NOT NULL| Timestamp of when video was added to database. Used to prioritize  videos that have been in the table for longer.
| node | VARCHAR(50) | IP Address or unique domain name of a node; used to record node contribution.
| url | VARCHAR(200) | The link for a video that is available for downloading, will be reported to the user.
| size | UNSIGNED SMALLINT | The size of the file in Megabytes (~64 GB max filesize)
| length | CHAR(8) | The Length of the video, specified in HH:MM:SS
| timeout | CHAR(19) | When timeout is reached video is assumed to have failed for whatever reason. Reset locked status to 0 and nullify the node, url, and timeout columns.
|   | UNIQUE(hash) | Prevent duplicate entries into the table.

**locked ints**

     0 – unlocked, available for reservation and download
     1 - Video reserved, downloading by node. If timeout is reached 
    -1 – "Permanently locked"; Download is complete