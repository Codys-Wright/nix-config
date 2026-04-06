{ fleet, ... }:
{
  fleet.coding._.tools._.reverse-engineering = {
    description = "Reverse engineering and binary analysis tools";
    nixos =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          (ghidra.withExtensions (exts: [
            exts.kaiju # CERT Pharos binary analysis framework
            exts.ret-sync # Sync between debugger and Ghidra
            exts.findcrypt # Locate cryptographic constants
          ])) # SRE suite — decompiler, disassembler, debugger
          imhex # Hex editor with pattern language and data analysis
          radare2 # CLI reverse engineering framework
          binwalk # Firmware analysis and extraction
          hexyl # Terminal hex viewer
          gef # GDB enhanced features for exploit dev
          pwntools # CTF and exploit development toolkit
          capstone # Disassembly framework (library + cstool CLI)
        ];
      };
  };
}
