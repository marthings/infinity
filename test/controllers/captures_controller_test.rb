require "test_helper"

class CapturesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "index shows only the signed-in user's captures" do
    get captures_path

    assert_response :success
    assert_select "link[rel='stylesheet'][href*='family=Prata']"
    assert_select "[data-native-navbar='Infinity']", count: 0
    assert_select "header.home-hero.native-inset-top h1", "Infinity"
    assert_select "header.home-hero form[data-controller='quick-capture']"
    assert_select "h1", "Infinity"
    assert_select "form[data-controller='quick-capture']"
    assert_select "input[name='capture[source_url]'][data-quick-capture-target='link'][placeholder='https://example.com']"
    assert_select "form.quick-capture-form input[type='submit']", count: 0
    assert_select "input[type='file']", count: 0
    assert_select "input[name='capture[collection_ids][]']", count: 0
    assert_select "input[name='capture[tag_ids][]']", count: 0
    assert_select "a[href=?]", new_capture_path, text: "Add manually"
    assert_select "nav.application-navigation a[href=?]", collections_path, text: "Collections"
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
    assert_equal "inspiration.txt", Capture.last.title
  end

  test "quick capture generates a title from a link hostname" do
    post captures_path, params: { capture: { source_url: "https://www.youtube.com/watch?v=example" }, capture_form: "quick" }

    assert_redirected_to capture_path(Capture.last)
    assert_equal "youtube.com", Capture.last.title
  end

  test "create renders errors for an empty capture" do
    assert_no_difference -> { Capture.count } do
      post captures_path, params: { capture: { title: " " } }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]"
  end

  test "quick capture returns errors to the inbox" do
    post captures_path, params: { capture: { source_url: " " }, capture_form: "quick" }

    assert_response :unprocessable_entity
    assert_select "h1", "Infinity"
    assert_select "[role=alert]"
  end

  test "new provides native navigation" do
    get new_capture_path

    assert_response :success
    assert_select "[data-native-form]"
    assert_select "[data-native-navbar='New capture']"
    assert_select "h1.native-hidden", "New capture"
    assert_select "a.native-hidden", "Back to captures"
    assert_select "input[name='capture[collection_ids][]'][value=?]", collections(:inspiration).id.to_s
    assert_select "input[name='capture[tag_ids][]'][value=?]", tags(:design).id.to_s
    assert_select "input[name='capture[title]'][placeholder='e.g. Studio inspiration']"
  end

  test "edit provides native form navigation" do
    get edit_capture_path(captures(:link))

    assert_response :success
    assert_select "[data-native-form]"
    assert_select "[data-native-navbar='Edit capture']"
    assert_select "h1.native-hidden", "Edit capture"
    assert_select "a.native-hidden", "Back to capture"
  end

  test "show does not expose another user's capture" do
    get capture_path(captures(:note))

    assert_response :not_found
  end

  test "show provides native navigation for a capture" do
    get capture_path(captures(:link))

    assert_response :success
    assert_select "[data-native-navbar=?]", captures(:link).title
    assert_select "h1.native-hidden", captures(:link).title
    assert_select "a.native-hidden", "Back to captures"
  end

  test "update changes the signed-in user's capture" do
    patch capture_path(captures(:link)), params: { capture: { title: "Updated link" } }

    assert_redirected_to capture_path(captures(:link))
    assert_equal "Updated link", captures(:link).reload.title
  end

  test "create assigns the signed-in user's collections and tags" do
    assert_difference -> { CollectionCapture.count }, +1 do
      assert_difference -> { Tagging.count }, +1 do
        post captures_path, params: { capture: { note: "An organized idea", collection_ids: [ collections(:inspiration).id ], tag_ids: [ tags(:design).id ] } }
      end
    end

    capture = Capture.last
    assert_equal [ collections(:inspiration) ], capture.collections.to_a
    assert_equal [ tags(:design) ], capture.tags.to_a
  end

  test "create does not assign another user's collections or tags" do
    post captures_path, params: { capture: { note: "A private idea", collection_ids: [ collections(:private).id ], tag_ids: [ tags(:private).id ] } }

    assert_redirected_to capture_path(Capture.last)
    assert_empty Capture.last.collections
    assert_empty Capture.last.tags
  end

  test "update removes a capture from collections and tags" do
    patch capture_path(captures(:link)), params: { capture: { collection_ids: [ "" ], tag_ids: [ "" ] } }

    assert_redirected_to capture_path(captures(:link))
    assert_empty captures(:link).reload.collections
    assert_empty captures(:link).tags
  end

  test "destroy removes the signed-in user's capture" do
    assert_difference -> { Capture.count }, -1 do
      delete capture_path(captures(:link))
    end

    assert_redirected_to captures_path
  end
end
