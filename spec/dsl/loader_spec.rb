require_relative '../../lib/dsl/loader.rb'
require 'spec_helper'

include DSL::Loader
describe DSL::Loader do
 
  describe 'when parsing a single simple Location' do
    let(:data) do
       lambda do
         location :town do
            name 'Viva La Vegas'
            desc 'A great town.'
         end 
       end
    end

    let(:locations) { parse(data) }
    subject { locations.first }
 
    it 'returns a location' do
      should_not be_nil
    end
    
    it 'returns a single Location' do
      locations.length.should == 1
    end
    
    its(:name)            { should == :town }
    its(:long_name)       { should == 'Viva La Vegas' }
    its(:description)     { should == 'A great town.' }
    its(:parent_location) { should be_nil }
    its(:child_locations) { should be_empty }
    its(:connected_locations) { should be_empty }

    it { should_not have_action(:any) } 
         
    it 'still returns only a single Location' do
      locations.length.should == 1
    end
  end
 
  describe 'when parsing hierarchical Locations' do
    let(:data) do
      lambda do

        location :street do
          location :park do
            location :bank do
            end
          end

          location :house do
            location :door do
            end
          end
        end

      end
    end

    let(:locations) { parse(data) }

    it 'returns the correct number of Locations' do
      locations.length.should == 5
    end

    it 'returns the described Locations' do
      names = locations.map {|location| location.name}
      names.should include(:street, :park, :bank, :house, :door)
    end

    it 'return Locations that are correctly connected to their parent Location' do
       parent_hash = {:street => nil, :park => :street, :bank => :park, :house => :street, :door => :house}
      
       locations.each {|location| location.should satisfy {|arg| parent_hash[location.name] == location.parent_location_name}}              
    end

    it 'returns Locations that know their child Locations' do
      hash = {
        :street => [:park, :house],
        :park => [:bank],
        :bank => [],
        :house => [:door],
        :door => []
      }

      locations.each do |location|
        child_location_names = location.child_locations.map {|location| location.name }
        child_location_names.should == hash[location.name]
      end
    end

    it 'returns Locations that are connected to their parent Location and child Locations' do
      hash = {
        :street => [:park, :house],
        :park => [:street, :bank],
        :bank => [:park],
        :house => [:street, :door],
        :door => [:house]
      }

      locations.each do |location|
        location_names = location.connected_locations.map {|location| location.name }
        location_names.should == hash[location.name]
      end
    end
  end

  describe 'when parsing Locations that are remotely connected to other Locations' do
    let(:data) do
      lambda do
        
        location :kitchen do
          remote_locations :living, :cellar
        end

        location :living do
        end

        location :cellar do
        end

      end
    end

    let(:locations) { parse(data) }
    let(:hash) do { 
        :kitchen => [:living, :cellar],
        :living => [:kitchen],
        :cellar => [:kitchen]
      }
    end

    it 'should return Locations that are correctly connected' do
      locations.each do |location|
        location.connected_location_names.should == hash[location.name]
      end
    end

    it 'should return Locations that correctly know
        about the Locations they are remotely connected to' do
      locations.each do |location|
        location.connected_locations.should == location.remote_locations
      end
    end
  end

  describe 'when parsing a Location that includes an Item' do
    let(:data) do
      lambda do
        
        location :table do
          item :coin, 'A silver coin.'

          action :search do
            take :coin
          end
        end

      end
    end

    let(:loc) { parse(data).first }

    it 'returns a Location that has one Item' do
      loc.items.length == 1
    end

    context "then the Item's" do
      subject { loc.items[0] }

      its(:name)        { should == :coin }
      its(:description) { should == 'A silver coin.' }
    end
  end

  describe 'when parsing a Location plus two remote Locations' do
    let(:data) do
      lambda do
        location :main do
          remote_location :rem_1
          remote_location :rem_2
        end
      end
    end

    let(:locations) { parse(data) }
    let(:main) { locations.first }
    let(:rem_1) { locations.at(1) }
    let(:rem_2) { locations.last }

    it 'returns three Locations' do
      locations.should have(3).items
    end

    describe 'returns a main Location that' do
      it 'has two remote Locations' do
        main.remote_locations.should == [rem_1, rem_2]
      end

      it 'has no child Locations' do
        main.child_locations.should be_empty
      end

      it 'has no parent location' do
        main.parent_location.should be_nil
      end
    end

    describe 'returns remote Locations that' do
      it 'are not connected to each-other' do
        rem_1.connected_locations.should == [main]
        rem_2.connected_locations.should == [main]
      end

      it 'are remotely connected to the parent' do
        rem_1.remote_locations.should == [main]
        rem_2.remote_locations.should == [main]
      end

      it 'have no parents' do
        rem_1.parent_location.should be_nil
        rem_2.parent_location.should be_nil
      end
    end
  end

  describe 'when parsing a Location that has various Points of Interest' do
    let(:data) do
      lambda do
        location :wall do
          poi :clock, 'An old wooden clock.'
          poi :painting, 'The painting is plain black.' 
        end
      end
    end

    let(:locations) { parse(data) }
    let(:loc) { locations.first }

    it 'created only one Location' do
      locations.length.should == 1
    end

    describe 'returns a Location that' do
      it 'has all pois' do
        loc.pois.should have(2).items
      end

      it 'has pois with the correct names and descriptions' do
        pois = loc.pois.map {|poi| [poi.name, poi.description]}

        pois.should == [
          [:clock,    'An old wooden clock.'], 
          [:painting, 'The painting is plain black.']
        ]
      end
    end
  end

  describe 'when parsing an errornous script' do

    let(:data) do
      lambda do
        location :wall do
          blbbla_unknown_method
        end
      end
    end

    it 'raises an error' do
      lambda { parse(data) }.should raise_error
    end

  end

end

