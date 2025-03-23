# mpv-cycle-through-subset

This is a short Lua script for [mpv](https://github.com/mpv-player/mpv)
that allows cycling through a **subset** of the
video, audio and subtitle tracks
based on a predefined list of accepted **languages**,
optionally skipping the "no video/audio/subtitles" state. 

### Usage

- Save `cycle-through-subset.lua` in
    `~/.config/.mpv/scripts/` (Linux and macOS)
    or `%AppData%\mpv\scripts\` (Windows).
- Edit your
    [mpv `input.conf`](https://mpv.io/manual/master/#input-conf)
    file to include
    the shortcuts for
    `script-binding cycle_lang_{video,audio,sub,sub2}_{up,down}`.
Example:
    ```
    _     script-binding cycle_lang_video_up
    SHARP script-binding cycle_lang_audio_up
    j     script-binding cycle_lang_sub_up
    J     script-binding cycle_lang_sub_down
    Alt+j script-binding cycle_lang_sub2_up
    Alt+J script-binding cycle_lang_sub2_down
    ```
- Add new lines to your
    [mpv `config` file](https://mpv.io/manual/stable/#configuration-files)
    defining the `cyclethroughsubset-{video,audio,sub}-langs` options. Each of them is a list of language codes separated by `+`.
    Languages can be specified by their two-letter ISO-639-1 codes or their three-letter ISO-639-2 codes
    ([reference table](https://www.loc.gov/standards/iso639-2/php/code_list.php)), separated by plus signs. For example, to accept English and French, write `en+fr` or `eng+fra`.

    Also, the "no video/audio/subtitles" state is included by default when cycling through the tracks. To skip this state,
    set the value of the
    `cyclethroughsubset-allow-no-{video,audio,sub,sub2}`
    options to `no`.

    Follow this example:
    ```ini
    # subtitles in English and Portuguese:
    script-opts-append=cyclethroughsubset-sub-langs=en+pt

    # audio in Indonesian, Arabic and Italian:
    script-opts-append=cyclethroughsubset-audio-langs=id+ar+it

    # skip "no video", "no audio" and "no subtitles"
    # but allow "no secondary subtitles":
    script-opts-append=cyclethroughsubset-allow-no-video=no
    script-opts-append=cyclethroughsubset-allow-no-audio=no
    script-opts-append=cyclethroughsubset-allow-no-sub=no
    script-opts-append=cyclethroughsubset-allow-no-sub2=yes
    ```

Please note:
- tracks without a language label will always be accepted;
- secondary subtitles use the same language list as primary subtitles, defined by the `cyclethroughsubset-sub-langs` option; 
- if no languages are specified for a track type,
    all tracks of that type will be included;
- this script does not change the behaviour of the OSD bar.
