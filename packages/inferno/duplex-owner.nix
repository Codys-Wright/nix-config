{
  lib,
  stdenv,
  alsa-lib,
  pkg-config,
  writeText,
}:

stdenv.mkDerivation {
  pname = "inferno-duplex-owner";
  version = "0.1.0";

  src = writeText "main.c" ''
    #include <alsa/asoundlib.h>
    #include <signal.h>
    #include <stdint.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <string.h>
    #include <unistd.h>

    static volatile sig_atomic_t keep_running = 1;

    static void handle_signal(int sig) {
      (void)sig;
      keep_running = 0;
    }

    static int setup_pcm(snd_pcm_t **handle, const char *device, snd_pcm_stream_t stream,
                         unsigned int rate, unsigned int channels, snd_pcm_uframes_t period_size,
                         snd_pcm_uframes_t buffer_size) {
      int err;
      if ((err = snd_pcm_open(handle, device, stream, 0)) < 0) {
        fprintf(stderr, "snd_pcm_open(%s,%s) failed: %s\n", device,
                stream == SND_PCM_STREAM_CAPTURE ? "capture" : "playback", snd_strerror(err));
        return err;
      }

      snd_pcm_hw_params_t *hw = NULL;
      snd_pcm_sw_params_t *sw = NULL;
      snd_pcm_hw_params_alloca(&hw);
      snd_pcm_sw_params_alloca(&sw);

      if ((err = snd_pcm_hw_params_any(*handle, hw)) < 0) goto fail;
      if ((err = snd_pcm_hw_params_set_access(*handle, hw, SND_PCM_ACCESS_RW_INTERLEAVED)) < 0) goto fail;
      if ((err = snd_pcm_hw_params_set_format(*handle, hw, SND_PCM_FORMAT_S32_LE)) < 0) goto fail;
      if ((err = snd_pcm_hw_params_set_channels(*handle, hw, channels)) < 0) goto fail;
      if ((err = snd_pcm_hw_params_set_rate(*handle, hw, rate, 0)) < 0) goto fail;
      if ((err = snd_pcm_hw_params_set_period_size_near(*handle, hw, &period_size, 0)) < 0) goto fail;
      if ((err = snd_pcm_hw_params_set_buffer_size_near(*handle, hw, &buffer_size)) < 0) goto fail;
      if ((err = snd_pcm_hw_params(*handle, hw)) < 0) goto fail;

      if ((err = snd_pcm_sw_params_current(*handle, sw)) < 0) goto fail;
      if ((err = snd_pcm_sw_params(*handle, sw)) < 0) goto fail;

      return 0;

    fail:
      fprintf(stderr, "PCM setup failed (%s): %s\n",
              stream == SND_PCM_STREAM_CAPTURE ? "capture" : "playback", snd_strerror(err));
      snd_pcm_close(*handle);
      *handle = NULL;
      return err;
    }

    int main(int argc, char **argv) {
      const char *device = argc > 1 ? argv[1] : "THEBATTLESHIP";
      unsigned int channels = argc > 2 ? (unsigned int)atoi(argv[2]) : 128;
      unsigned int rate = argc > 3 ? (unsigned int)atoi(argv[3]) : 48000;
      snd_pcm_uframes_t period_size = 4096;
      snd_pcm_uframes_t buffer_size = 16384;
      int err;

      signal(SIGINT, handle_signal);
      signal(SIGTERM, handle_signal);

      snd_pcm_t *capture = NULL;
      snd_pcm_t *playback = NULL;

      if ((err = setup_pcm(&capture, device, SND_PCM_STREAM_CAPTURE, rate, channels, period_size, buffer_size)) < 0) {
        return 1;
      }
      if ((err = setup_pcm(&playback, device, SND_PCM_STREAM_PLAYBACK, rate, channels, period_size, buffer_size)) < 0) {
        snd_pcm_close(capture);
        return 1;
      }

      size_t frame_bytes = channels * sizeof(int32_t);
      int32_t *capture_buf = calloc(period_size, frame_bytes);
      int32_t *playback_buf = calloc(period_size, frame_bytes);
      if (!capture_buf || !playback_buf) {
        fprintf(stderr, "allocation failed\n");
        snd_pcm_close(capture);
        snd_pcm_close(playback);
        free(capture_buf);
        free(playback_buf);
        return 1;
      }
      memset(playback_buf, 0, period_size * frame_bytes);

      if ((err = snd_pcm_prepare(capture)) < 0) {
        fprintf(stderr, "snd_pcm_prepare(capture) failed: %s\n", snd_strerror(err));
        return 1;
      }
      if ((err = snd_pcm_prepare(playback)) < 0) {
        fprintf(stderr, "snd_pcm_prepare(playback) failed: %s\n", snd_strerror(err));
        return 1;
      }

      fprintf(stderr, "duplex owner running on %s with %u channels @ %u Hz\n", device, channels, rate);

      while (keep_running) {
        snd_pcm_sframes_t r = snd_pcm_readi(capture, capture_buf, period_size);
        if (r < 0) {
          err = snd_pcm_recover(capture, (int)r, 1);
          if (err < 0) {
            fprintf(stderr, "capture failed unrecoverably: %s\n", snd_strerror(err));
            break;
          }
          continue;
        }

        snd_pcm_sframes_t written_total = 0;
        while (written_total < r) {
          snd_pcm_sframes_t w = snd_pcm_writei(playback, playback_buf + written_total * channels, r - written_total);
          if (w < 0) {
            err = snd_pcm_recover(playback, (int)w, 1);
            if (err < 0) {
              fprintf(stderr, "playback failed unrecoverably: %s\n", snd_strerror(err));
              keep_running = 0;
              break;
            }
            continue;
          }
          written_total += w;
        }
      }

      snd_pcm_drop(capture);
      snd_pcm_drop(playback);
      snd_pcm_close(capture);
      snd_pcm_close(playback);
      free(capture_buf);
      free(playback_buf);
      fprintf(stderr, "duplex owner exiting\n");
      return 0;
    }
  '';

  dontUnpack = true;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ alsa-lib ];

  buildPhase = ''
    cp "$src" main.c
    gcc -O2 -Wall main.c $(pkg-config --cflags --libs alsa) -o inferno-duplex-owner
  '';

  installPhase = ''
    install -Dm755 inferno-duplex-owner $out/bin/inferno-duplex-owner
  '';

  meta = with lib; {
    description = "Single-process persistent Inferno owner that keeps a 128-channel Dante device open";
    platforms = platforms.linux;
    mainProgram = "inferno-duplex-owner";
    license = licenses.mit;
  };
}
