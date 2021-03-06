require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/deep_merge"
require "active_support/test_case"
require "base64"
require "fileutils"
require "image_optim"
require "json"
require "nokogiri"
require "open-uri"
require "pathname"

$debugging_output = []

EMOJI_GROUPS_PATH ||= "app/assets/javascripts/discourse/lib/emoji/groups.js.es6"

EMOJI_DB_PATH ||= "lib/emoji/db.json"

EMOJI_IMAGES_PATH ||= "public/images/emoji"

EMOJI_LIST_URL ||= "http://unicode.org/emoji/charts/full-emoji-list.html"

EMOJI_ORDERING_URL ||= "http://www.unicode.org/emoji/charts/emoji-ordering.html"

EMOJI_KEYWORDS_URL ||= "https://raw.githubusercontent.com/muan/emojilib/master/emojis.json"

EMOJI_ALIASES ||= {
  "right_anger_bubble" => [ "anger_right" ],
  "ballot_box" => [ "ballot_box_with_ballot" ],
  "basketball_man" => [ "basketball_player", "person_with_ball" ],
  "beach_umbrella" => [ "umbrella_on_ground", "beach", "beach_with_umbrella" ],
  "parasol_on_ground" => [ "umbrella_on_ground" ],
  "bellhop_bell" => [ "bellhop" ],
  "biohazard" => [ "biohazard_sign" ],
  "bow_and_arrow" => [ "archery" ],
  "spiral_calendar" => [ "calendar_spiral", "spiral_calendar_pad" ],
  "card_file_box" => [ "card_box" ],
  "champagne" => [ "bottle_with_popping_cork" ],
  "cheese" => [ "cheese_wedge" ],
  "city_sunset" => [ "city_dusk" ],
  "clock" => [ "mantlepiece_clock" ],
  "couch_and_lamp" => [ "couch" ],
  "crayon" => [ "lower_left_crayon" ],
  "cricket" => [ "cricket_bat_ball" ],
  "latin_cross" => [ "cross" ],
  "dagger" => [ "dagger_knife" ],
  "desktop_computer" => [ "desktop" ],
  "card_index_dividers" => [ "dividers" ],
  "dove" => [ "dove_of_peace" ],
  "footprints" => [ "feet" ],
  "fire" => [ "flame" ],
  "black_flag" => [ "flag_black", "waving_black_flag" ],
  "cn" => [ "flag_cn" ],
  "de" => [ "flag_de" ],
  "es" => [ "flag_es" ],
  "fr" => [ "flag_fr" ],
  "uk" => [ "gb", "flag_gb" ],
  "it" => [ "flag_it" ],
  "jp" => [ "flag_jp" ],
  "kr" => [ "flag_kr" ],
  "ru" => [ "flag_ru" ],
  "us" => [ "flag_us" ],
  "white_flag" => [ "flag_white", "waving_white_flag" ],
  "plate_with_cutlery" => [ "fork_knife_plate", "fork_and_knife_with_plate" ],
  "framed_picture" => [ "frame_photo", "frame_with_picture" ],
  "hammer_and_pick" => [ "hammer_pick" ],
  "heavy_heart_exclamation" => [ "heart_exclamation", "heavy_heart_exclamation_mark_ornament" ],
  "houses" => [ "homes", "house_buildings" ],
  "hotdog" => [ "hot_dog" ],
  "derelict_house" => [ "house_abandoned", "derelict_house_building" ],
  "desert_island" => [ "island" ],
  "old_key" => [ "key2" ],
  "laughing" => [ "satisfied" ],
  "business_suit_levitating" => [ "levitate", "man_in_business_suit_levitating" ],
  "weight_lifting_man" => [ "lifter", "weight_lifter" ],
  "medal_sports" => [ "medal", "sports_medal" ],
  "metal" => [ "sign_of_the_horns" ],
  "fu" => [ "middle_finger", "reversed_hand_with_middle_finger_extended" ],
  "motorcycle" => [ "racing_motorcycle" ],
  "mountain_snow" => [ "snow_capped_mountain" ],
  "newspaper_roll" => [ "newspaper2", "rolled_up_newspaper" ],
  "spiral_notepad" => [ "notepad_spiral", "spiral_note_pad" ],
  "oil_drum" => [ "oil" ],
  "older_woman" => [ "grandma" ],
  "paintbrush" => [ "lower_left_paintbrush" ],
  "paperclips" => [ "linked_paperclips" ],
  "pause_button" => [ "double_vertical_bar" ],
  "peace_symbol" => [ "peace" ],
  "pen_ballpoint" => [ "lower_left_ballpoint_pen" ],
  "fountain_pen" => [ "pen_fountain", "lower_left_fountain_pen" ],
  "ping_pong" => [ "table_tennis" ],
  "place_of_worship" => [ "worship_symbol" ],
  "poop" => [ "shit", "hankey", "poo" ],
  "radioactive" => [ "radioactive_sign" ],
  "railway_track" => [ "railroad_track" ],
  "robot" => [ "robot_face" ],
  "skull" => [ "skeleton" ],
  "skull_and_crossbones" => [ "skull_crossbones" ],
  "speaking_head" => [ "speaking_head_in_silhouette" ],
  "male_detective" => [ "spy", "sleuth_or_spy" ],
  "thinking" => [ "thinking_face" ],
  "thumbsdown" => [ "-1" ],
  "thumbsup" => [ "+1" ],
  "cloud_with_lightning_and_rain" => [ "thunder_cloud_rain", "thunder_cloud_and_rain" ],
  "tickets" => [ "admission_tickets" ],
  "next_track_button" => [ "track_next", "next_track" ],
  "previous_track_button" => [ "track_previous", "previous_track" ],
  "unicorn" => [ "unicorn_face" ],
  "funeral_urn" => [ "urn" ],
  "sun_behind_large_cloud" => [ "white_sun_cloud", "white_sun_behind_cloud" ],
  "sun_behind_rain_cloud" => [ "white_sun_rain_cloud", "white_sun_behind_cloud_with_rain" ],
  "partly_sunny" => [ "white_sun_small_cloud", "white_sun_with_small_cloud" ],
  "open_umbrella" => [ "umbrella2" ],
  "hammer_and_wrench" => [ "tools" ],
  "face_with_thermometer" => [ "thermometer_face" ],
  "timer_clock" => [ "timer" ],
  "keycap_ten" => [ "ten" ],
  "memo" => [ "pencil" ],
  "rescue_worker_helmet" => [ "helmet_with_cross", "helmet_with_white_cross" ],
  "slightly_smiling_face" => [ "slightly_smiling", "slight_smile"],
  "construction_worker_man" => [ "construction_worker" ],
  "upside_down_face" => [ "upside_down" ],
  "money_mouth_face" => [ "money_mouth" ],
  "nerd_face" => [ "nerd" ],
  "hugs" => [ "hugging", "hugging_face" ],
  "roll_eyes" => [ "rolling_eyes", "face_with_rolling_eyes" ],
  "slightly_frowning_face" => [ "slight_frown" ],
  "frowning_face" => [ "frowning2", "white_frowning_face" ],
  "zipper_mouth_face" => [ "zipper_mouth" ],
  "face_with_head_bandage" => [ "head_bandage" ],
  "raised_hand_with_fingers_splayed" => [ "hand_splayed" ],
  "raised_hand" => [ "hand" ],
  "vulcan_salute" => [ "vulcan", "raised_hand_with_part_between_middle_and_ring_fingers" ],
  "policeman" => [ "cop" ],
  "running_man" => [ "runner" ],
  "walking_man" => [ "walking" ],
  "bowing_man" => [ "bow" ],
  "no_good_woman" => [ "no_good" ],
  "raising_hand_woman" => [ "raising_hand" ],
  "pouting_woman" => [ "person_with_pouting_face" ],
  "frowning_woman" => [ "person_frowning" ],
  "haircut_woman" => [ "haircut" ],
  "massage_woman" => [ "massage" ],
  "tshirt" => [ "shirt" ],
  "biking_man" => [ "bicyclist" ],
  "mountain_biking_man" => [ "mountain_bicyclist" ],
  "passenger_ship" => [ "cruise_ship" ],
  "motor_boat" => [ "motorboat", "boat" ],
  "flight_arrival" => [ "airplane_arriving" ],
  "flight_departure" => [ "airplane_departure" ],
  "small_airplane" => [ "airplane_small" ],
  "racing_car" => [ "race_car" ],
  "family_man_woman_boy_boy" => [ "family_man_woman_boys" ],
  "family_man_woman_girl_girl" => [ "family_man_woman_girls" ],
  "family_woman_woman_boy" => [ "family_women_boy" ],
  "family_woman_woman_girl" => [ "family_women_girl" ],
  "family_woman_woman_girl_boy" => [ "family_women_girl_boy" ],
  "family_woman_woman_boy_boy" => [ "family_women_boys" ],
  "family_woman_woman_girl_girl" => [ "family_women_girls" ],
  "family_man_man_boy" => [ "family_men_boy" ],
  "family_man_man_girl" => [ "family_men_girl" ],
  "family_man_man_girl_boy" => [ "family_men_girl_boy" ],
  "family_man_man_boy_boy" => [ "family_men_boys" ],
  "family_man_man_girl_girl" => [ "family_men_girls" ],
  "cloud_with_lightning" => [ "cloud_lightning" ],
  "tornado" => [ "cloud_tornado", "cloud_with_tornado" ],
  "cloud_with_rain" => [ "cloud_rain" ],
  "cloud_with_snow" => [ "cloud_snow" ],
  "asterisk" => [ "keycap_star" ],
  "studio_microphone" => [ "microphone2" ],
  "medal_military" => [ "military_medal" ],
  "couple_with_heart_woman_woman" => [ "female_couple_with_heart" ],
  "couple_with_heart_man_man" => [ "male_couple_with_heart" ],
  "couplekiss_woman_woman" => [ "female_couplekiss" ],
  "couplekiss_man_man" => [ "male_couplekiss" ],
  "honeybee" => [ "bee" ],
  "lion" => [ "lion_face" ],
  "artificial_satellite" => [ "satellite_orbital" ],
  "computer_mouse" => [ "mouse_three_button", "three_button_mouse" ],
  "hocho" => [ "knife" ],
  "swimming_man" => [ "swimmer" ],
  "wind_face" => [ "wind_blowing_face" ],
  "golfing_man" => [ "golfer" ],
  "facepunch" => [ "punch" ],
  "building_construction" => [ "construction_site" ],
  "family_man_woman_girl_boy" => [ "family" ],
  "ice_hockey" => [ "hockey" ],
  "snowman_with_snow" => [ "snowman2" ],
  "play_or_pause_button" => [ "play_pause" ],
  "film_projector" => [ "projector" ],
  "shopping" => [ "shopping_bags" ],
  "open_book" => [ "book" ],
  "national_park" => [ "park" ],
  "world_map" => [ "map" ],
  "pen" => [ "pen_ballpoint" ],
  "email" => [ "envelope", "e-mail" ],
  "phone" => [ "telephone" ],
  "atom_symbol" => [ "atom" ],
  "mantelpiece_clock" => [ "clock" ],
  "camera_flash" => [ "camera_with_flash" ],
  "film_strip" => [ "film_frames" ],
  "balance_scale" => [ "scales" ],
  "surfing_man" => [ "surfer" ],
  "couplekiss_man_woman" => [ "couplekiss" ],
  "couple_with_heart_woman_man" => [ "couple_with_heart" ],
  "clamp" => [ "compression" ],
  "dancing_women" => [ "dancers" ],
  "blonde_man" => [ "person_with_blond_hair" ],
  "sleeping_bed" => [ "sleeping_accommodation" ],
  "om" => [ "om_symbol" ],
  "tipping_hand_woman" => [ "information_desk_person" ],
  "rowing_man" => [ "rowboat" ],
  "new_moon" => [ "moon" ],
  "oncoming_automobile" => [ "car", "automobile" ],
  "fleur_de_lis" => [ "fleur-de-lis" ],
}

EMOJI_GROUPS ||= [
  {
    "name" => "people",
    "fullname" => "People",
    "tabicon" => "grinning",
    "sections" => [
      "face-positive",
      "face-neutral",
      "face-negative",
      "face-sick",
      "face-role",
      "face-fantasy",
      "cat-face",
      "monkey-face",
      "skin-tone",
      "person",
      "person-role",
      "person-fantasy",
      "person-gesture",
      "family",
      "body"
    ]
  },
  {
    "name" => "nature",
    "fullname" => "Nature",
    "tabicon" => "evergreen_tree",
    "sections" => [
      "animal-mammal",
      "animal-bird",
      "animal-amphibian",
      "animal-reptile",
      "animal-marine",
      "animal-bug",
      "plant-flower",
      "plant-other",
      "sky_&_weather",

    ]
  },
  {
    "name" => "food",
    "fullname" => "Food & Drink",
    "tabicon" => "hamburger",
    "sections" => [
      "food-fruit",
      "food-vegetable",
      "food-prepared",
      "food-asian",
      "food-sweet",
      "drink",
      "dishware"
    ]
  },
  {
    "name" => "celebration",
    "fullname" => "Celebration",
    "tabicon" => "gift",
    "sections" => [
      "event",
      "emotion"
    ]
  },
  {
    "name" => "activity",
    "fullname" => "Activities",
    "tabicon" => "soccer",
    "sections" => [
      "person-activity",
      "person-sport",
      "sport",
      "game",
      "music",
      "musical-instrument"
    ]
  },
  {
    "name" => "travel",
    "fullname" => "Travel & Places",
    "tabicon" => "airplane",
    "sections" => [
      "place-map",
      "place-geographic",
      "place-building",
      "place-religious",
      "place-other",
      "transport-ground",
      "transport-water",
      "transport-air",
      "hotel",
      "flag",
      "country-flag",
      "subdivision-flag"
    ]
  },
  {
    "name" => "objects",
    "fullname" => "Objects & Symbols",
    "tabicon" => "eyeglasses",
    "sections" => [
      "clothing",
      "award-medal",
      "sound",
      "phone",
      "computer",
      "light_&_video",
      "book-paper",
      "money",
      "mail",
      "writing",
      "office",
      "lock",
      "tool",
      "medical",
      "other-object",
      "transport-sign",
      "warning",
      "arrow",
      "religion",
      "zodiac",
      "av-symbol",
      "other-symbol",
      "keycap",
      "alphanum",
      "geometric",
      "time"
    ]
  }
]

FITZPATRICK_SCALE ||= [ "1f3fb", "1f3fc", "1f3fd", "1f3fe", "1f3ff" ]

VARIATION_SELECTOR ||= "fe0f"

# Patch content of EMOJI_KEYWORDS_URL
EMOJI_KEYWORDS_PATCH ||= {
  "man_singer" => { "fitzpatrick_scale" => true },
  "woman_singer" => { "fitzpatrick_scale" => true },
  "woman_student" => { "fitzpatrick_scale" => true },
  "man_student" => { "fitzpatrick_scale" => true },
  "woman_cook" => { "fitzpatrick_scale" => true },
  "man_cook" => { "fitzpatrick_scale" => true },
  "thumbsup" => { "char" => "👍", "fitzpatrick_scale" => true },
  "thumbsdown" => { "char" => "👎", "fitzpatrick_scale" => true },
  "asterisk" => { "char" => "*️⃣" },
  "dancing_men" => { "char" => "👯‍♂️️" },
  "women_wrestling" => { "char" => "🤼‍♀️️", "fitzpatrick_scale" => false },
  "men_wrestling" => { "char" => "🤼‍♂️️", "fitzpatrick_scale" => false },
  "female_detective" => { "char" => "🕵️‍♀️", "fitzpatrick_scale" => true },
  "blonde_woman" => { "fitzpatrick_scale" => true },
  "woman_with_turban" => { "fitzpatrick_scale" => true },
  "policewoman" => { "fitzpatrick_scale" => true },
  "construction_worker_woman" => { "fitzpatrick_scale" => true },
  "guardswoman" => { "fitzpatrick_scale" => true },
  "woman_health_worker" => { "fitzpatrick_scale" => true },
  "man_health_worker" => { "fitzpatrick_scale" => true },
  "woman_pilot" => { "fitzpatrick_scale" => true },
  "man_pilot" => { "fitzpatrick_scale" => true },
  "woman_judge" => { "fitzpatrick_scale" => true },
  "man_judge" => { "fitzpatrick_scale" => true },
  "running_woman" => { "fitzpatrick_scale" => true },
  "walking_woman" => { "fitzpatrick_scale" => true },
  "woman_facepalming" => { "fitzpatrick_scale" => true },
  "bowing_woman" => { "fitzpatrick_scale" => true },
  "woman_shrugging" => { "char" => "🤷‍♀️" },
  "man_shrugging" => { "fitzpatrick_scale" => true },
  "tipping_hand_man" => { "fitzpatrick_scale" => true },
  "no_good_man" => { "fitzpatrick_scale" => true },
  "ok_man" => { "fitzpatrick_scale" => true },
  "raising_hand_man" => { "fitzpatrick_scale" => true },
  "pouting_man" => { "fitzpatrick_scale" => true },
  "frowning_man" => { "fitzpatrick_scale" => true },
  "haircut_man" => { "fitzpatrick_scale" => true },
  "massage_man" => { "fitzpatrick_scale" => true },
  "golfing_woman" => { "fitzpatrick_scale" => true },
  "rowing_woman" => { "fitzpatrick_scale" => true },
  "swimming_woman" => { "fitzpatrick_scale" => true },
  "surfing_woman" => { "fitzpatrick_scale" => true },
  "basketball_woman" => { "fitzpatrick_scale" => true },
  "weight_lifting_woman" => { "fitzpatrick_scale" => true },
  "biking_woman" => { "fitzpatrick_scale" => true },
  "mountain_biking_woman" => { "fitzpatrick_scale" => true },
  "handshake" => { "fitzpatrick_scale" => false },
  "dancing_women" => { "fitzpatrick_scale" => false },
  "couple" => { "fitzpatrick_scale" => false },
  "two_men_holding_hands" => { "fitzpatrick_scale" => false },
  "two_women_holding_hands" => { "fitzpatrick_scale" => false },
  "couple_with_heart_woman_man" => { "fitzpatrick_scale" => false },
  "couplekiss_man_woman" => { "fitzpatrick_scale" => false },
  "family_man_woman_boy" => { "fitzpatrick_scale" => false },
  "rescue_worker_helmet" => { "fitzpatrick_scale" => false },
  "skier" => { "fitzpatrick_scale" => false }
}

# Exclude keywords from EMOJI_KEYWORDS_URL
EMOJI_KEYWORDS_EXCLUDE_LIST ||= [ "+1", "-1" ]

# Cell index of each platform in EMOJI_LIST_URL
EICI ||= EMOJI_IMAGES_CELLS_INDEX ||= {
  :windows => 10,
  :apple => 3,
  :google => 4,
  :twitter => 5,
  :one => 6
}

# Replace the platform by another when downloading the image
EMOJI_IMAGES_CELLS_INDEX_PATCH ||= {
  :apple => {
    "snowboarder" => EICI[:twitter],
    "snowboarder/2" => EICI[:twitter],
    "snowboarder/3" => EICI[:twitter],
    "snowboarder/4" => EICI[:twitter],
    "snowboarder/5" => EICI[:twitter],
    "snowboarder/6" => EICI[:twitter],
    "sleeping_bed" => EICI[:twitter],
    "sleeping_bed/2" => EICI[:twitter],
    "sleeping_bed/3" => EICI[:twitter],
    "sleeping_bed/4" => EICI[:twitter],
    "sleeping_bed/5" => EICI[:twitter],
    "sleeping_bed/6" => EICI[:twitter],
  },
  :one => {
    # dot not use emoji-one rounded flags
    "afghanistan" => EICI[:twitter],
    "aland_islands" => EICI[:twitter],
    "albania" => EICI[:twitter],
    "algeria" => EICI[:twitter],
    "american_samoa" => EICI[:twitter],
    "andorra" => EICI[:twitter],
    "angola" => EICI[:twitter],
    "anguilla" => EICI[:twitter],
    "antarctica" => EICI[:twitter],
    "antigua_barbuda" => EICI[:twitter],
    "argentina" => EICI[:twitter],
    "armenia" => EICI[:twitter],
    "aruba" => EICI[:twitter],
    "australia" => EICI[:twitter],
    "austria" => EICI[:twitter],
    "azerbaijan" => EICI[:twitter],
    "bahamas" => EICI[:twitter],
    "bahrain" => EICI[:twitter],
    "bangladesh" => EICI[:twitter],
    "barbados" => EICI[:twitter],
    "belarus" => EICI[:twitter],
    "belgium" => EICI[:twitter],
    "belize" => EICI[:twitter],
    "benin" => EICI[:twitter],
    "bermuda" => EICI[:twitter],
    "bhutan" => EICI[:twitter],
    "bolivia" => EICI[:twitter],
    "caribbean_netherlands" => EICI[:twitter],
    "bosnia_herzegovina" => EICI[:twitter],
    "botswana" => EICI[:twitter],
    "brazil" => EICI[:twitter],
    "british_indian_ocean_territory" => EICI[:twitter],
    "british_virgin_islands" => EICI[:twitter],
    "brunei" => EICI[:twitter],
    "bulgaria" => EICI[:twitter],
    "burkina_faso" => EICI[:twitter],
    "burundi" => EICI[:twitter],
    "cape_verde" => EICI[:twitter],
    "cambodia" => EICI[:twitter],
    "cameroon" => EICI[:twitter],
    "canada" => EICI[:twitter],
    "canary_islands" => EICI[:twitter],
    "cayman_islands" => EICI[:twitter],
    "central_african_republic" => EICI[:twitter],
    "chad" => EICI[:twitter],
    "chile" => EICI[:twitter],
    "cn" => EICI[:twitter],
    "christmas_island" => EICI[:twitter],
    "cocos_islands" => EICI[:twitter],
    "colombia" => EICI[:twitter],
    "comoros" => EICI[:twitter],
    "congo_brazzaville" => EICI[:twitter],
    "congo_kinshasa" => EICI[:twitter],
    "cook_islands" => EICI[:twitter],
    "costa_rica" => EICI[:twitter],
    "croatia" => EICI[:twitter],
    "cuba" => EICI[:twitter],
    "curacao" => EICI[:twitter],
    "cyprus" => EICI[:twitter],
    "czech_republic" => EICI[:twitter],
    "denmark" => EICI[:twitter],
    "djibouti" => EICI[:twitter],
    "dominica" => EICI[:twitter],
    "dominican_republic" => EICI[:twitter],
    "ecuador" => EICI[:twitter],
    "egypt" => EICI[:twitter],
    "el_salvador" => EICI[:twitter],
    "equatorial_guinea" => EICI[:twitter],
    "eritrea" => EICI[:twitter],
    "estonia" => EICI[:twitter],
    "ethiopia" => EICI[:twitter],
    "eu" => EICI[:twitter],
    "falkland_islands" => EICI[:twitter],
    "faroe_islands" => EICI[:twitter],
    "fiji" => EICI[:twitter],
    "finland" => EICI[:twitter],
    "fr" => EICI[:twitter],
    "french_guiana" => EICI[:twitter],
    "french_polynesia" => EICI[:twitter],
    "french_southern_territories" => EICI[:twitter],
    "gabon" => EICI[:twitter],
    "gambia" => EICI[:twitter],
    "georgia" => EICI[:twitter],
    "de" => EICI[:twitter],
    "ghana" => EICI[:twitter],
    "gibraltar" => EICI[:twitter],
    "greece" => EICI[:twitter],
    "greenland" => EICI[:twitter],
    "grenada" => EICI[:twitter],
    "guadeloupe" => EICI[:twitter],
    "guam" => EICI[:twitter],
    "guatemala" => EICI[:twitter],
    "guernsey" => EICI[:twitter],
    "guinea" => EICI[:twitter],
    "guinea_bissau" => EICI[:twitter],
    "guyana" => EICI[:twitter],
    "haiti" => EICI[:twitter],
    "honduras" => EICI[:twitter],
    "hong_kong" => EICI[:twitter],
    "hungary" => EICI[:twitter],
    "iceland" => EICI[:twitter],
    "india" => EICI[:twitter],
    "indonesia" => EICI[:twitter],
    "iran" => EICI[:twitter],
    "iraq" => EICI[:twitter],
    "ireland" => EICI[:twitter],
    "isle_of_man" => EICI[:twitter],
    "israel" => EICI[:twitter],
    "it" => EICI[:twitter],
    "cote_divoire" => EICI[:twitter],
    "jamaica" => EICI[:twitter],
    "jp" => EICI[:twitter],
    "jersey" => EICI[:twitter],
    "jordan" => EICI[:twitter],
    "kazakhstan" => EICI[:twitter],
    "kenya" => EICI[:twitter],
    "kiribati" => EICI[:twitter],
    "kosovo" => EICI[:twitter],
    "kuwait" => EICI[:twitter],
    "kyrgyzstan" => EICI[:twitter],
    "laos" => EICI[:twitter],
    "latvia" => EICI[:twitter],
    "lebanon" => EICI[:twitter],
    "lesotho" => EICI[:twitter],
    "liberia" => EICI[:twitter],
    "libya" => EICI[:twitter],
    "liechtenstein" => EICI[:twitter],
    "lithuania" => EICI[:twitter],
    "luxembourg" => EICI[:twitter],
    "macau" => EICI[:twitter],
    "macedonia" => EICI[:twitter],
    "madagascar" => EICI[:twitter],
    "malawi" => EICI[:twitter],
    "malaysia" => EICI[:twitter],
    "maldives" => EICI[:twitter],
    "mali" => EICI[:twitter],
    "malta" => EICI[:twitter],
    "marshall_islands" => EICI[:twitter],
    "martinique" => EICI[:twitter],
    "mauritania" => EICI[:twitter],
    "mauritius" => EICI[:twitter],
    "mayotte" => EICI[:twitter],
    "mexico" => EICI[:twitter],
    "micronesia" => EICI[:twitter],
    "moldova" => EICI[:twitter],
    "monaco" => EICI[:twitter],
    "mongolia" => EICI[:twitter],
    "montenegro" => EICI[:twitter],
    "montserrat" => EICI[:twitter],
    "morocco" => EICI[:twitter],
    "mozambique" => EICI[:twitter],
    "myanmar" => EICI[:twitter],
    "namibia" => EICI[:twitter],
    "nauru" => EICI[:twitter],
    "nepal" => EICI[:twitter],
    "netherlands" => EICI[:twitter],
    "new_caledonia" => EICI[:twitter],
    "new_zealand" => EICI[:twitter],
    "nicaragua" => EICI[:twitter],
    "niger" => EICI[:twitter],
    "nigeria" => EICI[:twitter],
    "niue" => EICI[:twitter],
    "norfolk_island" => EICI[:twitter],
    "northern_mariana_islands" => EICI[:twitter],
    "north_korea" => EICI[:twitter],
    "norway" => EICI[:twitter],
    "oman" => EICI[:twitter],
    "pakistan" => EICI[:twitter],
    "palau" => EICI[:twitter],
    "palestinian_territories" => EICI[:twitter],
    "panama" => EICI[:twitter],
    "papua_new_guinea" => EICI[:twitter],
    "paraguay" => EICI[:twitter],
    "peru" => EICI[:twitter],
    "philippines" => EICI[:twitter],
    "pitcairn_islands" => EICI[:twitter],
    "poland" => EICI[:twitter],
    "portugal" => EICI[:twitter],
    "puerto_rico" => EICI[:twitter],
    "qatar" => EICI[:twitter],
    "reunion" => EICI[:twitter],
    "romania" => EICI[:twitter],
    "ru" => EICI[:twitter],
    "rwanda" => EICI[:twitter],
    "st_barthelemy" => EICI[:twitter],
    "st_helena" => EICI[:twitter],
    "st_kitts_nevis" => EICI[:twitter],
    "st_lucia" => EICI[:twitter],
    "st_pierre_miquelon" => EICI[:twitter],
    "st_vincent_grenadines" => EICI[:twitter],
    "samoa" => EICI[:twitter],
    "san_marino" => EICI[:twitter],
    "sao_tome_principe" => EICI[:twitter],
    "saudi_arabia" => EICI[:twitter],
    "senegal" => EICI[:twitter],
    "serbia" => EICI[:twitter],
    "seychelles" => EICI[:twitter],
    "sierra_leone" => EICI[:twitter],
    "singapore" => EICI[:twitter],
    "sint_maarten" => EICI[:twitter],
    "slovakia" => EICI[:twitter],
    "slovenia" => EICI[:twitter],
    "solomon_islands" => EICI[:twitter],
    "somalia" => EICI[:twitter],
    "south_africa" => EICI[:twitter],
    "south_georgia_south_sandwich_islands" => EICI[:twitter],
    "kr" => EICI[:twitter],
    "south_sudan" => EICI[:twitter],
    "es" => EICI[:twitter],
    "sri_lanka" => EICI[:twitter],
    "sudan" => EICI[:twitter],
    "suriname" => EICI[:twitter],
    "swaziland" => EICI[:twitter],
    "sweden" => EICI[:twitter],
    "switzerland" => EICI[:twitter],
    "syria" => EICI[:twitter],
    "taiwan" => EICI[:twitter],
    "tajikistan" => EICI[:twitter],
    "tanzania" => EICI[:twitter],
    "thailand" => EICI[:twitter],
    "timor_leste" => EICI[:twitter],
    "togo" => EICI[:twitter],
    "tokelau" => EICI[:twitter],
    "tonga" => EICI[:twitter],
    "trinidad_tobago" => EICI[:twitter],
    "tunisia" => EICI[:twitter],
    "tr" => EICI[:twitter],
    "turkmenistan" => EICI[:twitter],
    "turks_caicos_islands" => EICI[:twitter],
    "tuvalu" => EICI[:twitter],
    "uganda" => EICI[:twitter],
    "ukraine" => EICI[:twitter],
    "united_arab_emirates" => EICI[:twitter],
    "uk" => EICI[:twitter],
    "us" => EICI[:twitter],
    "us_virgin_islands" => EICI[:twitter],
    "uruguay" => EICI[:twitter],
    "uzbekistan" => EICI[:twitter],
    "vanuatu" => EICI[:twitter],
    "vatican_city" => EICI[:twitter],
    "venezuela" => EICI[:twitter],
    "vietnam" => EICI[:twitter],
    "wallis_futuna" => EICI[:twitter],
    "western_sahara" => EICI[:twitter],
    "yemen" => EICI[:twitter],
    "zambia" => EICI[:twitter],
    "zimbabwe" => EICI[:twitter],
  },
  :windows => {
    "hash" => EICI[:apple],
    "zero" => EICI[:apple],
    "one" => EICI[:apple],
    "two" => EICI[:apple],
    "three" => EICI[:apple],
    "four" => EICI[:apple],
    "five" => EICI[:apple],
    "six" => EICI[:apple],
    "seven" => EICI[:apple],
    "eight" => EICI[:apple],
    "nine" => EICI[:apple],
    "asterisk" => EICI[:apple],
    "afghanistan" => EICI[:twitter],
    "aland_islands" => EICI[:twitter],
    "albania" => EICI[:twitter],
    "algeria" => EICI[:twitter],
    "american_samoa" => EICI[:twitter],
    "andorra" => EICI[:twitter],
    "angola" => EICI[:twitter],
    "anguilla" => EICI[:twitter],
    "antarctica" => EICI[:twitter],
    "antigua_barbuda" => EICI[:twitter],
    "argentina" => EICI[:twitter],
    "armenia" => EICI[:twitter],
    "aruba" => EICI[:twitter],
    "australia" => EICI[:twitter],
    "austria" => EICI[:twitter],
    "azerbaijan" => EICI[:twitter],
    "bahamas" => EICI[:twitter],
    "bahrain" => EICI[:twitter],
    "bangladesh" => EICI[:twitter],
    "barbados" => EICI[:twitter],
    "belarus" => EICI[:twitter],
    "belgium" => EICI[:twitter],
    "belize" => EICI[:twitter],
    "benin" => EICI[:twitter],
    "bermuda" => EICI[:twitter],
    "bhutan" => EICI[:twitter],
    "bolivia" => EICI[:twitter],
    "caribbean_netherlands" => EICI[:twitter],
    "bosnia_herzegovina" => EICI[:twitter],
    "botswana" => EICI[:twitter],
    "brazil" => EICI[:twitter],
    "british_indian_ocean_territory" => EICI[:twitter],
    "british_virgin_islands" => EICI[:twitter],
    "brunei" => EICI[:twitter],
    "bulgaria" => EICI[:twitter],
    "burkina_faso" => EICI[:twitter],
    "burundi" => EICI[:twitter],
    "cape_verde" => EICI[:twitter],
    "cambodia" => EICI[:twitter],
    "cameroon" => EICI[:twitter],
    "canada" => EICI[:twitter],
    "canary_islands" => EICI[:twitter],
    "cayman_islands" => EICI[:twitter],
    "central_african_republic" => EICI[:twitter],
    "chad" => EICI[:twitter],
    "chile" => EICI[:twitter],
    "cn" => EICI[:twitter],
    "christmas_island" => EICI[:twitter],
    "cocos_islands" => EICI[:twitter],
    "colombia" => EICI[:twitter],
    "comoros" => EICI[:twitter],
    "congo_brazzaville" => EICI[:twitter],
    "congo_kinshasa" => EICI[:twitter],
    "cook_islands" => EICI[:twitter],
    "costa_rica" => EICI[:twitter],
    "croatia" => EICI[:twitter],
    "cuba" => EICI[:twitter],
    "curacao" => EICI[:twitter],
    "cyprus" => EICI[:twitter],
    "czech_republic" => EICI[:twitter],
    "denmark" => EICI[:twitter],
    "djibouti" => EICI[:twitter],
    "dominica" => EICI[:twitter],
    "dominican_republic" => EICI[:twitter],
    "ecuador" => EICI[:twitter],
    "egypt" => EICI[:twitter],
    "el_salvador" => EICI[:twitter],
    "equatorial_guinea" => EICI[:twitter],
    "eritrea" => EICI[:twitter],
    "estonia" => EICI[:twitter],
    "ethiopia" => EICI[:twitter],
    "eu" => EICI[:twitter],
    "falkland_islands" => EICI[:twitter],
    "faroe_islands" => EICI[:twitter],
    "fiji" => EICI[:twitter],
    "finland" => EICI[:twitter],
    "fr" => EICI[:twitter],
    "french_guiana" => EICI[:twitter],
    "french_polynesia" => EICI[:twitter],
    "french_southern_territories" => EICI[:twitter],
    "gabon" => EICI[:twitter],
    "gambia" => EICI[:twitter],
    "georgia" => EICI[:twitter],
    "de" => EICI[:twitter],
    "ghana" => EICI[:twitter],
    "gibraltar" => EICI[:twitter],
    "greece" => EICI[:twitter],
    "greenland" => EICI[:twitter],
    "grenada" => EICI[:twitter],
    "guadeloupe" => EICI[:twitter],
    "guam" => EICI[:twitter],
    "guatemala" => EICI[:twitter],
    "guernsey" => EICI[:twitter],
    "guinea" => EICI[:twitter],
    "guinea_bissau" => EICI[:twitter],
    "guyana" => EICI[:twitter],
    "haiti" => EICI[:twitter],
    "honduras" => EICI[:twitter],
    "hong_kong" => EICI[:twitter],
    "hungary" => EICI[:twitter],
    "iceland" => EICI[:twitter],
    "india" => EICI[:twitter],
    "indonesia" => EICI[:twitter],
    "iran" => EICI[:twitter],
    "iraq" => EICI[:twitter],
    "ireland" => EICI[:twitter],
    "isle_of_man" => EICI[:twitter],
    "israel" => EICI[:twitter],
    "it" => EICI[:twitter],
    "cote_divoire" => EICI[:twitter],
    "jamaica" => EICI[:twitter],
    "jp" => EICI[:twitter],
    "jersey" => EICI[:twitter],
    "jordan" => EICI[:twitter],
    "kazakhstan" => EICI[:twitter],
    "kenya" => EICI[:twitter],
    "kiribati" => EICI[:twitter],
    "kosovo" => EICI[:twitter],
    "kuwait" => EICI[:twitter],
    "kyrgyzstan" => EICI[:twitter],
    "laos" => EICI[:twitter],
    "latvia" => EICI[:twitter],
    "lebanon" => EICI[:twitter],
    "lesotho" => EICI[:twitter],
    "liberia" => EICI[:twitter],
    "libya" => EICI[:twitter],
    "liechtenstein" => EICI[:twitter],
    "lithuania" => EICI[:twitter],
    "luxembourg" => EICI[:twitter],
    "macau" => EICI[:twitter],
    "macedonia" => EICI[:twitter],
    "madagascar" => EICI[:twitter],
    "malawi" => EICI[:twitter],
    "malaysia" => EICI[:twitter],
    "maldives" => EICI[:twitter],
    "mali" => EICI[:twitter],
    "malta" => EICI[:twitter],
    "marshall_islands" => EICI[:twitter],
    "martinique" => EICI[:twitter],
    "mauritania" => EICI[:twitter],
    "mauritius" => EICI[:twitter],
    "mayotte" => EICI[:twitter],
    "mexico" => EICI[:twitter],
    "micronesia" => EICI[:twitter],
    "moldova" => EICI[:twitter],
    "monaco" => EICI[:twitter],
    "mongolia" => EICI[:twitter],
    "montenegro" => EICI[:twitter],
    "montserrat" => EICI[:twitter],
    "morocco" => EICI[:twitter],
    "mozambique" => EICI[:twitter],
    "myanmar" => EICI[:twitter],
    "namibia" => EICI[:twitter],
    "nauru" => EICI[:twitter],
    "nepal" => EICI[:twitter],
    "netherlands" => EICI[:twitter],
    "new_caledonia" => EICI[:twitter],
    "new_zealand" => EICI[:twitter],
    "nicaragua" => EICI[:twitter],
    "niger" => EICI[:twitter],
    "nigeria" => EICI[:twitter],
    "niue" => EICI[:twitter],
    "norfolk_island" => EICI[:twitter],
    "northern_mariana_islands" => EICI[:twitter],
    "north_korea" => EICI[:twitter],
    "norway" => EICI[:twitter],
    "oman" => EICI[:twitter],
    "pakistan" => EICI[:twitter],
    "palau" => EICI[:twitter],
    "palestinian_territories" => EICI[:twitter],
    "panama" => EICI[:twitter],
    "papua_new_guinea" => EICI[:twitter],
    "paraguay" => EICI[:twitter],
    "peru" => EICI[:twitter],
    "philippines" => EICI[:twitter],
    "pitcairn_islands" => EICI[:twitter],
    "poland" => EICI[:twitter],
    "portugal" => EICI[:twitter],
    "puerto_rico" => EICI[:twitter],
    "qatar" => EICI[:twitter],
    "reunion" => EICI[:twitter],
    "romania" => EICI[:twitter],
    "ru" => EICI[:twitter],
    "rwanda" => EICI[:twitter],
    "st_barthelemy" => EICI[:twitter],
    "st_helena" => EICI[:twitter],
    "st_kitts_nevis" => EICI[:twitter],
    "st_lucia" => EICI[:twitter],
    "st_pierre_miquelon" => EICI[:twitter],
    "st_vincent_grenadines" => EICI[:twitter],
    "samoa" => EICI[:twitter],
    "san_marino" => EICI[:twitter],
    "sao_tome_principe" => EICI[:twitter],
    "saudi_arabia" => EICI[:twitter],
    "senegal" => EICI[:twitter],
    "serbia" => EICI[:twitter],
    "seychelles" => EICI[:twitter],
    "sierra_leone" => EICI[:twitter],
    "singapore" => EICI[:twitter],
    "sint_maarten" => EICI[:twitter],
    "slovakia" => EICI[:twitter],
    "slovenia" => EICI[:twitter],
    "solomon_islands" => EICI[:twitter],
    "somalia" => EICI[:twitter],
    "south_africa" => EICI[:twitter],
    "south_georgia_south_sandwich_islands" => EICI[:twitter],
    "kr" => EICI[:twitter],
    "south_sudan" => EICI[:twitter],
    "es" => EICI[:twitter],
    "sri_lanka" => EICI[:twitter],
    "sudan" => EICI[:twitter],
    "suriname" => EICI[:twitter],
    "swaziland" => EICI[:twitter],
    "sweden" => EICI[:twitter],
    "switzerland" => EICI[:twitter],
    "syria" => EICI[:twitter],
    "taiwan" => EICI[:twitter],
    "tajikistan" => EICI[:twitter],
    "tanzania" => EICI[:twitter],
    "thailand" => EICI[:twitter],
    "timor_leste" => EICI[:twitter],
    "togo" => EICI[:twitter],
    "tokelau" => EICI[:twitter],
    "tonga" => EICI[:twitter],
    "trinidad_tobago" => EICI[:twitter],
    "tunisia" => EICI[:twitter],
    "tr" => EICI[:twitter],
    "turkmenistan" => EICI[:twitter],
    "turks_caicos_islands" => EICI[:twitter],
    "tuvalu" => EICI[:twitter],
    "uganda" => EICI[:twitter],
    "ukraine" => EICI[:twitter],
    "united_arab_emirates" => EICI[:twitter],
    "uk" => EICI[:twitter],
    "us" => EICI[:twitter],
    "us_virgin_islands" => EICI[:twitter],
    "uruguay" => EICI[:twitter],
    "uzbekistan" => EICI[:twitter],
    "vanuatu" => EICI[:twitter],
    "vatican_city" => EICI[:twitter],
    "venezuela" => EICI[:twitter],
    "vietnam" => EICI[:twitter],
    "wallis_futuna" => EICI[:twitter],
    "western_sahara" => EICI[:twitter],
    "yemen" => EICI[:twitter],
    "zambia" => EICI[:twitter],
    "zimbabwe" => EICI[:twitter],
  }
}

PLATFORM_STYLES ||= {
  :apple => "apple",
  :google => "google",
  :twitter => "twitter",
  :one => "emoji_one",
  :windows => "win10"
}

desc "update emoji images"
task "emoji:update" do
  emojis = build_emojis_list(EMOJI_KEYWORDS_URL)
  images = build_images_list(EMOJI_LIST_URL, emojis)
  emojis.each { |code, emoji| emoji[:images] = ( images[code] || {} ) }
  write_emojis(emojis)
  write_db_json(emojis)
  groups = generate_emoji_groups(emojis)
  write_groups_js_es6(emojis, groups)

  puts "\r\n"
  $debugging_output.each { |debug| puts debug }

  TestEmojiUpdate.run_and_summarize
end

desc "test the emoji generation script"
task "emoji:test" do
  ENV['EMOJI_TEST'] = "1"
  Rake::Task["emoji:update"].invoke
end

def generate_emoji_groups(emojis)
  puts "Generating groups..."

  list = open(EMOJI_ORDERING_URL).read
  doc = Nokogiri::HTML(list)
  table = doc.css("table")[0]

  EMOJI_GROUPS.map do |group|
    group["icons"] ||= []
    group["sections"].each do |section|
      title_section = table.css("tr th a[@name='#{section}']")
      emoji_list_section = title_section.first.parent.parent.next_element
      emoji_list_section.css("a.plain img").each do |link|
        emoji_code = link.attr("title")
                         .scan(/U\+(.{4,5})\b/)
                         .flatten
                         .map { |code| code.downcase.strip }
                         .join("_")

        if emoji = emojis[emoji_code]
          group["icons"] << emoji[:name]
        end
      end
    end
    group.delete("sections")
    group
  end
end

def write_emojis(emojis)
  check_pngout

  path = "#{EMOJI_IMAGES_PATH}/**/*"
  confirm_overwrite(path)
  puts "Cleaning emoji folder..."
  FileUtils.rm_rf(Dir.glob(path))

  puts "Writing emojis to disk..."

  emojis.each do |code, emoji|
    images = emoji[:images]

    if images.values.all? { |image| !image.nil? }
      PLATFORM_STYLES.each do |platform, style|
        style_path = File.join(EMOJI_IMAGES_PATH, style)
        image_path = File.join(style_path, "#{emoji[:name]}.png")
        FileUtils.mkdir_p(File.expand_path("..", image_path))
        image = images[platform]

        write_emoji(image_path, image)

        if aliases = EMOJI_ALIASES[emoji[:name]]
          aliases.each do |alias_name|
            alias_image_path = File.join(style_path, "#{alias_name}.png")
            write_emoji(alias_image_path, image)
          end
        end
      end
    else
      platforms = images.select { |_, v| v.nil? }.keys.join(',')
      $debugging_output << "[!] Skipping `#{emoji[:name]} #{code_to_emoji(code)}`, undefined platforms: #{platforms}"
    end
  end

  puts "\r\n"
end

def build_emojis_list(url)
  puts "Downloading remote emoji list..."
  list = open(url).read

  emojis = {}

  keywords = JSON.parse(list).deep_merge(EMOJI_KEYWORDS_PATCH)
  EMOJI_KEYWORDS_EXCLUDE_LIST.each { |x| keywords.delete(x) }
  keywords.keys.each do |name|
    keyword = keywords[name]
    next unless char = keyword["char"].presence

    code = codepoints_to_code(char.codepoints, keyword["fitzpatrick_scale"])
    emojis[code] ||= {
      :name => name,
      :fitzpatrick_scale => keyword["fitzpatrick_scale"]
    }

    if keyword["fitzpatrick_scale"]
      emojis.merge!(generate_emoji_scales(name, code))
    end
  end

  emojis
end

def build_images_list(url, emojis)
  puts "Downloading remote emoji images list..."
  list = open(url).read

  puts "Parsing remote emoji images list..."
  images = {}

  doc = Nokogiri::HTML(list)
  table = doc.css("table")[0]
  table.css("tr").each do |row|
    cells = row.css("td")

    # skip header and section rows
    next if cells.size != 16

    code = cells[1].at_css("a")["name"]

    cell_to_img = lambda { |cell|
      return unless img = cell.at_css("img")
      Base64.decode64(img["src"][/base64,(.+)$/, 1])
    }

    images[code] = {}
    PLATFORM_STYLES.keys.each do |platform|
      default_cell_index = EMOJI_IMAGES_CELLS_INDEX[platform]

      if emoji = emojis[code]
        name = emoji[:name]
        patch_index = EMOJI_IMAGES_CELLS_INDEX_PATCH.fetch(platform, {})[name]

        if patch_index && cell_to_img.call(cells[default_cell_index])
          $debugging_output << "[!] Found existing image `#{name}` for platform: #{platform}, might want to remove the patch."
        end
      end

      index = patch_index || default_cell_index
      images[code][platform] = cell_to_img.call(cells[index])
    end

    putc "."
  end

  puts "\r\n"

  images
end

def write_db_json(emojis)
  puts "Writing #{EMOJI_DB_PATH}..."

  confirm_overwrite(EMOJI_DB_PATH)

  FileUtils.mkdir_p(File.expand_path("..", EMOJI_DB_PATH))

  # skin tones variations of emojis shouldn’t appear in autocomplete
  emojis_without_tones = emojis
    .select { |code, _| !FITZPATRICK_SCALE.any? {|scale| code[scale] } }
    .keys
    .map { |code|
      {
        "code" => code.tr("_", "-"),
        "name" => emojis[code][:name]
      }
    }

  emoji_with_tones = emojis
    .select { |code, emoji| emoji[:fitzpatrick_scale] }
    .keys
    .map { |code| emojis[code][:name] }

  db = {
    "emojis" => emojis_without_tones,
    "tonableEmojis" => emoji_with_tones,
    "aliases" => EMOJI_ALIASES
  }

  File.write(EMOJI_DB_PATH, JSON.pretty_generate(db))
end

def write_groups_js_es6(emojis, groups)
  puts "Writing #{EMOJI_GROUPS_PATH}..."

  confirm_overwrite(EMOJI_GROUPS_PATH)

  check_groups(emojis)

  template = <<TEMPLATE
// This file is generated by emoji.rake do not modify directly

// note that these categories are copied from Slack
const groups = #{JSON.pretty_generate(groups)};

export default groups;
TEMPLATE

  FileUtils.mkdir_p(File.expand_path("..", EMOJI_GROUPS_PATH))
  File.write(EMOJI_GROUPS_PATH, template)
end

def check_groups(emojis)
  grouped_emojis_names = EMOJI_GROUPS.map { |group| group["icons"] }.flatten

  emojis.each do |code, emoji|
    # we don’t group aliases
    next if EMOJI_ALIASES.values.flatten.include?(emoji[:name])

    # we don’t want skined toned emojis to appear in groups
    next if FITZPATRICK_SCALE.include?(code.split("_")[1])

    # we don’t need to categorize an already categorized aliased emoji
    aliases = EMOJI_ALIASES[emoji[:name]]
    next if aliases && grouped_emojis_names.any? { |name| aliases.include?(name) }

    if !grouped_emojis_names.include?(emoji[:name])
      $debugging_output << "[!] `#{emoji[:name]}` not found in any group, add it."
    end
  end

  emojis_names = emojis
                  .map { |_, emoji| emoji[:name] }
                  .concat(EMOJI_ALIASES.values).flatten

  grouped_emojis_names.each do |emoji_name|
    PLATFORM_STYLES.each do |_, style|
      path = File.join("public", "images", "emoji", style, "#{emoji_name}.png")
      if File.exists?(path) && !File.size?(path)
        $debugging_output << "[!] `#{emoji_name}` is in a group but we didn't create it. Possible fix: remove it, add an alias or patch keywords list."
      end
    end
  end
end

def write_emoji(path, image)
  open(path, "wb") { |file| file << image }
  `pngout #{path} -s0` if !ENV['EMOJI_TEST']
  putc "."
ensure
  if File.exists?(path) && !File.size?(path)
    raise "Failed to write emoji: #{path}"
  end
end

def code_to_emoji(code)
  code
    .split("_")
    .map { |e| e.to_i(16) }
    .pack "U*"
end

def codepoints_to_code(codepoints, fitzpatrick_scale)
  codepoints = codepoints
                .map { |c| c.to_s(16).rjust(4, "0") }
                .join("_")
                .downcase

  if !fitzpatrick_scale
    codepoints.gsub!(/_#{VARIATION_SELECTOR}$/, "")
  end

  codepoints
end

def inject_scale_to_codes(codes, scale)
  # some emojis were male only and got a male and woman variant while
  # keeping the original, for those the rule is different (eg: golfing_woman)
  if codes[1] == VARIATION_SELECTOR
    codes[1] = scale
  else
    codes.insert(1, scale)
  end
  codes.join("_")
end

def generate_emoji_scales(name, code)
  scaled_keywords = {}

  FITZPATRICK_SCALE.each.with_index do |scale, index|
    codes = code.split("_")
    code_with_scale = inject_scale_to_codes(codes, scale)
    scaled_keywords[code_with_scale] ||= {
      :name => "#{name}/#{index + 2}",
      :fitzpatrick_scale => false
    }
  end

  scaled_keywords
end

def check_pngout
  return if ENV['EMOJI_TEST']

  unless command?("pngout")
    raise "Please make sure `pngout` is installed and in your PATH"
  end
end

def command?(command)
  system("which \"#{command}\" > /dev/null 2>&1")
end

def confirm_overwrite(path)
  return if ENV['EMOJI_TEST']

  STDOUT.puts("[!] You are about to overwrite #{path}, are you sure? [CTRL+c] to cancel, [ENTER] to continue")
  STDIN.gets.chomp
end


class TestEmojiUpdate < MiniTest::Test
  def self.run_and_summarize
    puts "Runnings tests..."
    reporter = Minitest::SummaryReporter.new
    TestEmojiUpdate.run(reporter)
    puts reporter.to_s
  end

  def image_path(style, name)
    File.join("public", "images", "emoji", style, "#{name}.png")
  end

  def test_code_to_emoji
    assert_equal "😎", code_to_emoji("1f60e")
  end

  def test_codepoints_to_code
    assert_equal "1f6b5_200d_2640", codepoints_to_code([128693, 8205, 9792, 65039], false)
  end

  def test_codepoints_to_code_with_scale
    assert_equal "1f6b5_200d_2640_fe0f", codepoints_to_code([128693, 8205, 9792, 65039], true)
  end

  def test_groups_js_es6_creation
    assert File.exists?(EMOJI_GROUPS_PATH)
    assert File.size?(EMOJI_GROUPS_PATH)
  end

  def test_db_json_creation
    assert File.exists?(EMOJI_DB_PATH)
    assert File.size?(EMOJI_DB_PATH)
  end

  def test_alias_creation
    original_image = image_path("apple", "right_anger_bubble")
    alias_image = image_path("apple", "anger_right")

    assert_equal File.size(original_image), File.size(alias_image)
  end

  def test_cell_index_patch
    original_image = image_path("apple", "snowboarder")
    alias_image = image_path("twitter", "snowboarder")

    assert_equal File.size(original_image), File.size(alias_image)
  end

  def test_scales
    original_image = image_path("apple", "blonde_woman")
    assert File.exists?(original_image)
    assert File.size?(original_image)

    (2..6).each do |scale|
      image = image_path("apple", "blonde_woman/#{scale}")
      assert File.exists?(image)
      assert File.size?(image)
    end
  end

  def test_generate_emoji_scales
    actual = generate_emoji_scales("sleeping_bed", "1f6cc")
    expected = {
      "1f6cc_1f3fb" => { :name => "sleeping_bed/2", :fitzpatrick_scale => false },
      "1f6cc_1f3fc" => { :name => "sleeping_bed/3", :fitzpatrick_scale => false },
      "1f6cc_1f3fd" => { :name => "sleeping_bed/4", :fitzpatrick_scale => false },
      "1f6cc_1f3fe" => { :name => "sleeping_bed/5", :fitzpatrick_scale => false },
      "1f6cc_1f3ff" => { :name => "sleeping_bed/6", :fitzpatrick_scale => false }
    }

    assert_equal expected, actual
  end
end
