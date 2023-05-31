{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = [
        (pkgs.python310.withPackages (ps: with ps; [ pip click gdown ]))
        pkgs.fclones
        pkgs.gh
        pkgs.git
        pkgs.git-lfs
        pkgs.github-backup
        pkgs.glab
        pkgs.httrack
        pkgs.jo
        pkgs.jq
        pkgs.lftp
        pkgs.pup
        pkgs.rsync
        pkgs.ruby
        pkgs.wget
        pkgs.xh
    ];
}
