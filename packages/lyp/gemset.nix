{
  diff-lcs = {
    groups = ["default" "spec"];
    platforms = [];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "1vf9civd41bnqi6brr5d9jifdw73j9khc6fkhfl1f8r9cpkdvlx1";
      type = "gem";
    };
    version = "1.2.5";
  };
  directory_watcher = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fwc2shba7vks262ind74y3g76qp7znjq5q8b2dvza0yidgywhcq";
      type = "gem";
    };
    version = "1.5.1";
  };
  httpclient = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "4b645958e494b2f86c2f8a2f304c959baa273a310e77a2931ddb986d83e498c8";
      type = "gem";
    };
    version = "2.9.0";
  };
  lyp = {
    dependencies = ["directory_watcher" "httpclient" "ruby-progressbar" "rugged" "thor"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "0cflfmzs4xk0ar39xy6gyd9kd2ahx68672chxv1fiksvmp1imjrs";
      type = "gem";
    };
    version = "1.3.11";
  };
  rspec = {
    dependencies = ["rspec-core" "rspec-expectations" "rspec-mocks"];
    groups = ["spec"];
    platforms = [];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "0lkz01j4yxcwb3g5w6r1l9khnyw3sxib4rrh4npd2pxh390fcc4f";
      type = "gem";
    };
    version = "3.2.0";
  };
  rspec-core = {
    dependencies = ["rspec-support"];
    groups = ["default" "spec"];
    platforms = [];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "0k2471iw30gc2cvv67damrx666pmsvx8l0ahk3hm20dhfnmcmpvv";
      type = "gem";
    };
    version = "3.2.3";
  };
  rspec-expectations = {
    dependencies = ["diff-lcs" "rspec-support"];
    groups = ["default" "spec"];
    platforms = [];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "01kmchabgpdcaqdsqg8r0g5gy385xhp1k1jsds3w264ypin17n14";
      type = "gem";
    };
    version = "3.2.1";
  };
  rspec-mocks = {
    dependencies = ["diff-lcs" "rspec-support"];
    groups = ["default" "spec"];
    platforms = [];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "09yig1lwgxl8fsns71z3xhv7wkg7zvagydh37pvaqpw92dz55jv2";
      type = "gem";
    };
    version = "3.2.1";
  };
  rspec-support = {
    groups = ["default" "spec"];
    platforms = [];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "194zry5195ls2hni7r9824vqb5d3qfg4jb15fgj8glfy0rvw3zxl";
      type = "gem";
    };
    version = "3.2.2";
  };
  ruby-progressbar = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "0hynaavnqzld17qdx9r7hfw00y16ybldwq730zrqfszjwgi59ivi";
      type = "gem";
    };
    version = "1.7.5";
  };
  rugged = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "7faaa912c5888d6e348d20fa31209b6409f1574346b1b80e309dbc7e8d63efac";
      type = "gem";
    };
    version = "1.9.0";
  };
  thor = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["http://rubygems.org"];
      sha256 = "0nmqpyj642sk4g16nkbq6pj856adpv91lp4krwhqkh2iw63aszdl";
      type = "gem";
    };
    version = "0.20.0";
  };
}
