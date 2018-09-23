#!/bin/env ruby
# frozen_string_literal: true

require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class MemberList < Scraped::JSON
  field :members do
    json.dig(:AllMembersList, :Member).map { |m| fragment(m => Member) }.uniq(&:id).map(&:to_h)
  end
end

class Member < Scraped::JSON
  field :id do
    json[:PersonId]
  end

  field :name do
    json[:MemberName].split(', ').reverse.join(' ')
  end

  field :family_name do
    json[:MemberLastName]
  end

  field :given_name do
    json[:MemberFirstName]
  end

  field :image do
    json[:MemberImgUrl]
  end
end

url = 'http://data.niassembly.gov.uk/members.asmx/GetAllMembers_JSON?'
Scraped::Scraper.new(url => MemberList).store(:members)
