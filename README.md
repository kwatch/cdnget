CDNget
======

($Release: 0.0.0 $)

CDNget is a utility script to download files from CDNJS, jsDelivr, UNPKG or Google.


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

    $ cdnget                               # list CDN (cdnjs/jsdelivr/unpkg/google)
    $ cdnget [-q] cdnjs                    # list libraries (except jsdelivr/unpkg)
    $ cdnget [-q] cdnjs '*jquery*'         # search libraries
    $ cdnget [-q] cdnjs jquery             # list library versions
    $ cdnget [-q] cdnjs jquery latest      # show latest version
    $ cdnget [-q] cdnjs jquery 2.2.0       # list library files
    $ mkdir -p static/lib                  # create a directory
    $ cdnget [-q] cdnjs jquery 2.2.0 static/lib  # download files
    static/lib/jquery/2.2.0/jquery.js ... Done (258,388 byte)
    static/lib/jquery/2.2.0/jquery.min.js ... Done (85,589 byte)
    static/lib/jquery/2.2.0/jquery.min.map ... Done (129,544 byte)

    $ ls static/lib/jquery/2.2.0
    jquery.js	jquery.min.js	jquery.min.map


Tips
----

CDNget downloads files with keeping file structures, therefore you can
switch file source URL easily (CDN <=> local development server).

```erb
<%
    if ENV['RACK_ENV'] == "development"
      static_baseurl = "/static/lib"
    else  # production
      static_baseurl = "https://cdnjs.cloudflare.com/ajax/libs"
    end
%>
<script src="<%= static_baseurl %>/jquery/2.2.0/jquery.min.js"></script>
```


Todo
----

* [x] change to call api.cdnjs.com
* [x] support <https://unpkg.com/>


Copyright and License
---------------------

$Copyright: copyright(c) 2016-2021 kuwata-lab.com all rights reserved $

$License: MIT License $
