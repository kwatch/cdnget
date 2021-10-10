<!-- -*- coding: utf-8 -*- -->

CDNget README (for Python)
==========================

($Release: 0.0.0 $)

CDNget is a utility to download files from public CDN:

* CDNJS    (https://cdnjs.com/)
* jsDelivr (https://www.jsdelivr.com/)
* UNPKG    (https://unpkg.com/)
* Google   (https://ajax.googleapis.com/)


Install
-------

    $ pip install cdnget

Requires Python 2.6 or later.


Example
-------

```terminal
$ cdnget                           # list public CDN
$ cdnget cdnjs                     # list libraries
$ cdnget cdnjs jquery              # list versions
$ cdnget cdnjs jquery latest       # show latest version
$ cdnget cdnjs jquery 2.2.4        # list files
$ mkdir -p static/lib
$ cdnget cdnjs jquery 2.2.4 static/libs   # download files
static/lib/jquery/2.2.4/jquery.js ... Done (257,551 byte)
static/lib/jquery/2.2.4/jquery.min.js ... Done (85,578 byte)
static/lib/jquery/2.2.4/jquery.min.map ... Done (129,572 byte)
$ ls static/lib/jquery/2.2.4
jquery.js	jquery.min.js	jquery.min.map
```


Tips
----

CDNget downloads files from CDN with keeping file structure.
For exapmle:

```terminal
$ cdnget cdnjs jquery 2.2.4 static/libs
$ tree static/lib
static/lib
└── jquery
    └── 2.2.4
        ├── jquery.js
        ├── jquery.min.js
        └── jquery.min.map

2 directories, 3 files
```

Therefore it is easy to switch base location of JS libraries between CDN and local directory.
For examle:

```html
<?py if APP_MODE == "development": ?>
<?py     basedir = "/static/lib" ?>
<?py else: ?>
<?py     basedir = "https://cdnjs.cloudflare.com/ajax/libs" ?>
<?py end ?>
<script href="${baseurl}/jquery/2.2.4/jquery.min.js"></script>
```


ChangeLog
---------

* Release 1.2.0
  * Changes to exclude alpha or beta version when using `latest` keyword on jsDelivr or UNPKG
  * Supports `@author/name` style NPM package on jsDelivr and UNPKG

* Release 1.1.0
  * Supports new public CDN: UNPKG (https://unpkg.com/)
  * Supports `latest` as version number of libraries
  * Change jsDelivr CDN to new API (supports npm package only)

* Release 1.0.0
  * Public release
