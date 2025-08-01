{
  channels,
  namespace,
  inputs,
  ...
}:

final: prev: {
  # Make the whitesur-wallpapers package available
  whitesur-wallpapers = inputs.self.packages.${prev.system}.whitesur-wallpapers;
} 