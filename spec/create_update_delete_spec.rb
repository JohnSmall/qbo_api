require 'spec_helper'

describe "QboApi Create Update Delete" do

  let(:api){ QboApi.new(creds.to_h) }

  context ".create" do

    after do
      QboApi.request_id = false
    end

    it 'an invoice' do
      invoice = {
        "Line": [
          {
            "Amount": 100.00,
            "DetailType": "SalesItemLineDetail",
            "SalesItemLineDetail": {
              "ItemRef": {
                "value": "1",
                "name": "Services"
              }
            }
          }
        ],
        "CustomerRef": {
          "value": "1"
        }
      }
      use_cassette("qbo_api/create/invoice") do
        response = api.create(:invoice, payload: invoice)
        #p response['Id']
        expect(response['Id']).to_not be_nil
      end
    end

    it 'a customer using a request id' do
      customer = { DisplayName: 'Doe, Jane' }
      QboApi.request_id = true
      use_cassette("qbo_api/create/customer") do
        response = api.create(:customer, payload: customer)
        expect(response['Id']).to_not be_nil
      end
    end
  end

  context '.update' do
    after do
    end

    it 'a customer using a minor version configuration' do
      customer = {
        DisplayName: 'Jack Doe',
        PrimaryPhone: {
          FreeFormNumber: "(415) 444-1234"
        }
      }
      QboApi.minor_version = 8
      use_cassette("qbo_api/update/customer") do
        # Use the id of the created customer above
        response = api.update(:customer, id: 60, payload: customer)
        expect(response.fetch('PrimaryPhone').fetch('FreeFormNumber')).to eq "(415) 444-1234"
      end
      QboApi.minor_version = false
    end

    it 'a sales receipt with minor version and request id set for the individual request' do
      sales_receipt = {
        Line: [
          {
            "Description": "Custom Design",
            "Amount": 337.5,
            "DetailType": "SalesItemLineDetail",
            "SalesItemLineDetail": {
              "ItemRef": {
                "value": "4",
                "name": "Design"
              },
              "UnitPrice": 75,
              "Qty": 4.5,
              "TaxCodeRef": {
                "value": "NON"
              }
            }
          }
        ]
      }
      use_cassette("qbo_api/update/sales_receipt") do
        # SalesReceipt = 17 is part of default sandbox
        response = api.update(:sales_receipt, id: 17, payload: sales_receipt, params: { minorversion: 4, requestid: api.uuid })
        expect(response['SyncToken'].to_i).to be > 0
      end
    end
  end #= end '.update

  context '.delete' do
    it 'an invoice' do
      use_cassette("qbo_api/delete/invoice") do
        # Use the id of the created invoice above
        response = api.delete(:invoice, id: 145)
        expect(response['status']).to eq "Deleted"
      end
    end

    it 'only a transaction entity' do
      expect { response = api.delete(:customer, id: 145) }.to raise_error QboApi::NotImplementedError, /^Delete is only for/
    end
  end

  context '.deactivate' do
    it 'an employee' do
      use_cassette("qbo_api/deactivate/employee") do
        response = api.deactivate(:employee, id: 55)
        expect(response['Active']).to eq false
      end
    end

    it 'an account' do
      use_cassette("qbo_api/deactivate/account") do
        response = api.deactivate(:account, id: 5)
        expect(response['Active']).to eq false
      end
    end

    it 'only a name list entity' do
      expect { response = api.deactivate(:refund_receipt, id: 145) }.to raise_error QboApi::NotImplementedError, /^Deactivate is only for/
    end
  end
end
