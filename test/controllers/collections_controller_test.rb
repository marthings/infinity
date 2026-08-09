require "test_helper"

class CollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
  end

  test "index lists only the signed-in user's collections" do
    get collections_path

    assert_response :success
    assert_select "[data-native-navbar='Collections']"
    assert_select "a[href=?]", new_collection_path, text: "New collection"
    assert_select "a", text: collections(:inspiration).name
    assert_select "a", text: collections(:private).name, count: 0
  end

  test "create saves a collection for the signed-in user" do
    assert_difference -> { users(:one).collections.count }, +1 do
      post collections_path, params: { collection: { name: "Reading" } }
    end

    assert_redirected_to collection_path(Collection.last)
  end

  test "update changes the signed-in user's collection" do
    patch collection_path(collections(:inspiration)), params: { collection: { name: "Ideas" } }

    assert_redirected_to collection_path(collections(:inspiration))
    assert_equal "Ideas", collections(:inspiration).reload.name
  end

  test "show does not expose another user's collection" do
    get collection_path(collections(:private))

    assert_response :not_found
  end

  test "destroy removes a collection without removing its captures" do
    assert_no_difference -> { Capture.count } do
      assert_difference -> { Collection.count }, -1 do
        delete collection_path(collections(:inspiration))
      end
    end

    assert_redirected_to collections_path
  end
end
