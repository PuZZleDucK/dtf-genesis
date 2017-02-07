require 'test_helper'

class ContractsControllerTest < ActionDispatch::IntegrationTest

  test "should get contract list" do
    @user = admin_users(:one)
    login_as @user, scope: :user
    get contracts_path
    assert_response :success
  end

  test "non logged in user should see contract list" do
    get contracts_path
    assert_response :success
  end


end
