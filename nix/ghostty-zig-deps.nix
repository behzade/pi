{
  fetchgit,
  fetchurl,
  fetchzip,
  lib,
  runCommandLocal,
  zig_0_16,
}:

let
  # gpui-libghostty 0.1.4 vendors Ghostty 9f0e1719. This is the package set
  # requested by Pi's library-only build, plus its nested Zig dependencies.
  unpackZigArtifact =
    name: artifact:
    runCommandLocal name { nativeBuildInputs = [ zig_0_16 ]; } ''
      mkdir "$TMPDIR/source" "$TMPDIR/cache" "$out"
      touch "$TMPDIR/source/build.zig"
      package_hash="$(
        cd "$TMPDIR/source"
        zig fetch --global-cache-dir "$TMPDIR/cache" ${artifact}
      )"
      tar -xzf "$TMPDIR/cache/p/$package_hash.tar.gz" \
        --directory "$out" --strip-components=1
    '';

  fetchZig =
    {
      name,
      url,
      hash,
      unpack ? false,
    }:
    let
      artifact = if unpack then fetchzip { inherit url hash; } else fetchurl { inherit url hash; };
    in
    unpackZigArtifact name artifact;

  fetchGitZig =
    {
      name,
      url,
      rev,
      hash,
    }:
    fetchgit {
      inherit
        name
        url
        rev
        hash
        ;
      deepClone = false;
      fetchSubmodules = false;
    };

  packages = [
    {
      name = "aro-0.0.0-JSD1Qk8rOQDnuVcD4jAwMpHitA6pADRKzQ7M7hKRwxvD";
      path = fetchZig {
        name = "aro";
        url = "https://github.com/vancluever/arocc/archive/ecbc5c799574e0da2758a961b12efa586007f03c.tar.gz";
        hash = "sha256-rjNfhWjmA/1WR/xuHo4ls4fnDCbsI1VZSvb8SFRvwso=";
        unpack = true;
      };
    }
    {
      name = "N-V-__8AANT61wB--nJ95Gj_ctmzAtcjloZ__hRqNw5lC1Kr";
      path = fetchZig {
        name = "bindings";
        url = "https://deps.files.ghostty.org/DearBindings_v0.17_ImGui_v1.92.5-docking.tar.gz";
        hash = "sha256-i/7FAOAJJvZ5hT7iPWfMOS08MYFzPKRwRzhlHT9wuqM=";
      };
    }
    {
      name = "N-V-__8AABzkUgISeKGgXAzgtutgJsZc0-kkeqBBscJgMkvy";
      path = fetchZig {
        name = "glslang";
        url = "https://deps.files.ghostty.org/glslang-12201278a1a05c0ce0b6eb6026c65cd3e9247aa041b1c260324bf29cee559dd23ba1.tar.gz";
        hash = "sha256-FKLtu1Ccs+UamlPj9eQ12/WXFgS0uDPmPmB26MCpl7U=";
      };
    }
    {
      name = "N-V-__8AAGmZhABbsPJLfbqrh6JTHsXhY6qCaLAQyx25e0XE";
      path = fetchZig {
        name = "highway";
        url = "https://deps.files.ghostty.org/highway-66486a10623fa0d72fe91260f96c892e41aceb06.tar.gz";
        hash = "sha256-h9T4iT704I8iSXNgj/6/lCaKgTgLp5wS6IQZaMgKohI=";
      };
    }
    {
      name = "N-V-__8AAEbOfQBnvcFcCX2W5z7tDaN8vaNZGamEQtNOe0UI";
      path = fetchZig {
        name = "imgui";
        url = "https://deps.files.ghostty.org/N-V-__8AAEbOfQBnvcFcCX2W5z7tDaN8vaNZGamEQtNOe0UI.tar.gz";
        hash = "sha256-yBbCDox18+Fa6Gc1DnmSVQLRpqhZOLsac7iSfl8x+cs=";
      };
    }
    {
      name = "N-V-__8AAPpcBAD4_75xLBbLiYqdojOwQP74eoWmpL3jPrBl";
      path = fetchZig {
        name = "iterm2_themes";
        url = "https://deps.files.ghostty.org/ghostty-themes-release-20260810-152212-0173c3c.tgz";
        hash = "sha256-6ph4RxQg7lsS5/L/SACZyVTqUOVzob34P0PhBcm+Y/A=";
      };
    }
    {
      name = "N-V-__8AAIC5lwAVPJJzxnCAahSvZTIlG-HhtOvnM1uh-66x";
      path = fetchZig {
        name = "jetbrains_mono";
        url = "https://deps.files.ghostty.org/JetBrainsMono-2.304.tar.gz";
        hash = "sha256-xXppHouCrQmLWWPzlZAy5AOPORCHr3cViFulkEYQXMQ=";
      };
    }
    {
      name = "libxev-0.0.0-86vtcwIRFADbH4hk-EjROXxlrKIRPQdA41XiTSytYO-F";
      path = fetchZig {
        name = "libxev";
        url = "https://deps.files.ghostty.org/libxev-9ce8e8e6ff89e583258a7f8e7adeeeaeae8611bf.tar.gz";
        hash = "sha256-fOU1oxIxfoEgoLuWz7fVX6M+zmqpo7gqZObWiH/aDE0=";
        unpack = true;
      };
    }
    {
      name = "N-V-__8AAMVLTABmYkLqhZPLXnMl-KyN38R8UVYqGrxqO26s";
      path = fetchZig {
        name = "nerd_fonts_symbols_only";
        url = "https://deps.files.ghostty.org/NerdFontsSymbolsOnly-3.4.0.tar.gz";
        hash = "sha256-EWTRuVbUveJI17LwmYxDzJT1ICQxoVZKeTiVsec7DQQ=";
      };
    }
    {
      name = "N-V-__8AADYiAAB_80AWnH1AxXC0tql9thT-R-DYO1gBqTLc";
      path = fetchZig {
        name = "pixels";
        url = "https://deps.files.ghostty.org/pixels-12207ff340169c7d40c570b4b6a97db614fe47e0d83b5801a932dcd44917424c8806.tar.gz";
        hash = "sha256-Veg7FtCRCCUCvxSb9FfzH0IJLFmCZQ4/+657SIcb8Ro=";
      };
    }
    {
      name = "N-V-__8AANb6pwD7O1WG6L5nvD_rNMvnSc9Cpg1ijSlTYywv";
      path = fetchZig {
        name = "spirv_cross";
        url = "https://deps.files.ghostty.org/spirv_cross-1220fb3b5586e8be67bc3feb34cbe749cf42a60d628d2953632c2f8141302748c8da.tar.gz";
        hash = "sha256-tStvz8Ref6abHwahNiwVVHNETizAmZVVaxVsU7pmV+M=";
      };
    }
    {
      name = "translate_c-0.0.0-Q_BUWmU6BwB_9JKG2l2W7i_mhmYWeRseTGBEHi_YlV5f";
      path = fetchZig {
        name = "translate_c";
        url = "https://deps.files.ghostty.org/translate_c-80f8b6e4f45a303268717d8e5f4f91d7837138bb.tar.gz";
        hash = "sha256-fB7OsZ2PIijMzVMYg8SzDBtTKX7IZHbEvPuBTdyGtWk=";
        unpack = true;
      };
    }
    {
      name = "uucode-0.2.0-ZZjBPlK5VADj7fdoq7G8LIHzD5o6FSkcBXXrRWr4jnrA";
      path = fetchZig {
        name = "uucode";
        url = "https://deps.files.ghostty.org/uucode-2826a37a4562284fdacd8fa029d49509cc9bffcd.tar.gz";
        hash = "sha256-R5RXW5tWIaDq5JOF2+oWd5YOYOyns6WH7f687WE+b20=";
        unpack = true;
      };
    }
    {
      name = "vaxis-0.6.0-BWNV_MjFCQCs9UDHiRkrgw_ayeiPkzOe4xVbaAqXkUWW";
      path = fetchGitZig {
        name = "vaxis";
        url = "https://github.com/rockorager/libvaxis.git";
        rev = "c1e1f23be38951c425cdf31af455ba23ef178940";
        hash = "sha256-bIXu8lGwGo42QbItC0jOi/eN7u+f4snknBexw7dc0DI=";
      };
    }
    {
      name = "vaxis-0.6.0-BWNV_CrbCQCscGpzsAlR402rYQ_tV3aAl081c2iRRkka";
      path = fetchZig {
        name = "vaxis";
        url = "https://deps.files.ghostty.org/vaxis-1dbbe575dff4586fe51e3217aa5c3fecdcbb6089.tar.gz";
        hash = "sha256-z3J3w+oYapfAZZR+MvWXwg+th1hePDA1TptnKFO4r+M=";
        unpack = true;
      };
    }
    {
      name = "z2d-0.12.1-j5P_Hsw8EQAKyZTQICCQnAH2xYkLDW8k9uefbsYdfPZ-";
      path = fetchZig {
        name = "z2d";
        url = "https://deps.files.ghostty.org/z2d-7dbae85c81784dba9988320bf9543ed9a81350c8.tar.gz";
        hash = "sha256-Fjr1ORn0ozxU7QY09o2ZOZQHIJsXfVw0UCdZxTKmZJ0=";
        unpack = true;
      };
    }
    {
      name = "zf-0.11.0-OIRy8X-RAAAwaRXHMYpj2uvBnuGTZWEE_3V7acqHQNtW";
      path = fetchZig {
        name = "zf";
        url = "https://deps.files.ghostty.org/zf-c35c421f84895193246db06c40683c1a30e616ef.tar.gz";
        hash = "sha256-LHurWwqK8jhP8AZd/CXrMJNeVsKftRCTN31/EgEgKaA=";
        unpack = true;
      };
    }
    {
      name = "zigimg-0.1.0-8_eo2oyaFwBZwJpmqPkCfVXWBrHcqbYwmrp1I6bTD3lI";
      path = fetchGitZig {
        name = "zigimg";
        url = "https://github.com/zigimg/zigimg";
        rev = "d695acd97c02e57bb151e8f659d1280f5cd6ca70";
        hash = "sha256-0IYATQldT6eJxRR2T/2CsIYZuzomqjvmdVyjmsjguyE=";
      };
    }
  ];
in
runCommandLocal "pi-gpui-ghostty-zig-deps" { } ''
  mkdir -p "$out"
  ${lib.concatMapStringsSep "\n" (package: ''
    cp -rL ${package.path} "$out/${package.name}"
  '') packages}
''
