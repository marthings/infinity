require "test_helper"

class CapturesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "index shows only the signed-in user's captures" do
    get captures_path

    assert_response :success
    assert_select "a", text: captures(:link).title
    assert_select "a", text: captures(:note).note, count: 0
  end

  test "create saves a capture for the signed-in user" do
    assert_difference -> { users(:one).captures.count }, +1 do
      post captures_path, params: { capture: { note: "A new idea" } }
    end

    assert_redirected_to capture_path(Capture.last)
  end

  test "create accepts uploads" do
    post captures_path, params: { capture: { uploads: [ fixture_file_upload("inspiration.txt", "text/plain") ] } }

    assert_redirected_to capture_path(Capture.last)
    assert_predicate Capture.last.uploads, :attached?
  end

  test "create renders errors for an empty capture" do
    assert_no_difference -> { Capture.count } do
      post captures_path, params: { capture: { title: " " } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]"
  end

  test "show does not expose another user's capture" do
    get capture_path(captures(:note))

    assert_response :not_found
  end

  test "update changes the signed-in user's capture" do
    patch capture_path(captures(:link)), params: { capture: { title: "Updated link" } }

    assert_redirected_to capture_path(captures(:link))
    assert_equal "Updated link", captures(:link).reload.title
  end

  test "destroy removes the signed-in user's capture" do
    assert_difference -> { Capture.count }, -1 do
      delete capture_path(captures(:link))
    end

    assert_redirected_to captures_path
  end
end
