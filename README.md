CDNget
======

($Release: 0.0.0 $)

CDNget is a utility script to download files from CDNJS, jsDelivr or Google.


Install
-------

    $ gem install cdnget

Or:

    $ curl -sLo cdnget bit.ly/cdnget_rb
    $ chmod a+x cdnget
    $ sudo cp cdnget /usr/local/bin

CDNget is implemented in Ruby and requires Ruby >= 2.0.


Usage
-----

    $ cdnget                               # list CDN (cdnjs/jsdelivr/google)
    $ cdnget [-q] cdnjs                    # list libraries
    $ cdnget [-q] cdnjs '*jquery*'         # search libraries
    $ cdnget [-q] cdnjs jquery             # list library versions
    $ cdnget [-q] cdnjs jquery 2.2.0       # list library files
    $ cdnget [-q] cdnjs jquery 2.2.0 /tmp  # download files
    /tmp/jquery/2.2.0/jquery.js ... Done (258,388 byte)
    /tmp/jquery/2.2.0/jquery.min.js ... Done (85,589 byte)
    /tmp/jquery/2.2.0/jquery.min.map ... Done (129,544 byte)

    $ ls /tmp/jquery/2.2.0
    jquery.js	jquery.min.js	jquery.min.map


Todo
----

* [_] change to call api.cdnjs.com


Copyright and License
---------------------

$Copyright: copyright(c) 2016 kuwata-lab.com all rights reserved $

$License: MIT License $
