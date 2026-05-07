{ inputs, lib }:
let
  mkHmCfg =
    sys: usr: hst:
    let
      cfg = lib.mkHomeConfiguration sys usr hst;
    in
    cfg // { type = "homeManagerConfiguration"; };
in
{
  "rocha@inspiron" = mkHmCfg "x86_64-linux" "rocha" "inspiron";
  "rocha@glacier" = mkHmCfg "x86_64-linux" "rocha" "glacier";
  "nina@inspiron-nina" = mkHmCfg "x86_64-linux" "nina" "inspiron-nina";
}
