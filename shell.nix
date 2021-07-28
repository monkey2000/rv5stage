{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [
    pkgs.verilator
    pkgs.gnumake
    pkgs.gcc
    pkgs.glibcLocales
  ];
}
