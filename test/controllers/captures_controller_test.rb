require "test_helper"

class CapturesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "index shows only the signed-in user's captures" do
    get captures_path

    assert_response :success
    assert_select "link[rel='stylesheet'][href*='family=Prata']"
    assert_select "[data-native-navbar='']"
    assert_select "[data-native-navbar='Infinity']", count: 0
    assert_select "[data-native-button][data-native-icon='plus'][data-native-href=?]", new_capture_path
    assert_select "header.home-hero.native-inset-top h1", "Save it"
    assert_select "header.home-hero form[data-controller='quick-capture']"
    assert_select "h1", "Save it"
    assert_select "form[data-controller='quick-capture']"
    assert_select "input[name='capture[source_url]'][data-quick-capture-target='link'][placeholder='https://example.com']"
    assert_select "form.quick-capture-form input[type='submit']", count: 0
    assert_select "input[type='file']", count: 0
    assert_select "input[name='capture[collection_ids][]']", count: 0
    assert_select "input[name='capture[tag_ids][]']", count: 0
    assert_select "form.quick-capture-form a[href=?]", new_capture_path, count: 0
    assert_select "a.application-brand[href=?]", root_path, text: "Infinity"
    assert_select "button.menu-toggle[popovertarget='application-menu']"
    assert_select "nav#application-menu[popover='auto'] a[href=?]", collections_path, text: "Collections"
    assert_select "nav#application-menu[popover='auto'] a.menu-create[href=?]", new_capture_path
    assert_select "a.menu-create .menu-create-icon", "+"
    assert_select "a.menu-create span:not(.menu-create-icon)", "Add manually"
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
    assert_select "h1", "Save it"
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

  test "share saves a URL for the signed-in user" do
    assert_difference -> { users(:one).captures.count }, +1 do
      get share_path, params: { url: "https://example.com/from-phone" }
    end

    capture = Capture.last
    assert_redirected_to capture_path(capture)
    assert_equal "https://example.com/from-phone", capture.source_url
    assert_equal users(:one), capture.user
    assert_equal "example.com", capture.title
  end

  test "share extracts an HTTP URL from shared text" do
    assert_difference -> { users(:one).captures.count }, +1 do
      get share_path, params: { text: "Look at this https://example.com/video?v=1 tonight" }
    end

    assert_redirected_to capture_path(Capture.last)
    assert_equal "https://example.com/video?v=1", Capture.last.source_url
  end

  test "share does not create a capture without a session" do
    sign_out

    assert_no_difference -> { Capture.count } do
      get share_path, params: { url: "https://example.com/from-phone" }
    end

    assert_redirected_to new_session_path
  end

  test "share saves the URL after sign-in returns to the share target" do
    sign_out

    get share_path, params: { url: "https://example.com/after-sign-in" }
    assert_redirected_to new_session_path

    post session_path, params: { email_address: users(:one).email_address, password: "password" }
    assert_redirected_to share_url(url: "https://example.com/after-sign-in")

    assert_difference -> { users(:one).captures.count }, +1 do
      follow_redirect!
    end

    assert_redirected_to capture_path(Capture.last)
    assert_equal "https://example.com/after-sign-in", Capture.last.source_url
  end

  test "share rejects a non-web URL" do
    assert_no_difference -> { Capture.count } do
      get share_path, params: { url: "javascript:alert(1)" }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]"
    assert_select "input[name='capture[source_url]'][value='javascript:alert(1)']"
  end

  test "share without a URL opens the capture form" do
    get share_path

    assert_redirected_to new_capture_path
  end

  test "new prefills a shared source URL" do
    get new_capture_path, params: { source_url: "https://example.com/prefill" }

    assert_response :success
    assert_select "input[name='capture[source_url]'][value='https://example.com/prefill']"
  end

  test "destroy removes the signed-in user's capture" do
    assert_difference -> { Capture.count }, -1 do
      delete capture_path(captures(:link))
    end

    assert_redirected_to captures_path
  end
end
