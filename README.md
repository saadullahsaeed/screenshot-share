screenshot-share
================

A simple Ruby app, to watch changes to screenshot directory and auto-upload all screenshots to Imgur and copy the link in clipboard for easy sharing.

Also, added support for growl notifications. Uses ruby-growl.


GEM Dependencies
================

- fssm
- crack/json
- ruby-growl
- yaml
- oauth


Added Support OAuth
===================

You will need to get the access token and plug into the config in order to use OAuth. I need to add a mode config, to be able to use this with the anonymous IMGUR API


Usage
=====

ruby control.rb start -- /path/to/config.yaml


Anonymous vs OAuth
==================

To use the 'Anonymous' mode, set the property anonymous: 1 in the config.

To use OAuth, get the access token and add it to the config as indicated in the sample config.


Email: saadullah.saeed@gmail.com


