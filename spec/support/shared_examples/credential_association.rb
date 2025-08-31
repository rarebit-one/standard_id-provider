RSpec.shared_examples "a credentialable" do
  it { is_expected.to have_one(:credential) }
end
