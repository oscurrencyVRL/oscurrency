require 'spec_helper'

describe PeopleController do
  fixtures :time_zones, :form_signup_fields

  let(:validated_params) { {name: 'sample name', email: 'email@email.com', business_name: 'business name', business_type: 'business type',
                            password: 'password', password_confirmation: 'password'} }

  describe "#create" do
    context "without metadata" do
      it 'success' do
        expect {
          post :create, {person: validated_params}
        }.to change { Person.count }.by(1)
      end
    end

    context "with metadata" do
      let!(:field) { form_signup_fields(:one) }

      it "success" do
        expect {
          post :create, {person: validated_params.merge({person_metadata_attributes: [{sample_key: 'sample key'}]})}
        }.to change { Person.count }.by(1)
      end
    end
  end
end