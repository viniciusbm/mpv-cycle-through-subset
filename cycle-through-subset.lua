--[[
Copyright 2025 Vinícius B. Matos

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
--]]

-- Language code map (ISO 639-2 to ISO 639-1, when available):
---@format disable-next
local lang_map = {aar='aa', abk='ab', afr='af', aka='ak', alb='sq', amh='am', ara='ar', arg='an', arm='hy', asm='as', ava='av', ave='ae', aym='ay', aze='az', bak='ba', bam='bm', baq='eu', bel='be', ben='bn', bis='bi', bod='bo', bos='bs', bre='br', bul='bg', bur='my', cat='ca', ces='cs', cha='ch', che='ce', chi='zh', chu='cu', chv='cv', cor='kw', cos='co', cre='cr', cym='cy', cze='cs', dan='da', deu='de', div='dv', dut='nl', dzo='dz', ell='el', eng='en', epo='eo', est='et', eus='eu', ewe='ee', fao='fo', fas='fa', fij='fj', fin='fi', fra='fr', fre='fr', fry='fy', ful='ff', geo='ka', ger='de', gla='gd', gle='ga', glg='gl', glv='gv', gre='el', grn='gn', guj='gu', hat='ht', hau='ha', heb='he', her='hz', hin='hi', hmo='ho', hrv='hr', hun='hu', hye='hy', ibo='ig', ice='is', ido='io', iii='ii', iku='iu', ile='ie', ina='ia', ind='id', ipk='ik', isl='is', ita='it', jav='jv', jpn='ja', kal='kl', kan='kn', kas='ks', kat='ka', kau='kr', kaz='kk', khm='km', kik='ki', kin='rw', kir='ky', kom='kv', kon='kg', kor='ko', kua='kj', kur='ku', lao='lo', lat='la', lav='lv', lim='li', lin='ln', lit='lt', ltz='lb', lub='lu', lug='lg', mac='mk', mah='mh', mal='ml', mao='mi', mar='mr', may='ms', mkd='mk', mlg='mg', mlt='mt', mon='mn', mri='mi', msa='ms', mya='my', nau='na', nav='nv', nbl='nr', nde='nd', ndo='ng', nep='ne', nld='nl', nno='nn', nob='nb', nor='no', nya='ny', oci='oc', oji='oj', ori='or', orm='om', oss='os', pan='pa', per='fa', pli='pi', pol='pl', por='pt', pus='ps', que='qu', roh='rm', ron='ro', rum='ro', run='rn', rus='ru', sag='sg', san='sa', sin='si', slk='sk', slo='sk', slv='sl', sme='se', smo='sm', sna='sn', snd='sd', som='so', sot='st', spa='es', sqi='sq', srd='sc', srp='sr', ssw='ss', sun='su', swa='sw', swe='sv', tah='ty', tam='ta', tat='tt', tel='te', tgk='tg', tgl='tl', tha='th', tib='bo', tir='ti', ton='to', tsn='tn', tso='ts', tuk='tk', tur='tr', twi='tw', uig='ug', ukr='uk', urd='ur', uzb='uz', ven='ve', vie='vi', vol='vo', wel='cy', wln='wa', wol='wo', xho='xh', yid='yi', yor='yo', zha='za', zho='zh', zul='zu'}

-- Read configuration
local options = {
    ['sub-langs'] = '',
    ['audio-langs'] = '',
    ['video-langs'] = '',
    ['allow-no-sub'] = true,
    ['allow-no-sub2'] = true,
    ['allow-no-audio'] = true,
    ['allow-no-video'] = true
}
require "mp.options".read_options(options, 'cyclethroughsubset')


---Obtain the chosen set of languages given a string
---@param str string the string representation of a list of language codes, separated by a plus sign
---@return table<string, boolean> : a table mapping the chosen language codes to true
local function get_lang_table(str)
    if #str == 0 then
        return {}
    end
    local langs = {}
    for code in string.gmatch(str .. '+', '(%a+)%+') do
        if string.len(code) >= 2 then
            langs[code] = true
        end
        code = lang_map[code]
        if code ~= nil then
            langs[code] = true
        end
    end
    return langs
end

---Table of the chosen languages for audio, video and subtitles
local langs = {
    audio = get_lang_table(options['audio-langs']),
    video = get_lang_table(options['video-langs']),
    sub = get_lang_table(options['sub-langs']),
}

local valid_track_types = { video = true, audio = true, sub = true, sub2 = true }
---@alias track_type "video" | "audio" | "sub" | "sub2"

local valid_dirs = { up = true, down = true }
---@alias direction  "up" | "down"


---Move to the next track.
---@param kind track_type the type of the track to be changed
---@param dir  direction  up or down
local function cycle_lang(kind, dir)
    if not valid_track_types[kind] then
        error('Invalid argument for kind')
    end
    if not valid_dirs[dir] then
        error('Invalid argument for dir')
    end

    local track_type = kind:gsub('2', '')
    local property_name = kind
    if kind == 'sub2' then
        property_name = 'secondary-sid'
    end

    ---Accepted languages
    local accepted_langs = langs[track_type]

    ---Position of the currently selected track
    local cur_idx = mp.get_property_native('current-tracks/' .. kind .. '/src-id', 0)

    ---List of all tracks, indexed starting from 1
    ---(We cannot cache this because the user may add subtitle tracks at runtime)
    local all_tracks = mp.get_property_native('track-list', {})

    -- +1 to go up, -1 to go down
    local step = 1
    if dir == 'down' then
        step = -1
    end
    local first = cur_idx + step
    local last = cur_idx + step * #all_tracks

    for i = first, last, step do
        local idx = i % (#all_tracks + 1)
        if idx == 0 then
            if options['allow-no-' .. kind] then
                mp.command('set ' .. property_name .. ' 0')
                return
            end
        else
            local t = all_tracks[idx]
            if t.type == track_type
                and not t.selected                      -- skip tracks that are already selected
                and (
                    t.lang == nil                       -- accept tracks without a language label
                    or accepted_langs[t.lang]           -- accept tracks with a selected language
                    or accepted_langs[lang_map[t.lang]] -- accept tracks with a selected language
                    or next(accepted_langs) == nil      -- accept all tracks if no languages are selected
                ) then
                mp.command('set ' .. property_name .. ' ' .. t.id)
                return
            end
        end
    end
end


mp.add_key_binding(nil, 'cycle_lang_video_up', function() cycle_lang('video', 'up') end)
mp.add_key_binding(nil, 'cycle_lang_audio_up', function() cycle_lang('audio', 'up') end)
mp.add_key_binding(nil, 'cycle_lang_sub_up', function() cycle_lang('sub', 'up') end)
mp.add_key_binding(nil, 'cycle_lang_sub2_up', function() cycle_lang('sub2', 'up') end)

mp.add_key_binding(nil, 'cycle_lang_video_down', function() cycle_lang('video', 'down') end)
mp.add_key_binding(nil, 'cycle_lang_audio_down', function() cycle_lang('audio', 'down') end)
mp.add_key_binding(nil, 'cycle_lang_sub_down', function() cycle_lang('sub', 'down') end)
mp.add_key_binding(nil, 'cycle_lang_sub2_down', function() cycle_lang('sub2', 'down') end)
