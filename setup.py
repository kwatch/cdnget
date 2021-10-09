# -*- coding: utf-8 -*-

import sys
from distutils.core import setup

PY2 = sys.version_info[0] == 2
PY3 = sys.version_info[0] == 3

def _pypi_download_url(name, version):
    base = 'https://pypi.python.org/packages/source/%s/%s/%s-%s.tar.gz'
    return base % (name[0], name, name, version)

def _kwargs():
    name          = 'cdnget'
    version       = '$Release: 1.1.0 $'.split(' ')[1]
    author        = 'kwatch'
    author_email  = 'kwatch@gmail.com'
    description   = 'Utility to download files from public CDN (CDNJS/jsDelivr/UNPKG/Google)'
    url           = 'https://github.com/kwatch/cdnget/tree/python'
    download_url  = _pypi_download_url(name, version)
    license       = 'MIT'
    platforms     = 'any'
    py_modules    = ['cdnget']
    #package_dir   = {'': PY2 and 'lib2' or 'lib3'}
    #packages     = ['cdnget']
    #scripts       = ['bin/cdnget']
    #install_requires = ['oktest']
    entry_points  = {
        "console_scripts": [
            "cdnget = cdnget:main",
        ],
    }
    extras_require = {
        'dev' : ['oktest', 'kook'],
        'test': ['oktest'],
    }
    #
    long_description = r"""
Utility to download files from public CDN:

* CDNJS    (https://cdnjs.com)
* jsDelivr (https://www.jsdelivr.com)
* UNPKG    (https://unpkg.com)
* Google   (https://ajax.googleapis.com)

Example::

    $ cdnget                           # list public CDN names
    $ cdnget cdnjs                     # list libraries
    $ cdnget cdnjs jquery              # list versions
    $ cdnget cdnjs jquery latest       # show latest version
    $ cdnget cdnjs jquery 2.2.4        # list files
    $ mkdir -p static/lib              # create a directory
    $ cdnget cdnjs jquery 2.2.4 static/lib  # download files
    $ find static/lib
    static/lib
    static/lib/jquery
    static/lib/jquery/2.2.4
    static/lib/jquery/2.2.4/jquery.min.js
    static/lib/jquery/2.2.4/jquery.min.map
    static/lib/jquery/2.2.4/jquery.js
"""[1:]
    #
    classifiers = [
        #'Development Status :: 3 - Alpha',
        #'Development Status :: 4 - Beta',
        'Development Status :: 5 - Production/Stable',
        'Environment :: Console',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Operating System :: OS Independent',
        'Programming Language :: Python',
        'Programming Language :: Python :: 2.6',
        'Programming Language :: Python :: 2.7',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.3',
        'Programming Language :: Python :: 3.4',
        'Programming Language :: Python :: 3.5',
        'Programming Language :: Python :: 3.6',
        'Programming Language :: Python :: 3.7',
        'Programming Language :: Python :: 3.8',
        'Programming Language :: Python :: 3.9',
        'Programming Language :: Python :: 3.10',
        'Topic :: Software Development :: Libraries :: Python Modules',
        'Topic :: Internet :: WWW/HTTP :: Dynamic Content :: CGI Tools/Libraries',
    ]
    #
    return locals()

setup(**_kwargs())
