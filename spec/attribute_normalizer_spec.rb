require File.dirname(__FILE__) + '/test_helper'
require 'attribute_normalizer'

describe AttributeNormalizer do

  it 'should add the class method Class#normalize_attributes when included' do

    klass = Class.new do
      include AttributeNormalizer
    end

    klass.respond_to?(:normalize_attributes).should be_true
  end

end

describe '#normalize_attributes without a block' do

  before do

    class Klass
      attr_accessor :attribute
      include AttributeNormalizer
      normalize_attributes :attribute
    end

  end

  {
    ' spaces in front and back ' => 'spaces in front and back',
    "\twe hate tabs!\t"          => 'we hate tabs!'
  }.each do |key, value|
    it "should normalize '#{key}' to '#{value}'" do
      Klass.send(:normalize_attribute, key).should == value
    end
  end

end

describe '#normalize_attributes with a block' do

  before do

    class Klass
      attr_accessor :attribute
      include AttributeNormalizer
      normalize_attributes :attribute do |value|
        value = value.strip.upcase if value.is_a?(String)
        value = value * 2          if value.is_a?(Fixnum)
        value = value * 0.5        if value.is_a?(Float)
        value
      end
    end

    @object = Klass.new

  end

  {
    "\tMichael Deering" => 'MICHAEL DEERING',
    2                   => 4,
    2.0                 => 1.0
  }.each do |key, value|
    it "should normalize '#{key}' to '#{value}'" do
      Klass.send(:normalize_attribute, key).should == value
    end
  end

end

describe 'with an instance' do

  before do
    User.class_eval do
      normalize_attributes :name
    end
    @user = User.new
  end

  {
    ' spaces in front and back ' => 'spaces in front and back',
    "\twe hate tabs!\t"          => 'we hate tabs!'
  }.each do |key, value|
    it "should normalize '#{key}' to '#{value}'" do
      @user.name = key
      @user.name.should == value
    end
  end

  context 'when another instance of the same saved record has been changed' do

    before do
      @user = User.create!(:name => 'Jimi Hendrix')
      @user2 = User.find(@user.id)
      @user2.update_attributes(:name => 'Thom Yorke')
    end

    it "should reflect the change when the record is reloaded" do
      lambda { @user.reload }.should change(@user, :name).from('Jimi Hendrix').to('Thom Yorke')
    end
  end

end

describe "#normalize_attributes on write" do

  before do

    class Klass
      attr_accessor :height
      include AttributeNormalizer
      normalize_attributes :height, :on => :write do |value|
        value * 12
      end
      def [](attr)
        instance_variable_get "@#{attr}".to_sym
      end
      def []=(attr, value)
        instance_variable_set "@#{attr}".to_sym, value
      end
      def raw_height=(value)
        @height = value
      end
    end
    @subject = Klass.new
  end

  it "should assign normalized value" do
    @subject.height = 1
    @subject.height.should == 12
  end

  it "should return unchanged value" do
    @subject.raw_height = 12
    @subject.height.should == 12
  end

end

describe "#normalize_attributes on read" do

  before do

    class Klass
      attr_accessor :height
      include AttributeNormalizer
      normalize_attributes :height, :on => :read do |value|
        value * 12
      end
      def [](attr)
        instance_variable_get "@#{attr}".to_sym
      end
      def []=(attr, value)
        instance_variable_set "@#{attr}".to_sym, value
      end
      def raw_height
        @height
      end
    end
    @subject = Klass.new
  end

  it "should assign unchanged value" do
    @subject.height = 1
    @subject.raw_height.should == 1
  end

  it "should return normalized value" do
    @subject.height = 1
    @subject.height.should == 12
  end

end

describe 'normalize_attribute is aliased to normalize_attributes' do
  before do
    User.class_eval do
      normalize_attribute :name
    end
    @user = User.new
  end

  {
    ' spaces in front and back ' => 'spaces in front and back',
    "\twe hate tabs!\t"          => 'we hate tabs!'
  }.each do |key, value|
    it "should normalize '#{key}' to '#{value}'" do
      @user.name = key
      @user.name.should == value
    end
  end

end
