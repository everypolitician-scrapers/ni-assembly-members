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

class MemberName < Scraped::JSON
  field :prefix do
    partitioned.first.join(' ')
  end

  field :suffix do
    partitioned.last.join(' ')
  end

  field :name do
    partitioned[1].join(' ')
  end

  private

  PREFIXES = %w(SIR).freeze
  SUFFIXES = %w(MC MP MBE OBE MCA).freeze

  def partitioned
    pre, rest = words.partition { |w| PREFIXES.include? w.chomp('.').upcase }
    suf, name = rest.partition { |w| SUFFIXES.include? w.chomp('.').upcase }
    [pre, name, suf]
  end

  def prefixes
    partitioned.first.map { |w| w.chomp('.') }
  end

  def words
    json.split('|').first.tidy.split(/\s+/)
  end
end

class Member < Scraped::JSON
  field :id do
    json[:PersonId]
  end

  field :name do
    name_parts.name
  end

  field :honorific_prefix do
    name_parts.prefix
  end

  field :honorific_suffix do
    name_parts.suffix
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

  private

  def reversed_name
    json[:MemberName].split(', ').reverse.join(' ')
  end

  def name_parts
    fragment(reversed_name => MemberName)
  end
end

url = 'http://data.niassembly.gov.uk/members.asmx/GetAllMembers_JSON?'
Scraped::Scraper.new(url => MemberList).store(:members)
