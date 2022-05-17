Mix.shell(Mix.Shell.Process)

defmodule Mix.Tasks.Swoosh.Gallery.HtmlTest do
  use ExUnit.Case, async: true

  @moduletag :tmp_dir

  defp run_task(module, path) do
    Mix.Tasks.Swoosh.Gallery.Html.run(["--gallery", inspect(module), "--path", path])
  end

  defp sorted_ls!(path) do
    path
    |> File.ls!()
    |> Enum.sort()
  end

  test "creates the html files", %{tmp_dir: tmp_dir} do
    run_task(Support.Gallery, tmp_dir)
    assert File.dir?(tmp_dir)

    assert sorted_ls!(tmp_dir) == [
             "auth.reset_password",
             "auth.reset_password.html",
             "index.html",
             "welcome",
             "welcome.html"
           ]

    assert sorted_ls!("#{tmp_dir}/auth.reset_password") == ["preview.html"]
    assert sorted_ls!("#{tmp_dir}/welcome") == ["attachments", "preview.html"]
    assert sorted_ls!("#{tmp_dir}/welcome/attachments") == ["0"]
    assert sorted_ls!("#{tmp_dir}/welcome/attachments/0") == ["my_file.txt"]
  end

  describe "generated files" do
    test "lists preview titles", %{tmp_dir: tmp_dir} do
      run_task(Support.Gallery, tmp_dir)
      contents = File.read!("#{tmp_dir}/index.html")
      assert contents =~ "Reset Password"
      assert contents =~ "Welcome"
    end

    test "has links to the previews", %{tmp_dir: tmp_dir} do
      run_task(Support.Gallery, tmp_dir)
      contents = File.read!("#{tmp_dir}/index.html")
      assert contents =~ "a href=\"./auth.reset_password.html\""
      assert contents =~ "a href=\"./welcome.html\""
    end

    test "accessing a preview lists the basic informations", %{tmp_dir: tmp_dir} do
      run_task(Support.Gallery, tmp_dir)
      contents = File.read!("#{tmp_dir}/welcome.html")
      assert contents =~ "Welcome"
      assert contents =~ "Sends a warm welcome to the user"
      assert contents =~ "attachments: yes"
    end

    test "accessing a preview shows the email as text", %{tmp_dir: tmp_dir} do
      run_task(Support.Gallery, tmp_dir)
      contents = File.read!("#{tmp_dir}/auth.reset_password.html")
      assert contents =~ "Reset Password"
      assert contents =~ "Sends instructions on how to reset password"
      assert contents =~ "passwords: yes"
      assert contents =~ "Please, reset your password: http://reset.pw"
    end

    test "accessing a preview.html shows the email as html", %{tmp_dir: tmp_dir} do
      run_task(Support.Gallery, tmp_dir)
      contents = File.read!("#{tmp_dir}/auth.reset_password/preview.html")

      assert contents ==
               "Please, reset your password <a href=\"http://reset.pw\">here</a>."
    end
  end

  test "fails when Gallery is missing", %{tmp_dir: tmp_dir} do
    start_task = fn -> Mix.Tasks.Swoosh.Gallery.Html.run(["--path", tmp_dir]) end

    assert_raise(
      Mix.Error,
      "No gallery available. Please pass a gallery with the --gallery option",
      start_task
    )
  end

  test "fails when Gallery is invalid", %{tmp_dir: tmp_dir} do
    start_task = fn -> run_task(Kernel, tmp_dir) end

    assert_raise(
      Mix.Error,
      ~r/^The module Kernel is not a valid gallery. Make sure it uses Swoosh.Gallery:.*/,
      start_task
    )
  end

  test "fails when path is missing" do
    start_task = fn ->
      Mix.Tasks.Swoosh.Gallery.Html.run(["--gallery", inspect(Support.Gallery)])
    end

    assert_raise(
      Mix.Error,
      "No path available. Please pass a path with the --path option",
      start_task
    )
  end
end
