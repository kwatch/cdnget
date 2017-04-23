cdnget
======

($Release: 1.0.0 $)

Utility to download files from public CDN:

* CDNJS    (https://cdnjs.com)
* jsDelivr (https://www.jsdelivr.com)
* Google   (https://ajax.googleapis.com)


Install
-------

    $ pip install cdnget

Requires Python 2.6 or later.


Example
-------

    $ cdnget                           # list public CDN
    $ cdnget cdnjs                     # list libraries
    $ cdnget cdnjs jquery              # list versions
    $ cdnget cdnjs jquery 2.2.4        # list files
    $ mkdir -p static/libs
    $ cdnget cdnjs jquery 2.2.4 static/libs   # download files
    $ ls static/libs/jquery/2.2.4
    jquery.js	jquery.min.js	jquery.min.map
