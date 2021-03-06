$LOAD_PATH.unshift '../lib'

require 'test/unit'
require 'set'
require 'geocoder/us/address'

include Geocoder::US

class TestAddress < Test::Unit::TestCase
  def test_new
    addr = Address.new("1600 Pennsylvania Av., Washington DC")
    assert_equal "1600 Pennsylvania Av, Washington DC", addr.text
  end
  def test_clean
    fixtures = [
      [ "cleaned text", "cleaned: text!" ],
      [ "cleaned-text 2", "cleaned-text: #2?" ],
      [ "it's working 1/2", "~it's working 1/2~" ],
      [ "it's working, yes", "it's working, yes...?" ],
      [ "it's working & well", "it's working & well?" ]
    ]
    fixtures.each {|output, given|
      assert_equal output, Address.new(given).text
    }
  end
  def test_expand_numbers
    num_list = ["5", "fifth", "five"]
    num_list.each {|n|
      addr = Address.new(n)
      assert_equal num_list, addr.expand_numbers(n).to_a.sort
    }
  end
  def test_city_parse
    places = [
      [ "New York, NY",     "New York", "NY", "" ],
      [ "NY",               "", "NY",   "" ],
      [ "New York",         "New York", "NY",   "" ],
      [ "Philadelphia",     "Philadelphia", "", "" ],
      [ "Philadelphia PA",  "Philadelphia", "PA", "" ],
      [ "Philadelphia, PA", "Philadelphia", "PA", "" ],
      [ "Philadelphia, Pennsylvania", "Philadelphia", "PA", "" ],
      [ "Philadelphia, Pennsylvania 19131", "Philadelphia", "PA", "19131" ],
      [ "Philadelphia 19131", "Philadelphia", "", "19131" ],
      [ "Pennsylvania 19131", "Pennsylvania", "PA", "19131" ], # kind of a misfeature
      [ "19131", "", "", "19131" ],
      [ "19131-9999", "", "", "19131" ],
    ]
    for fixture in places
      addr  = Address.new fixture[0]
      [:city, :state, :zip].zip(fixture[1..3]).each {|key,val|
        result = addr.send key
        result = [result.downcase] unless result.kind_of? Array
        if result.empty?
          assert_equal val, "", key.to_s + " test no result " + fixture.join("/")
        else
          assert result.member?(val.downcase), key.to_s + " test " + result.inspect + fixture.join("/")
        end
      }
    end
  end
  
  def test_po_box
    addr_po = Address.new "PO Box 1111 Herndon VA 20171"
    assert addr_po.po_box?, true 
  end
  
  def test_parse
    addrs = [
      {:text   => "1600 Pennsylvania Av., Washington DC 20050",
       :number => "1600",
       :street => "Pennsylvania Ave",
       :city   => "Washington",
       :state  => "DC",
       :zip    => "20050"},

      {:text   => "1600 Pennsylvania, Washington DC",
       :number => "1600",
       :street => "Pennsylvania",
       :city   => "Washington",
       :state  => "DC"},

      {:text   => "1600 Pennsylvania Washington DC",
       :number => "1600",
       :street => "Pennsylvania Washington",
       :city   => "Pennsylvania Washington", # FIXME
       :state  => "DC"},

      {:text   => "1600 Pennsylvania Washington",
       :number => "1600",
       :street => "Pennsylvania",
       :city   => "Washington",
       :state  => "WA"}, # FIXME

      {:text   => "1600 Pennsylvania 20050",
       :number => "1600",
       :street => "Pennsylvania", # FIXME
       :zip    => "20050"},

      {:text   => "1600 Pennsylvania Av, 20050-9999",
       :number => "1600",
       :street => "Pennsylvania Ave",
       :zip    => "20050"},

      {:text   => "1005 Gravenstein Highway North, Sebastopol CA",
       :number => "1005",
       :street => "Gravenstein Hwy N",
       :city   => "Sebastopol",
       :state  => "CA"},

      {:text   => "100 N 7th St, Brooklyn",
       :number => "100",
       :street => "N 7 St",
       :city   => "Brooklyn"},

      {:text   => "100 N Seventh St, Brooklyn",
       :number => "100",
       :street => "N 7 St",
       :city   => "Brooklyn"},

      {:text   => "100 Central Park West, New York, NY",
       :number => "100",
       :street => "Central Park W",
       :city   => "New York",
       :state  => "NY"},

      {:text   => "100 Central Park West, 10010",
       :number => "100",
       :street => "Central Park W",
       :zip    => "10010"},

      {:text   => "1400 Avenue of the Americas, New York, NY 10019",
       :number => "1400",
       :street => "Ave of the Americas",
       :city   => "New York",
       :state  => "NY"},

      {:text   => "1400 Avenue of the Americas, New York",
       :number => "1400",
       :street => "Ave of the Americas",
       :city   => "New York"},

      {:text   => "1400 Ave of the Americas, New York",
       :number => "1400",
       :street => "Ave of the Americas",
       :city   => "New York"},

      {:text   => "1400 Av of the Americas, New York",
       :number => "1400",
       :street => "Ave of the Americas",
       :city   => "New York"},

      {:text   => "1400 Av of the Americas New York",
       :number => "1400",
       :street => "Ave of the Americas",
       :city   => "New York"},
    ]
    for fixture in addrs
      text = fixture.delete(:text)
      addr = Address.new(text)
      for key, val in fixture
        result = addr.send key
        if result.kind_of? Array
          result.map! {|str| str.downcase}
          assert result.member?(val.downcase), "#{text} (#{key}) = #{result.inspect}"
        else
          assert_equal val, result, "#{text} (#{key}) = #{result.inspect}"
        end
      end
    end
  end
end
