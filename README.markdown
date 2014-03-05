# JSHint.rb

[![Build Status](https://secure.travis-ci.org/josephholsten/jshint.rb.png)](http://travis-ci.org/josephholsten/jshint.rb)

**JSHint on Rails** is a Ruby library which lets you run
the [JSHint JavaScript code checker](http://jshint.com) on your Javascript code easily.
JSHint on rails is a fork project from [JSLint on Rails](https://github.com/jsuder/jslint_on_rails),
adapted to work with jshint.

## Requirements

* Ruby 1.8.7 or 1.9.2+
* Javascript engine compatible with [execjs](https://github.com/sstephenson/execjs) (on Mac and Windows it's provided by the OS)
* JSON engine compatible with [multi_json](https://github.com/intridea/multi_json) (included in Ruby 1.9, on 1.8 use e.g. [json gem](http://rubygems.org/gems/json))
* should work with (but doesn't require) Rails 2.x and 3.x

## Installation

To use JSHint in Rails 3 you just need to do one thing:

* add `gem 'jshint-rb'` to bundler's Gemfile

In Rails 2 and other frameworks JSHint on Rails can't be loaded automatically using a Railtie, so you have to load it explicitly. The procedure in this case is:

* install the gem in your application using whatever technique is recommended for your framework (e.g. using bundler,
or by installing the gem manually with `gem install jshint-rb` and loading it with `require 'jshint'`)
* in your Rakefile, add a line to load the JSHint tasks:

        require 'jshint/tasks'

## Configuration

It's strongly recommended that you create your own copy of the JSHint config file provided by the gem and tweak it to suit your preferences. To create a new config file from the template in your config directory, call this rake task:

    [bundle exec] rake jshint:copy_config

This will create a config file at `config/jshint.yml` listing all available options. If for some reason you'd like to put the config file at a different location, set the `config_path` variable somewhere in your Rakefile:

    JSHint.config_path = "config/lint.yml"

There are two things you can change in the config file:

* define which Javascript files are checked by default; you'll almost certainly want to change that, because the default
is `public/javascripts/**/*.js` which means all Javascript files, and you probably don't want JSHint to check entire
jQuery, Prototype or whatever other libraries you use - so change this so that only your scripts are checked (you can
put multiple entries under "paths:" and "exclude_paths:")
* enable or disable specific checks - I've set the defaults to what I believe is reasonable,
but what's reasonable for me may not be reasonable for you

## Running

To start the check, run the rake task:

    [bundle exec] rake jshint

You will get a result like this (if everything goes well):

    Running JSHint:
    
    checking public/javascripts/Event.js... OK
    checking public/javascripts/Map.js... OK
    checking public/javascripts/Marker.js... OK
    checking public/javascripts/Reports.js... OK
    
    No JS errors found.

If anything is wrong, you will get something like this instead:

    Running JSHint:
    
    checking public/javascripts/Event.js... 2 errors:
    
    Lint at line 24 character 15: Use '===' to compare with 'null'.
    if (a == null && b == null) {
    
    Lint at line 72 character 6: Extra comma.
    },
    
    checking public/javascripts/Marker.js... 1 error:
    
    Lint at line 275 character 27: Missing radix parameter.
    var x = parseInt(mapX);
    
    
    Found 3 errors.
    rake aborted!
    JSHint test failed.

If you want to test specific file or files (just once, without modifying the config), you can pass paths to include
and/or paths to exclude to the rake task:

    rake jshint paths=public/javascripts/models/*.js,public/javascripts/lib/*.js exclude_paths=public/javascripts/lib/jquery.js

For the best effect, you should include JSHint check in your Continuous Integration build - that way you'll get
immediate notification when you've committed JS code with errors.

## Running from your code

If you would prefer to write your own rake task to run JSHint, you can create and execute the JSHint object manually:

    require 'jshint'
    
    lint = JSHint::Lint.new(
      :paths => ['public/javascripts/**/*.js'],
      :exclude_paths => ['public/javascripts/vendor/**/*.js'],
      :config_path => 'config/jslint.yml'
    )
    
    lint.run

## Credits

* JSLint on Rails was created by [Jakub Suder](http://psionides.eu), licensed under MIT License
* JSHint by [JSHint Community](https://github.com/jshint/jshint)
* JSHint is a fork of JSLint and is maintained by the [JSHint Community](https://github.com/jshint/jshint)
* JSLint was created by [Douglas Crockford](http://jslint.com)
