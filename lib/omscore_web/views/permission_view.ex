defmodule OmscoreWeb.PermissionView do
  use OmscoreWeb, :view
  alias OmscoreWeb.PermissionView

  def render("index.json", %{permissions: permissions, filters: filters}) do
    data = permissions
    |> render_many(PermissionView, "permission.json")
    |> Omscore.Core.apply_attribute_filters(filters)

    %{success: true, data: data}
  end
  def render("index.json", %{permissions: permissions}), do: render("index.json", %{permissions: permissions, filters: []})

  def render("show.json", %{permission: permission, filters: filters}) do
    data = permission
    |> render_one(PermissionView, "permission.json")
    |> Omscore.Core.apply_attribute_filters(filters)

    %{success: true, data: data}
  end
  def render("show.json", %{permission: permission}), do: render("show.json", %{permission: permission, filters: []})

  def render("permission.json", %{permission: permission}) do
    %{id: permission.id,
      scope: permission.scope,
      action: permission.action,
      object: permission.object,
      description: permission.description,
      combined: permission.scope <> ":" <> permission.action <> ":" <> permission.object,
      always_assigned: permission.always_assigned
    }
  end
end
