require 'test_helper'
require 'active_merchant/billing/gateway'
require File.expand_path(File.dirname(__FILE__) + '/../../../../lib/active_merchant/billing/gateways/paypal/paypal_recurring_api')
require 'nokogiri'

class CommonPaypalExpressGateway < ActiveMerchant::Billing::PaypalExpressGateway
  include ActiveMerchant::Billing::PaypalRecurringApi
end

class PaypalRecurringApiTest < Test::Unit::TestCase
  def setup
    @amount = 100
    Base.mode = :test
    CommonPaypalExpressGateway.pem_file = nil

    @gateway = CommonPaypalExpressGateway.new(
      :login => 'cody', 
      :password => 'test',
      :pem => 'PEM'
    )

    @address = { :address1 => '1234 My Street',
                 :address2 => 'Apt 1',
                 :company => 'Widgets Inc',
                 :city => 'Ottawa',
                 :state => 'ON',
                 :zip => 'K1C2N6',
                 :country => 'Canada',
                 :phone => '(555)555-5555'
               }
    @options = { :billing_address => address, :ip => '127.0.0.1' }
    @recurring_required_fields = {:start_date => Date.today, :frequency => :Month, :period => 'Month', :description => 'A description'}
  end

  def xml_builder
    Builder::XmlMarkup.new
  end

  def wrap_xml(&block)
    REXML::Document.new(@gateway.send(:build_request_wrapper, 'Action', &block))
  end

    def test_recurring_requires_description
    @recurring_required_fields.delete(:description)
    assert_raise(ArgumentError){ @gateway.recurring(@amount, @credit_card, @options.merge(@recurring_required_fields)) }
  end

  def test_recurring_requires_start_date
    @recurring_required_fields.delete(:start_date)
    assert_raise(ArgumentError){ @gateway.recurring(@amount, @credit_card, @options.merge(@recurring_required_fields)) }
  end

  def test_recurring_requires_frequency
    @recurring_required_fields.delete(:frequency)
    assert_raise(ArgumentError){ @gateway.recurring(@amount, @credit_card, @options.merge(@recurring_required_fields)) }
  end

  def test_recurring_requires_period
    @recurring_required_fields.delete(:period)
    assert_raise(ArgumentError){ @gateway.recurring(@amount, @credit_card, @options.merge(@recurring_required_fields)) }
  end

  def test_update_recurring_requires_profile_id
    assert_raise(ArgumentError){ @gateway.update_recurring(:amount => 100)}
  end

  def test_cancel_recurring_requires_profile_id
    assert_raise(ArgumentError){ @gateway.cancel_recurring(nil, :note => 'Note')}
  end

  def test_status_recurring_requires_profile_id
    assert_raise(ArgumentError){ @gateway.status_recurring(nil, :note => 'Note')}
  end

  def test_suspend_recurring_requires_profile_id
    assert_raise(ArgumentError){ @gateway.suspend_recurring(nil, :note => 'Note')}
  end

  def test_reactivate_recurring_requires_profile_id
    assert_raise(ArgumentError){ @gateway.reactivate_recurring(nil, :note => 'Note')}
  end

  def test_update_recurring_delegation
    @gateway.expects(:build_change_profile_request).with('I-G7A2FF8V75JY', :amount => 200)
    @gateway.stubs(:commit)
    @gateway.update_recurring(:profile_id => 'I-G7A2FF8V75JY', :amount => 200)
  end

  def test_update_recurring_response
    @gateway.expects(:ssl_post).returns(successful_update_recurring_payment_profile_response)
    response = @gateway.update_recurring(:profile_id => 'I-G7A2FF8V75JY', :amount => 200)
    assert response.success?
  end

  def test_cancel_recurring_delegation
    @gateway.expects(:build_manage_profile_request).with('I-G7A2FF8V75JY', 'Cancel', :note => 'A Note').returns(:cancel_request)
    @gateway.expects(:commit).with('ManageRecurringPaymentsProfileStatus', :cancel_request)
    @gateway.cancel_recurring('I-G7A2FF8V75JY', :note => 'A Note')
  end

  def test_suspend_recurring_delegation
    @gateway.expects(:build_manage_profile_request).with('I-G7A2FF8V75JY', 'Suspend', :note => 'A Note').returns(:request)
    @gateway.expects(:commit).with('ManageRecurringPaymentsProfileStatus', :request)
    @gateway.suspend_recurring('I-G7A2FF8V75JY', :note => 'A Note')
  end

  def test_reactivate_recurring_delegation
    @gateway.expects(:build_manage_profile_request).with('I-G7A2FF8V75JY', 'Reactivate', :note => 'A Note').returns(:request)
    @gateway.expects(:commit).with('ManageRecurringPaymentsProfileStatus', :request)
    @gateway.reactivate_recurring('I-G7A2FF8V75JY', :note => 'A Note')
  end

  def test_status_recurring_delegation
    @gateway.expects(:build_get_profile_details_request).with('I-G7A2FF8V75JY').returns(:request)
    @gateway.expects(:commit).with('GetRecurringPaymentsProfileDetails', :request)
    @gateway.status_recurring('I-G7A2FF8V75JY')
  end

  def test_status_recurring_response
    @gateway.expects(:ssl_post).returns(succesful_get_recurring_payments_profile_response)
    response = @gateway.status_recurring('I-M1L3RX91DPDD')
    assert response.success?
    assert_equal 'I-M1L3RX91DPDD', response.params['profile_id']
  end

  private
  def successful_update_recurring_payment_profile_response
    <<-RESPONSE
    <?xml version=\"1.0\" encoding=\"UTF-8\"?><SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" xmlns:cc=\"urn:ebay:apis:CoreComponentTypes\" xmlns:wsu=\"http://schemas.xmlsoap.org/ws/2002/07/utility\" xmlns:saml=\"urn:oasis:names:tc:SAML:1.0:assertion\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\" xmlns:wsse=\"http://schemas.xmlsoap.org/ws/2002/12/secext\" xmlns:ed=\"urn:ebay:apis:EnhancedDataTypes\" xmlns:ebl=\"urn:ebay:apis:eBLBaseComponents\" xmlns:ns=\"urn:ebay:api:PayPalAPI\"><SOAP-ENV:Header><Security xmlns=\"http://schemas.xmlsoap.org/ws/2002/12/secext\" xsi:type=\"wsse:SecurityType\"></Security><RequesterCredentials xmlns=\"urn:ebay:api:PayPalAPI\" xsi:type=\"ebl:CustomSecurityHeaderType\"><Credentials xmlns=\"urn:ebay:apis:eBLBaseComponents\" xsi:type=\"ebl:UserIdPasswordType\"><Username xsi:type=\"xs:string\"></Username><Password xsi:type=\"xs:string\"></Password><Signature xsi:type=\"xs:string\"></Signature><Subject xsi:type=\"xs:string\"></Subject></Credentials></RequesterCredentials></SOAP-ENV:Header><SOAP-ENV:Body id=\"_0\">
    <UpdateRecurringPaymentsProfileResponse xmlns=\"urn:ebay:api:PayPalAPI\">
      <Timestamp xmlns=\"urn:ebay:apis:eBLBaseComponents\">2012-03-19T20:30:02Z</Timestamp>
      <Ack xmlns=\"urn:ebay:apis:eBLBaseComponents\">Success</Ack>
      <CorrelationID xmlns=\"urn:ebay:apis:eBLBaseComponents\">9ad0f67c1127c</CorrelationID>
      <Version xmlns=\"urn:ebay:apis:eBLBaseComponents\">72</Version>
      <Build xmlns=\"urn:ebay:apis:eBLBaseComponents\">2649250</Build>
      <UpdateRecurringPaymentsProfileResponseDetails xmlns=\"urn:ebay:apis:eBLBaseComponents\" xsi:type=\"ebl:UpdateRecurringPaymentsProfileResponseDetailsType\">
        <ProfileID xsi:type=\"xs:string\">I-M1L3RX91DPDD</ProfileID>
      </UpdateRecurringPaymentsProfileResponseDetails>
    </UpdateRecurringPaymentsProfileResponse>
  </SOAP-ENV:Body></SOAP-ENV:Envelope>
    RESPONSE
  end

  def successful_manage_recurring_payment_profile_response 
    <<-RESPONSE
    <?xml version=\"1.0\" encoding=\"UTF-8\"?><SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" xmlns:cc=\"urn:ebay:apis:CoreComponentTypes\" xmlns:wsu=\"http://schemas.xmlsoap.org/ws/2002/07/utility\" xmlns:saml=\"urn:oasis:names:tc:SAML:1.0:assertion\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\" xmlns:wsse=\"http://schemas.xmlsoap.org/ws/2002/12/secext\" xmlns:ed=\"urn:ebay:apis:EnhancedDataTypes\" xmlns:ebl=\"urn:ebay:apis:eBLBaseComponents\" xmlns:ns=\"urn:ebay:api:PayPalAPI\"><SOAP-ENV:Header><Security xmlns=\"http://schemas.xmlsoap.org/ws/2002/12/secext\" xsi:type=\"wsse:SecurityType\"></Security><RequesterCredentials xmlns=\"urn:ebay:api:PayPalAPI\" xsi:type=\"ebl:CustomSecurityHeaderType\"><Credentials xmlns=\"urn:ebay:apis:eBLBaseComponents\" xsi:type=\"ebl:UserIdPasswordType\"><Username xsi:type=\"xs:string\"></Username><Password xsi:type=\"xs:string\"></Password><Signature xsi:type=\"xs:string\"></Signature><Subject xsi:type=\"xs:string\"></Subject></Credentials></RequesterCredentials></SOAP-ENV:Header>
    <SOAP-ENV:Body id=\"_0\">
    <ManageRecurringPaymentsProfileStatusResponse xmlns=\"urn:ebay:api:PayPalAPI\"><Timestamp xmlns=\"urn:ebay:apis:eBLBaseComponents\">2012-03-19T20:41:03Z</Timestamp><Ack xmlns=\"urn:ebay:apis:eBLBaseComponents\">Success</Ack><CorrelationID xmlns=\"urn:ebay:apis:eBLBaseComponents\">3c02ea62138c4</CorrelationID><Version xmlns=\"urn:ebay:apis:eBLBaseComponents\">72</Version><Build xmlns=\"urn:ebay:apis:eBLBaseComponents\">2649250</Build><ManageRecurringPaymentsProfileStatusResponseDetails xmlns=\"urn:ebay:apis:eBLBaseComponents\" xsi:type=\"ebl:ManageRecurringPaymentsProfileStatusResponseDetailsType\"><ProfileID xsi:type=\"xs:string\">I-M1L3RX91DPDD</ProfileID></ManageRecurringPaymentsProfileStatusResponseDetails></ManageRecurringPaymentsProfileStatusResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>
    RESPONSE
  end


  def succesful_get_recurring_payments_profile_response
    <<-RESPONSE
    <?xml version=\"1.0\" encoding=\"UTF-8\"?><SOAP-ENV:Envelope xmlns:SOAP-ENV=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:SOAP-ENC=\"http://schemas.xmlsoap.org/soap/encoding/\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns:xs=\"http://www.w3.org/2001/XMLSchema\" xmlns:cc=\"urn:ebay:apis:CoreComponentTypes\" xmlns:wsu=\"http://schemas.xmlsoap.org/ws/2002/07/utility\" xmlns:saml=\"urn:oasis:names:tc:SAML:1.0:assertion\" xmlns:ds=\"http://www.w3.org/2000/09/xmldsig#\" xmlns:wsse=\"http://schemas.xmlsoap.org/ws/2002/12/secext\" xmlns:ed=\"urn:ebay:apis:EnhancedDataTypes\" xmlns:ebl=\"urn:ebay:apis:eBLBaseComponents\" xmlns:ns=\"urn:ebay:api:PayPalAPI\"><SOAP-ENV:Header><Security xmlns=\"http://schemas.xmlsoap.org/ws/2002/12/secext\" xsi:type=\"wsse:SecurityType\"></Security><RequesterCredentials xmlns=\"urn:ebay:api:PayPalAPI\" xsi:type=\"ebl:CustomSecurityHeaderType\"><Credentials xmlns=\"urn:ebay:apis:eBLBaseComponents\" xsi:type=\"ebl:UserIdPasswordType\"><Username xsi:type=\"xs:string\"></Username><Password xsi:type=\"xs:string\"></Password><Signature xsi:type=\"xs:string\"></Signature><Subject xsi:type=\"xs:string\"></Subject></Credentials></RequesterCredentials></SOAP-ENV:Header><SOAP-ENV:Body id=\"_0\"><GetRecurringPaymentsProfileDetailsResponse xmlns=\"urn:ebay:api:PayPalAPI\"><Timestamp xmlns=\"urn:ebay:apis:eBLBaseComponents\">2012-03-19T21:34:40Z</Timestamp><Ack xmlns=\"urn:ebay:apis:eBLBaseComponents\">Success</Ack><CorrelationID xmlns=\"urn:ebay:apis:eBLBaseComponents\">6f24b53c49232</CorrelationID><Version xmlns=\"urn:ebay:apis:eBLBaseComponents\">72</Version><Build xmlns=\"urn:ebay:apis:eBLBaseComponents\">2649250</Build><GetRecurringPaymentsProfileDetailsResponseDetails xmlns=\"urn:ebay:apis:eBLBaseComponents\" xsi:type=\"ebl:GetRecurringPaymentsProfileDetailsResponseDetailsType\"><ProfileID xsi:type=\"xs:string\">I-M1L3RX91DPDD</ProfileID><ProfileStatus xsi:type=\"ebl:RecurringPaymentsProfileStatusType\">CancelledProfile</ProfileStatus><Description xsi:type=\"xs:string\">A description</Description><AutoBillOutstandingAmount xsi:type=\"ebl:AutoBillType\">NoAutoBill</AutoBillOutstandingAmount><MaxFailedPayments>0</MaxFailedPayments><RecurringPaymentsProfileDetails xsi:type=\"ebl:RecurringPaymentsProfileDetailsType\"><SubscriberName xsi:type=\"xs:string\">Ryan Bates</SubscriberName><SubscriberShippingAddress xsi:type=\"ebl:AddressType\"><Name xsi:type=\"xs:string\"></Name><Street1 xsi:type=\"xs:string\"></Street1><Street2 xsi:type=\"xs:string\"></Street2><CityName xsi:type=\"xs:string\"></CityName><StateOrProvince xsi:type=\"xs:string\"></StateOrProvince><CountryName></CountryName><Phone xsi:type=\"xs:string\"></Phone><PostalCode xsi:type=\"xs:string\"></PostalCode><AddressID xsi:type=\"xs:string\"></AddressID><AddressOwner xsi:type=\"ebl:AddressOwnerCodeType\">PayPal</AddressOwner><ExternalAddressID xsi:type=\"xs:string\"></ExternalAddressID><AddressStatus xsi:type=\"ebl:AddressStatusCodeType\">Unconfirmed</AddressStatus></SubscriberShippingAddress><BillingStartDate xsi:type=\"xs:dateTime\">2012-03-19T11:00:00Z</BillingStartDate></RecurringPaymentsProfileDetails><CurrentRecurringPaymentsPeriod xsi:type=\"ebl:BillingPeriodDetailsType\"><BillingPeriod xsi:type=\"ebl:BillingPeriodTypeType\">Month</BillingPeriod><BillingFrequency>1</BillingFrequency><TotalBillingCycles>0</TotalBillingCycles><Amount xsi:type=\"cc:BasicAmountType\" currencyID=\"USD\">1.23</Amount><ShippingAmount xsi:type=\"cc:BasicAmountType\" currencyID=\"USD\">0.00</ShippingAmount><TaxAmount xsi:type=\"cc:BasicAmountType\" currencyID=\"USD\">0.00</TaxAmount></CurrentRecurringPaymentsPeriod><RecurringPaymentsSummary xsi:type=\"ebl:RecurringPaymentsSummaryType\"><NumberCyclesCompleted>1</NumberCyclesCompleted><NumberCyclesRemaining>-1</NumberCyclesRemaining><OutstandingBalance xsi:type=\"cc:BasicAmountType\" currencyID=\"USD\">1.23</OutstandingBalance><FailedPaymentCount>1</FailedPaymentCount></RecurringPaymentsSummary><CreditCard xsi:type=\"ebl:CreditCardDetailsType\"><CreditCardType xsi:type=\"ebl:CreditCardTypeType\">Visa</CreditCardType><CreditCardNumber xsi:type=\"xs:string\">3576</CreditCardNumber><ExpMonth>1</ExpMonth><ExpYear>2013</ExpYear><CardOwner xsi:type=\"ebl:PayerInfoType\"><PayerStatus xsi:type=\"ebl:PayPalUserStatusCodeType\">unverified</PayerStatus><PayerName xsi:type=\"ebl:PersonNameType\"><FirstName xmlns=\"urn:ebay:apis:eBLBaseComponents\">Ryan</FirstName><LastName xmlns=\"urn:ebay:apis:eBLBaseComponents\">Bates</LastName></PayerName><Address xsi:type=\"ebl:AddressType\"><AddressOwner xsi:type=\"ebl:AddressOwnerCodeType\">PayPal</AddressOwner><AddressStatus xsi:type=\"ebl:AddressStatusCodeType\">Unconfirmed</AddressStatus></Address></CardOwner><StartMonth>0</StartMonth><StartYear>0</StartYear><ThreeDSecureRequest xsi:type=\"ebl:ThreeDSecureRequestType\"></ThreeDSecureRequest></CreditCard><RegularRecurringPaymentsPeriod xsi:type=\"ebl:BillingPeriodDetailsType\"><BillingPeriod xsi:type=\"ebl:BillingPeriodTypeType\">Month</BillingPeriod><BillingFrequency>1</BillingFrequency><TotalBillingCycles>0</TotalBillingCycles><Amount xsi:type=\"cc:BasicAmountType\" currencyID=\"USD\">1.23</Amount><ShippingAmount xsi:type=\"cc:BasicAmountType\" currencyID=\"USD\">0.00</ShippingAmount><TaxAmount xsi:type=\"cc:BasicAmountType\" currencyID=\"USD\">0.00</TaxAmount></RegularRecurringPaymentsPeriod><TrialAmountPaid xsi:type=\"cc:BasicAmountType\" currencyID=\"USD\">0.00</TrialAmountPaid><RegularAmountPaid xsi:type=\"cc:BasicAmountType\" currencyID=\"USD\">0.00</RegularAmountPaid><AggregateAmount xsi:type=\"cc:BasicAmountType\" currencyID=\"USD\">0.00</AggregateAmount><AggregateOptionalAmount xsi:type=\"cc:BasicAmountType\" currencyID=\"USD\">0.00</AggregateOptionalAmount><FinalPaymentDueDate xsi:type=\"xs:dateTime\">1970-01-01T00:00:00Z</FinalPaymentDueDate></GetRecurringPaymentsProfileDetailsResponseDetails></GetRecurringPaymentsProfileDetailsResponse></SOAP-ENV:Body></SOAP-ENV:Envelope>
    RESPONSE
  end
end
