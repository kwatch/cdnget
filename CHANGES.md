Changes
=======


Release 1.1.0 (2021-10-10)
---------------------------

* Fix to ignore alpha or beta versions when using `latest` keyword on jsDelivr or UNPKG.
* Support `@author/name` style NPM package name on jsDelivr and UNPKG.
* Tweak help message.
* Tweak error messages
* (internal) Change UNPKG to use metadata from unpkg.com.
* (internal) Make source code refactored.
* (internal) Change testing library from `minitest` to `oktest`.


Release 1.0.2 (2021-10-03)
---------------------------

* Improve help message.
* Update `README.md`.


Release 1.0.1 (2021-10-02)
---------------------------

* Skip downloading '.DS_Store' files from unpkg.com (due to 403 Forbidden)


Release 1.0.0 (2021-10-02)
---------------------------

* Download performance improved.
* New CDN `unpkg` supported.
* Change `jsdelivr` CDN to use new jsdelivr API.
* Detect latest version of JS library automatically when `latest` keyword specified as version.
* Increase output information of JS library.
  - license
  - tags
  - page url on CDN web site
  - url of npm package (`*.tgz`)
* Add '--debug' option.


Release 0.3.1 (2021-09-30)
---------------------------

* Fix to work on Ruby 3.
* Fix to follow API specification changes of CDNJS.com.


Release 0.3.0 (2016-09-07)
---------------------------

* Change to read data from https://api.cdnjs.com/ .


Release 0.2.0 (2016-07-11)
--------------------------

* Update to follow change of CDNJS website


Release 0.1.0 (2016-01-13)
--------------------------

* First release
