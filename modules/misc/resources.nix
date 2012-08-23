
{config, pkgs, ...}:

let

  inherit (pkgs) lib;
  inherit (builtins) hasAttr attrNames listToAttrs getAttr tail head;
  inherit (pkgs.lib) types mkOption fold filterAttrs maybeAttr mapAttrs;
  # inherit (builtins) ;

  foldAttr = op: nul: attrs:
    assert builtins.isList attrs;
    assert lib.all (builtins.isAttrs) attrs;
    fold (n: a: 
        fold (name: o:
          o // (listToAttrs [{inherit name; value = op (getAttr name n) (maybeAttr name nul a); }])
        ) a (attrNames n)
    ) {} attrs;

  resource = {
    type = mkOption {
      description = "optional. Examples: http,php-fpm-socket,...";
    };
    resource = mkOption {
      type = types.string;
      description = "optional. Examples: http,php-fpm-socket,...";
    };
  };

  options = {

    # move this into a namespace along with fileSystems ?
    resources = lib.mkOption {
      description = ''
        Modules can tell that they provide a resource (such as TCP/IP:80 port running a HTTP service)
        andother modules can query it (eg http caches can verify that a resource is a HTTP service)

        The resource name defines the unsharable resource. Additional names
        such as type can be populated to provide additional information

        Known resource types:
        user and groups: id:number gid:number
        sockets: UDP:port TCP/IP:port
      '';

      # type = types.listOf resource;
      default = [];
      example = 
      [
        { resource = "UDP:80"; type = "iperf speed testing"; }
        { resource = "TCP/IP:80";  type = "http"; }
      ];

      # options = [ resource ];
      /* or
        "UDP:80"    = { type = "iperf speed testing"; }
        "TCP/IP:80" = { type = "http"; }
      */

      # check = lib.all (x: builtins.isAttrs x);

      # attrNameOfListItem = defIdx: elemIdx: elem: elem.resource;
      # merge = fold (x: y: x ++ y) [];
      apply = list:
        let toAttr = i: builtins.listToAttrs [({ name = i.resource; value = i;} )];
            attrWithLists = foldAttr (n: a: a ++ [n]) [] (map toAttr list);
            bad  = filterAttrs (n: v: (tail v) != []) attrWithLists;
            good = mapAttrs (n: v: (head v)) attrWithLists;
        in if bad != {} then throw "These resources are used multiple times: ${lib.concatStringsSep ", " (attrNames bad)}"
           else good;
    };

  };

in
  
{

  require = options;

  # force evaluation:
  assertions = assert (builtins.isAttrs config.resources); [];

}
