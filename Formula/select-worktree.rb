# git is not declared as a dependency. It is present wherever git worktrees
# are, and the same choice is made by comparable shell tools in homebrew-core.
class SelectWorktree < Formula
  desc "Switch between git worktrees in your current shell"
  homepage "https://github.com/anshul-chandan/git-select-worktree"
  url "https://github.com/anshul-chandan/git-select-worktree/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "e3a46280ea96203cc96c9debd7ebf48800ebaaff6686970afbfb924c61aa8c52"
  license "MIT"
  head "https://github.com/anshul-chandan/git-select-worktree.git", branch: "main"

  # Completion scripts are deliberately not installed. Users opt in with
  # `swt completion -s <shell>`, as described in the caveats.
  def install
    pkgshare.install "select-worktree.sh"
  end

  def caveats
    <<~EOS
      select-worktree has to be sourced into your shell rather than run as a
      command. It changes your working directory, and a separate process
      cannot do that to its parent.

      Add this to your ~/.zshrc or ~/.bashrc:

        [ -f #{opt_pkgshare}/select-worktree.sh ] && . #{opt_pkgshare}/select-worktree.sh

      That defines both `select-worktree` and its short form `swt`.
      Start a new shell afterwards:

        exec $SHELL

      Tab completion is optional. For instructions, run:

        swt completion --help
    EOS
  end

  test do
    # A repository with one linked worktree is enough to prove the function
    # both loads and moves the shell that sourced it.
    system "git", "init", "-q", testpath/"main"
    touch testpath/"main/file.txt"
    system "git", "-C", testpath/"main", "add", "file.txt"
    system "git", "-C", testpath/"main",
           "-c", "user.name=brew test",
           "-c", "user.email=test@example.com",
           "commit", "-qm", "initial commit"
    system "git", "-C", testpath/"main", "branch", "other"
    system "git", "-C", testpath/"main", "worktree", "add", "-q",
           testpath/"wt-other", "other"

    expected = (testpath/"wt-other").realpath.to_s

    # The short name.
    swt = [
      ". #{pkgshare}/select-worktree.sh",
      "cd #{testpath}/main",
      "swt other >/dev/null",
      "pwd",
    ].join("; ")
    assert_equal expected, shell_output("bash -c '#{swt}'").strip

    # The long name has to behave identically; they are one function.
    long = [
      ". #{pkgshare}/select-worktree.sh",
      "cd #{testpath}/main",
      "select-worktree other >/dev/null",
      "pwd",
    ].join("; ")
    assert_equal expected, shell_output("bash -c '#{long}'").strip

    # Listing works without switching.
    list = [
      ". #{pkgshare}/select-worktree.sh",
      "cd #{testpath}/main",
      "swt --list",
    ].join("; ")
    assert_match "other", shell_output("bash -c '#{list}'")

    # Completion scripts are printed on request, never installed.
    zsh_script = shell_output("bash -c '. #{pkgshare}/select-worktree.sh; swt completion -s zsh'")
    assert_match "#compdef select-worktree swt", zsh_script
  end
end
