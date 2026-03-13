#
# ~/.nixos/home/modules/git.nix
#
{
  config,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Imnos";
        email = "sbelcl@users.noreply.github.com"; # GitHub noreply email
      };

      init.defaultBranch = "main";
      pull.rebase = false;

      # Better diff algorithm
      diff.algorithm = "histogram";

      # Color output
      color.ui = "auto";

      # Useful aliases
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        graph = "log --graph --oneline --decorate --all";
      };
    };
  };
}
