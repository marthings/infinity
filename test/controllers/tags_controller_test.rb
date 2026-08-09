require "test_helper"

class TagsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "index lists only the signed-in user's tags" do
    get tags_path

    assert_response :success
    assert_select "[data-native-navbar='Tags']"
    assert_select "[data-native-button][data-native-icon='plus'][data-native-href=?]", new_tag_path
    assert_select "a.primary-action.native-hidden[href=?]", new_tag_path, text: "New tag"
    assert_select "a", text: tags(:design).name
    assert_select "a", text: tags(:private).name, count: 0
  end

  test "create normalizes a tag for the signed-in user" do
    assert_difference -> { users(:one).tags.count }, +1 do
      post tags_path, params: { tag: { name: "  Research  " } }
    end

    assert_redirected_to tag_path(Tag.last)
    assert_equal "research", Tag.last.name
  end

  test "update changes the signed-in user's tag" do
    patch tag_path(tags(:design)), params: { tag: { name: "Product" } }

    assert_redirected_to tag_path(tags(:design))
    assert_equal "product", tags(:design).reload.name
  end

  test "show does not expose another user's tag" do
    get tag_path(tags(:private))

    assert_response :not_found
  end

  test "destroy removes a tag without removing its captures" do
    assert_no_difference -> { Capture.count } do
      assert_difference -> { Tag.count }, -1 do
        delete tag_path(tags(:design))
      end
    end

    assert_redirected_to tags_path
  end
end
