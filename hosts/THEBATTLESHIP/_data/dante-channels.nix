# THEBATTLESHIP's Dante channel labels (Inferno rx/tx), consumed by the
# inferno call in THEBATTLESHIP.nix. Plain data — `_data/` is invisible to
# import-tree.
{
  # RX channel names ≡ THEBATTLESHIP's "inputs" — these are
  # what Reaper records from. Sourced from the Reaper chanmap
  # at ~/.fasttrackstudio/Reaper/ChanMaps/THEBATTLESHIP.ReaperChanMap;
  # regenerate with `~/.flake/scripts/set_dante_channel_names.py`
  # if/when the chanmap changes.
  rx = {
    "1" = "1 - Kick In";
    "2" = "2 - Kick Out";
    "3" = "3 - Snare Top";
    "4" = "4 - Snare Bottom";
    "5" = "5 - Tom 1";
    "6" = "6 - Tom 2";
    "7" = "7 - Tom 3";
    "8" = "8 - Tom 4";
    "9" = "9 - Hi-Hat";
    "10" = "10 - Ride";
    "11" = "11 - OH L";
    "12" = "12 - OH R";
    "13" = "13 - Room L";
    "14" = "14 - Room R";
    "15" = "15 - E-Kit L";
    "16" = "16 - E-Kit R";
    "17" = "17 - Drum Pad L";
    "18" = "18 - Drum Pad R";
    "19" = "19 - Bass DI";
    "20" = "20 - Bass Amp";
    "21" = "21 - Guitar 1 L";
    "22" = "22 - Guitar 1 R";
    "23" = "23 - Guitar 2 L";
    "24" = "24 - Guitar 2 R";
    "25" = "25 - Guitar 1 DI";
    "26" = "26 - Guitar 2 DI";
    "27" = "27 - Acoustic 1";
    "28" = "28 - Acoustic 2";
    "29" = "29 - Keys 1 L";
    "30" = "30 - Keys 1 R";
    "31" = "31 - Keys 2 L";
    "32" = "32 - Keys 2 R";
    "33" = "33 - Vox 1 L";
    "34" = "34 - Vox 1 R";
    "35" = "35 - Vox 2";
    "36" = "36 - Vox 3";
    "37" = "37 - Vox 4";
    "38" = "38 - Vox 5 [Drums]";
    "39" = "39 - Vox 6 [Bass]";
    "40" = "40 - Vox 7 [Guitar]";
    "41" = "41 - Vox 8 [Keys]";
    "42" = "42 - Vox 9 [Engineer]";
    "43" = "43 - Vox 10 [Producer]";
    "44" = "44 - Kick [DSP]";
    "45" = "45 - Snare [DSP]";
    "46" = "46 - Vox 1 L [DSP]";
    "47" = "47 - Vox 1 R [DSP]";
    "48" = "48 - Vox 2 [DSP]";
    "49" = "49 - Vox 3 [DSP]";
    "50" = "50 - Vox 4 [DSP]";
    "51" = "51 - Vox 9 [Engineer] [DSP]";
    "52" = "52 - Click";
    "53" = "53 - Headphone Mix L";
    "54" = "54 - Headphone Mix R";
    "55" = "55 - Processed HP Mix L";
    "56" = "56 - Processed HP Mix R";
    "57" = "57 - System L";
    "58" = "58 - System R";
    "59" = "59 - Voice Chat L";
    "60" = "60 - Voice Chat R";
    "61" = "61 - DAW L";
    "62" = "62 - DAW R";
    "63" = "63 - Broadcast L";
    "64" = "64 - Broadcast R";
  };
  # TX channel names — placeholder labels until we lock in the
  # broadcast/output layout. `N - OUTN` makes every slot unique
  # so Dante Controller and other receivers can target a specific
  # channel without ambiguity, and identifies the slot number
  # inline. Replace with meaningful labels alongside the
  # rxChannelNames map when the routing is finalised.
  tx = {
    "1" = "1 - OUT1";
    "2" = "2 - OUT2";
    "3" = "3 - OUT3";
    "4" = "4 - OUT4";
    "5" = "5 - OUT5";
    "6" = "6 - OUT6";
    "7" = "7 - OUT7";
    "8" = "8 - OUT8";
    "9" = "9 - OUT9";
    "10" = "10 - OUT10";
    "11" = "11 - OUT11";
    "12" = "12 - OUT12";
    "13" = "13 - OUT13";
    "14" = "14 - OUT14";
    "15" = "15 - OUT15";
    "16" = "16 - OUT16";
    "17" = "17 - OUT17";
    "18" = "18 - OUT18";
    "19" = "19 - OUT19";
    "20" = "20 - OUT20";
    "21" = "21 - OUT21";
    "22" = "22 - OUT22";
    "23" = "23 - OUT23";
    "24" = "24 - OUT24";
    "25" = "25 - OUT25";
    "26" = "26 - OUT26";
    "27" = "27 - OUT27";
    "28" = "28 - OUT28";
    "29" = "29 - OUT29";
    "30" = "30 - OUT30";
    "31" = "31 - OUT31";
    "32" = "32 - OUT32";
    "33" = "33 - OUT33";
    "34" = "34 - OUT34";
    "35" = "35 - OUT35";
    "36" = "36 - OUT36";
    "37" = "37 - OUT37";
    "38" = "38 - OUT38";
    "39" = "39 - OUT39";
    "40" = "40 - OUT40";
    "41" = "41 - OUT41";
    "42" = "42 - OUT42";
    "43" = "43 - OUT43";
    "44" = "44 - OUT44";
    "45" = "45 - OUT45";
    "46" = "46 - OUT46";
    "47" = "47 - OUT47";
    "48" = "48 - OUT48";
    "49" = "49 - OUT49";
    "50" = "50 - OUT50";
    "51" = "51 - OUT51";
    "52" = "52 - OUT52";
    "53" = "53 - Headphone Mix L";
    "54" = "54 - Headphone Mix R";
    "55" = "55 - Processed HP Mix L";
    "56" = "56 - Processed HP Mix R";
    "57" = "57 - System L";
    "58" = "58 - System R";
    "59" = "59 - Voice Chat L";
    "60" = "60 - Voice Chat R";
    "61" = "61 - DAW L";
    "62" = "62 - DAW R";
    "63" = "63 - Broadcast L";
    "64" = "64 - Broadcast R";
  };
}
