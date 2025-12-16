{
  y = "EDITOR=d yazi";
  l = "exa -l";
  ll = "exa -l -@ --git";
  tree = "exa -T";
  "." = "eval (history | head -1 | string replace -r '^\\s*\\d+\\s+' '')";
  ".." = "cd ..";
  vs = ''vim -c "lua Snacks.picker.smart()"'';
  vf = ''vim -c "lua Snacks.picker.files()"'';
  vg = ''vim -c "lua Snacks.picker.grep()"'';
  vr = ''vim -c "lua Snacks.picker.recent()"'';
  vd = ''vim -c "DiffEditor $left $right $output"'';
  av = ''astrovim'';
  lv = ''lazyvim'';
  vp = ''nix run /home/cody/.flake#nvf'';
}
