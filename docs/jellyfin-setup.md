# Jellyfin Media Library Setup Guide

## Quick Setup Reference

Access Jellyfin at: `https://media.starcommand.live`

### Media Library Paths

These directories are pre-created on `/mnt/storage` (22TB merged NTFS storage):

| Library Type | Path | Description |
|-------------|------|-------------|
| Movies | `/mnt/storage/media/movies` | Movie files |
| TV Shows | `/mnt/storage/media/tv` | TV series |
| Music | `/mnt/storage/media/music` | Music library |
| Audiobooks | `/mnt/storage/media/audiobooks` | Audiobook collection |

### One-Time Configuration Steps

1. **Access Jellyfin**
   - Go to `https://media.starcommand.live`
   - Login with LDAP credentials via Authelia SSO

2. **Add Media Libraries** (Dashboard → Libraries → Add Library)

   **Movies:**
   - Content type: Movies
   - Folders: `/mnt/storage/media/movies`
   - Metadata: Enable TMDB, OMDB as needed
   - Save

   **TV Shows:**
   - Content type: Shows
   - Folders: `/mnt/storage/media/tv`
   - Metadata: Enable TheTVDB, TMDB as needed
   - Save

   **Music:**
   - Content type: Music
   - Folders: `/mnt/storage/media/music`
   - Metadata: Enable MusicBrainz as needed
   - Save

   **Audiobooks:**
   - Content type: Books (or Music if you prefer)
   - Folders: `/mnt/storage/media/audiobooks`
   - Save

   **YouTube Downloads (Optional):**
   - Content type: Movies or Music Videos (depending on content)
   - Folders: `/mnt/storage/youtube`
   - Note: Pinchflat downloads go here by default
   - Save

3. **Initial Scan**
   - Jellyfin will scan the directories and fetch metadata
   - This may take a while depending on library size

## Integration with Other Services

### Radarr (Movies)
- Configure Radarr to download to: `/mnt/storage/media/movies`
- Jellyfin will auto-detect new movies on library scan

### Sonarr (TV Shows)
- Configure Sonarr to download to: `/mnt/storage/media/tv`
- Jellyfin will auto-detect new episodes on library scan

### Lidarr (Music)
- Configure Lidarr to download to: `/mnt/storage/media/music`
- Jellyfin will auto-detect new music on library scan

### Pinchflat (YouTube Downloads)
- Default download location: `/mnt/storage/youtube`
- **Option 1**: Add `/mnt/storage/youtube` as a separate Jellyfin library
- **Option 2**: Configure Pinchflat sources to download to specific Jellyfin folders:
  - Music videos → `/mnt/storage/media/music`
  - Documentaries → `/mnt/storage/media/movies`
  - Podcast episodes → `/mnt/storage/media/tv`
- Configure per-source output paths at: `https://youtube.starcommand.live`

## Persistence

All Jellyfin configuration (including library setup) is stored in `/var/lib/jellyfin` which is:
- On fast NVMe btrfs
- Part of the impermanence persistence layer
- Backed up regularly

**You only need to configure libraries once!** They will persist across:
- System reboots
- NixOS rebuilds
- Service restarts

## Notes

- Library scanning is automatic but can be triggered manually
- Metadata fetching requires internet access
- LDAP authentication is pre-configured via selfhostblocks
- SSO integration is pre-configured via Authelia
