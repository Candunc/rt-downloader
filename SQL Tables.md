This file provides the content and reasoning behind the tables in the SQL Database. It is designed and tested for MariaDB, however all attempts will be made for compatibility with MySQL. 

###Metadata

| Column | Type | Explanation |
|---|---|---|
processed | TINYINT SIGNED DEFAULT 0 | Representative of the current state of the video. See below addition.
hash | CHAR(64) | Hash of the video title, converted to all lowercase, non-alphanumeric characters and spaces are stripped. Algorithm is SHA-256.
sponsor | TINYINT | Boolean value stored as integer as a holdover from SQLite3. If 0 the video is available to the general public; 1 if restricted to sponsors.
channelURL | VARCHAR(32) | Base portion of the URL; used for selecting the channel in the frontend.
slug | VARCHAR(100) | The remainder of the URL for the specified video.
showName | VARCHAR(100) | The specified show the video belongs to.
title | VARBINARY(800) | The specified title of the video. Specified as VARBINARY in the case that the supporting database forces characters into a simpler character set.
caption | VARBINARY(4000) | The caption of the video, some videos use a simple line of text, while older videos have an identical entry to description.
description | VARBINARY(4000) | The specified description of the video, with no HTML tags.
image | VARCHAR(200) | Full resolution version of the episode thumbnail.
imageMedium | VARCHAR(200) | Reduced resolution version of the episode thumbnail. (960px x 540px)
releaseDate | CHAR(10) | The date the video was added to the website, formatted as ISO 8601 Date.

**processed ints**

    *  0 – Not processed.
    *  1 – Processing complete; ready for download.
    * -1 – Processing failed. See node for details.
    * -2 – Currently being processed by a node.

---

###Storage

This table is not complete.
