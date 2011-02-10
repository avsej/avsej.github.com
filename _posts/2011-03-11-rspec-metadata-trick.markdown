---
layout: post
title: RSpec metadata trick
description: Pass useful data with rspec example metadata
---

RSpec is absolutely flexible tool. One of its multitarget features is [metadata][1]. The main purpose of this feature is filtering and groupping examples by given attributes. You can found a lot of examples in article ["Filtering examples in rspec-2"][2].

Recently I was faced with the need to test application behaviour depending on current subdomain. It was a group of examples so I need to use filters. Spec was similar to script below:

    feature "On custom subdomain", :subdomain => 'custom' do
      scenario "homepage should change colorscheme to blue and use custom logo" do
        ...
      end

      scenario "about us page should show custom contact info" do
        ...
      end
      ...
    end

It also need to configure that filter in `spec_helper.rb`:

    RSpec.configure do |config|
      config.around(:each, :subdomain => 'custom') do |example|
        Capybara.default_host = "custom.example.com"
        Capybara.current_session.reset!
        example.run
        Capybara.default_host = nil
        Capybara.current_session.reset!
      end
    end

But what if we need to take into account particular subdomain name wich could be changed for another group. Here is that litle trick: RSpec hook conditions accept not only plain values. To solve our problem we need to change only two lines:

      config.around(:each, :subdomain => /[\w-]+/) do |example|
        Capybara.default_host = "#{example.metadata[:subdomain]}.example.com"

This code means that we looking for examples or example groups with key `:subdomain` and value matching `/[\w-]+/`. To see how it works let see `RSpec::Core::Metadata#apply_conditions`. It has special handling for `Hash`, `Regexp`, `Proc` and `Fixnum`. So you can even use `:dup.to_proc` as a filter condition.

[1]: https://github.com/rspec/rspec-core/blob/master/lib/rspec/core/metadata.rb
[2]: http://blog.davidchelimsky.net/2010/06/14/filtering-examples-in-rspec-2/

