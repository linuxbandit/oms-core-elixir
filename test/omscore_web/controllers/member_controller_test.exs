defmodule OmscoreWeb.MemberControllerTest do
  use OmscoreWeb.ConnCase

  alias Omscore.Members
  alias Omscore.Members.Member

  @create_attrs %{about_me: "some about_me", address: "some address", date_of_birth: ~D[2010-04-17], first_name: "some first_name", gender: "some gender", last_name: "some last_name", phone: "+1212345678", user_id: 42}
  @update_attrs %{about_me: "some updated about_me", address: "some updated address", date_of_birth: ~D[2011-05-18], first_name: "some updated first_name", gender: "some updated gender", last_name: "some updated last_name", phone: "+1212345679", seo_url: "some_updated_seo_url", user_id: 43}
  @invalid_attrs %{about_me: nil, address: nil, date_of_birth: nil, first_name: nil, gender: nil, last_name: nil, phone: nil, seo_url: nil, user_id: nil}

  def fixture(:member) do
    {:ok, member} = Members.create_member(@create_attrs)
    member
  end

  def create_many_members(id_range) do
    id_range
    |> Enum.map(fn(x) -> 
      {:ok, member} = Members.create_member(@create_attrs |> Map.put(:user_id, x))
      member
    end)
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all members", %{conn: conn} do
      %{token: token, member: member} = create_member_with_permissions([%{action: "view", object: "member"}])
      conn = put_req_header(conn, "x-auth-token", token)

      conn = get conn, member_path(conn, :index)
      assert json_response(conn, 200)["data"] |> Enum.any?(fn(x) -> x["id"] == member.id end)
    end

    test "lists all members with data", %{conn: conn} do
      %{token: token} = create_member_with_permissions([%{action: "view", object: "member"}])
      conn = put_req_header(conn, "x-auth-token", token)

      members = create_many_members(0..100)

      conn = get conn, member_path(conn, :index)
      assert res = json_response(conn, 200)["data"]
      assert members |> Enum.all?(fn(x) -> Enum.find(res, fn(y) -> x.id == y["id"] end) != nil end)
    end

    test "paginates the request if pagination data is passed", %{conn: conn} do
      %{token: token} = create_member_with_permissions([%{action: "view", object: "member"}])
      conn = put_req_header(conn, "x-auth-token", token)

      create_many_members(0..100)

      conn = get conn, member_path(conn, :index), limit: 10, offset: 0
      assert res = json_response(conn, 200)["data"]
      assert Enum.count(res) == 10
    end

    test "searches the result if query is passed", %{conn: conn} do
      %{token: token} = create_member_with_permissions([%{action: "view", object: "member"}])
      conn = put_req_header(conn, "x-auth-token", token)

      create_many_members(0..100)

      conn = get conn, member_path(conn, :index), query: "some really exotic query that definitely doesn't match any member at all"
      assert json_response(conn, 200)["data"] == []
    end

    test "rejects the request to unauthorized user", %{conn: conn} do
      %{token: token} = create_member_with_permissions([])
      conn = put_req_header(conn, "x-auth-token", token)

      conn = get conn, member_path(conn, :index)
      assert json_response(conn, 403)
    end
  end

  describe "create member" do
    test "renders member when data is valid", %{conn: conn} do
      %{token: token} = create_member_with_permissions([%{action: "create", object: "member"}])
      conn = put_req_header(conn, "x-auth-token", token)

      conn = post conn, member_path(conn, :create), member: @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get conn, member_path(conn, :show, id)
      assert json_response(conn, 200)["data"] |> map_inclusion(%{
        "id" => id,
        "about_me" => "some about_me",
        "address" => "some address",
        "date_of_birth" => "2010-04-17",
        "first_name" => "some first_name",
        "gender" => "some gender",
        "last_name" => "some last_name",
        "phone" => "+1212345678",
        "user_id" => 42})
    end

    test "renders errors when data is invalid", %{conn: conn} do
      %{token: token} = create_member_with_permissions([%{action: "create", object: "member"}])
      conn = put_req_header(conn, "x-auth-token", token)

      conn = post conn, member_path(conn, :create), member: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end

    test "rejects the request to unauthorized user", %{conn: conn} do
      %{token: token} = create_member_with_permissions([])
      conn = put_req_header(conn, "x-auth-token", token)

      conn = post conn, member_path(conn, :create), member: @create_attrs
      assert json_response(conn, 403)
    end
  end

  describe "update member" do
    setup [:create_member]

    test "renders member when data is valid", %{conn: conn, member: %Member{id: id} = member} do
      conn = put conn, member_path(conn, :update, member), member: @update_attrs
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, member_path(conn, :show, id)
      assert json_response(conn, 200)["data"] == %{
        "id" => id,
        "about_me" => "some updated about_me",
        "address" => "some updated address",
        "date_of_birth" => "2011-05-18",
        "first_name" => "some updated first_name",
        "gender" => "some updated gender",
        "last_name" => "some updated last_name",
        "phone" => "+1212345679",
        "seo_url" => "some_updated_seo_url",
        "user_id" => 42}
    end

    test "renders errors when data is invalid", %{conn: conn, member: member} do
      conn = put conn, member_path(conn, :update, member), member: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete member" do
    setup [:create_member]

    test "deletes chosen member", %{conn: conn, member: member} do
      conn = delete conn, member_path(conn, :delete, member)
      assert response(conn, 204)
      assert_error_sent 404, fn ->
        get conn, member_path(conn, :show, member)
      end
    end
  end

  defp create_member(_) do
    member = fixture(:member)
    {:ok, member: member}
  end
end
