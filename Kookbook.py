# -*- coding: utf-8 -*-

import sys, os, re

pyvers = prop('pyvers', "2.6.9, 2.7.13, 3.3.6, 3.4.5, 3.5.2, 3.6.0")
pyroot = prop('pyroot', "/opt/vs/python/%s")


@recipe
def task_help(self):
    print(r"""
How to release:

  $ git checkout python-dev
  $ git checkout -b python-1.0
  $ kk edit 1.0.0

  ### create package
  $ kk package
  $ ls dist
  cdnget-1.0.0.tar.gz

  ### confirm package
  $ bash
  $ pyvenv testenv
  $ . testenv/bin/activate
  $ pip install dist/cdnget-1.0.0.tar.gz
  $ which cdnget
  $ cdnget --version
  1.0.0
  $ cdnget --help | less
  $ exit
  $ rm -r testenv

  ### commit and tag
  $ git add -p
  $ git commit -m "python: release preparation for 1.0.0"
  $ git tag py-1.0.0
  $ git push
  $ git push --tags

  ### reset 'python' branch
  $ git checkout python
  $ git reset --hard -
  $ git push -uf origin python
  $ git checkout -
""")

@recipe
@spices("-a : test on Python2.x and 3.x")
def task_test(c, *args, **kwargs):
    """do test"""
    if not kwargs.get('a'):
        system(c%"python -m oktest tests")
    else:
        vers = [ s.strip() for s in pyvers.split(',') ]
        for ver in vers:
            print(c%"### python $(ver)")
            pydir = pyroot % ver
            system_f(c%"PATH=$(pydir)/bin:$PATH python --version")
            system_f(c%"PATH=$(pydir)/bin:$PATH python -m oktest tests -sp")

@recipe
def task_edit(c, release=None):
    """edit files"""
    if release is None:
        print("*** ERROR: edit task requires release number.")
        return 1
    def filenames():
        system("python setup.py sdist --manifest-only > /dev/null 2>&1")
        with open('MANIFEST') as f:
            for line in f:
                if line.startswith('#'):
                    continue
                yield line.strip()
    #
    for fname in filenames():
        print("$ edit %s" % fname)
        with open(fname, 'r+', encoding='utf-8') as f:
            s = f.read()
            s = re.sub(r'\$[R]elease\$', release, s)
            s = re.sub(r'\$[R]elease: .*?\$', '$''Release: %s $' % release, s)
            s = re.sub(r'\$[R]elease: .*?\$', '$''Release: %s $' % release, s)
            #
            f.seek(0)
            f.truncate()
            f.write(s)

@recipe
def task_package(c):
    """create package"""
    system(c%"python setup.py sdist")

@recipe
def task_clean(c):
    """remove files"""
    rm_f("**/*.pyc")
    rm_rf("MANIFEST")
    rm_rf("dist", "build")
