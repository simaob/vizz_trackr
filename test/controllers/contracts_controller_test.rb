require 'test_helper'

class ContractsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test 'should get index' do
    sign_in users(:admin)
    get contracts_url
    assert_response :success
  end
end
