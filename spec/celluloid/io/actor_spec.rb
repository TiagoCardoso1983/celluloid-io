require 'spec_helper'

RSpec.describe Celluloid::IO do
  it_behaves_like "a Celluloid Actor", Celluloid::IO
end
