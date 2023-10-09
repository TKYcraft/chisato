require 'rails_helper'
require './lib/acl/acl.rb'

RSpec.describe Acl::Acl do
	it "is object of Acl::Acl class" do
		acl = Acl::Acl.new "", App::Application.config.tld_list["TLD"]
		expect(acl.class).to eq(Acl::Acl)
	end
end
