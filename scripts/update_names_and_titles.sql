BEGIN;

-- temporary lookup tables
CREATE TEMP TABLE tmp_first_names (id SERIAL PRIMARY KEY, name TEXT);
CREATE TEMP TABLE tmp_last_names  (id SERIAL PRIMARY KEY, name TEXT);
CREATE TEMP TABLE tmp_adjectives  (id SERIAL PRIMARY KEY, word TEXT);
CREATE TEMP TABLE tmp_nouns       (id SERIAL PRIMARY KEY, word TEXT);


-- first names  (~480 entries: 240 female + 240 male)
INSERT INTO tmp_first_names (name) VALUES
  -- female
  ('Emma'),('Olivia'),('Ava'),('Isabella'),('Sophia'),('Charlotte'),('Mia'),('Amelia'),('Harper'),('Evelyn'),
  ('Abigail'),('Emily'),('Elizabeth'),('Mila'),('Ella'),('Avery'),('Sofia'),('Camila'),('Aria'),('Scarlett'),
  ('Victoria'),('Madison'),('Luna'),('Grace'),('Chloe'),('Penelope'),('Layla'),('Riley'),('Zoey'),('Nora'),
  ('Lily'),('Eleanor'),('Hannah'),('Lillian'),('Addison'),('Aubrey'),('Ellie'),('Stella'),('Natalie'),('Zoe'),
  ('Leah'),('Hazel'),('Violet'),('Aurora'),('Savannah'),('Audrey'),('Brooklyn'),('Bella'),('Claire'),('Skylar'),
  ('Lucy'),('Paisley'),('Everly'),('Anna'),('Caroline'),('Nova'),('Genesis'),('Emilia'),('Kennedy'),('Samantha'),
  ('Maya'),('Willow'),('Kinsley'),('Naomi'),('Aaliyah'),('Elena'),('Sarah'),('Ariana'),('Allison'),('Gabriella'),
  ('Alice'),('Madelyn'),('Cora'),('Ruby'),('Eva'),('Serenity'),('Autumn'),('Adeline'),('Hailey'),('Gianna'),
  ('Valentina'),('Isla'),('Eliana'),('Quinn'),('Ivy'),('Sadie'),('Piper'),('Lydia'),('Alexa'),('Josephine'),
  ('Emery'),('Julia'),('Delilah'),('Arianna'),('Vivian'),('Kaylee'),('Sophie'),('Brielle'),('Madeline'),('Peyton'),
  ('Rylee'),('Clara'),('Hadley'),('Melanie'),('Mackenzie'),('Reagan'),('Liliana'),('Jade'),('Katherine'),('Isabelle'),
  ('Natalia'),('Maria'),('Athena'),('Alyssa'),('Makayla'),('Daisy'),('Elise'),('Annabelle'),('Nadia'),('Brianna'),
  ('Laila'),('Faith'),('Kylie'),('Lauren'),('Alexandra'),('Jasmine'),('Kayla'),('Molly'),('Paige'),('Presley'),
  ('Cecelia'),('Remi'),('Emerson'),('Harlow'),('Daniela'),('Sloane'),('Summer'),('Elaina'),('Esme'),('Fiona'),
  ('Sienna'),('Vera'),('Zara'),('Arabella'),('Anastasia'),('Mariah'),('Camille'),('Bianca'),('Amara'),('Adriana'),
  ('Sara'),('Juliana'),('Sasha'),('Tessa'),('Megan'),('Aliyah'),('Amy'),('Jocelyn'),('Destiny'),('Vivienne'),
  ('Rosalie'),('Genevieve'),('Margot'),('Miriam'),('Selena'),('Carmen'),('Diana'),('Monica'),('Nicole'),('Rachel'),
  ('Vanessa'),('Melissa'),('Amanda'),('Jessica'),('Ashley'),('Crystal'),('Danielle'),('Jennifer'),('Shannon'),('Stephanie'),
  ('Whitney'),('Dawn'),('Heather'),('Holly'),('Kimberly'),('Michelle'),('Patricia'),('Rebecca'),('Sandra'),('Susan'),
  ('Teresa'),('Angela'),('Dorothy'),('Frances'),('Gloria'),('Helen'),('Jane'),('Karen'),('Laura'),('Linda'),
  ('Margaret'),('Nancy'),('Pamela'),('Paula'),('Ruth'),('Sharon'),('Shirley'),('Virginia'),('Wanda'),('Barbara'),
  ('Betty'),('Carol'),('Carolyn'),('Catherine'),('Cheryl'),('Christine'),('Cynthia'),('Diane'),('Donna'),('Janet'),
  ('Jean'),('Joyce'),('Judith'),('Julie'),('Kathleen'),('Kelly'),('Lisa'),('Lori'),('Martha'),('Rose'),
  ('Beatrice'),('Cecilia'),('Claudia'),('Constance'),('Dolores'),('Edna'),('Elaine'),('Esther'),('Florence'),('Gladys'),
  -- male
  ('Liam'),('Noah'),('Oliver'),('Elijah'),('James'),('William'),('Benjamin'),('Lucas'),('Henry'),('Alexander'),
  ('Mason'),('Ethan'),('Daniel'),('Jacob'),('Logan'),('Jackson'),('Sebastian'),('Jack'),('Aiden'),('Owen'),
  ('Samuel'),('Joseph'),('Wyatt'),('John'),('David'),('Leo'),('Luke'),('Julian'),('Hudson'),('Grayson'),
  ('Matthew'),('Mateo'),('Levi'),('Asher'),('Carter'),('Dylan'),('Jayden'),('Gabriel'),('Isaac'),('Anthony'),
  ('Lincoln'),('Ezra'),('Thomas'),('Maverick'),('Elias'),('Josiah'),('Charles'),('Caleb'),('Christopher'),('Isaiah'),
  ('Andrew'),('Eli'),('Joshua'),('Nathan'),('Landon'),('Hunter'),('Jonathan'),('Christian'),('Jaxon'),('Nolan'),
  ('Ezekiel'),('Cameron'),('Connor'),('Jeremiah'),('Adrian'),('Evan'),('Theodore'),('Jordan'),('Jose'),('Aaron'),
  ('Ian'),('Brooks'),('Carson'),('Jace'),('Everett'),('Nicholas'),('Dominic'),('Xavier'),('Bennett'),('Greyson'),
  ('Miles'),('Kai'),('Sawyer'),('Jason'),('Axel'),('Cooper'),('Easton'),('Rowan'),('Colton'),('Roman'),
  ('Leonardo'),('Zion'),('Dawson'),('Bryson'),('Damian'),('Jameson'),('Harrison'),('Xander'),('Emmett'),('Leon'),
  ('Ryker'),('Silas'),('Brayden'),('Gael'),('Eric'),('Austin'),('Chase'),('Cole'),('Caden'),('Blake'),
  ('Brody'),('Brandon'),('Brian'),('Bryan'),('Bruce'),('Carl'),('Chad'),('Clayton'),('Clifford'),('Cody'),
  ('Colin'),('Craig'),('Curtis'),('Dale'),('Damon'),('Darren'),('Derek'),('Desmond'),('Devon'),('Douglas'),
  ('Dwayne'),('Earl'),('Eddie'),('Edgar'),('Edward'),('Edwin'),('Elliot'),('Erik'),('Floyd'),('Francis'),
  ('Frank'),('Frederick'),('Gary'),('Gene'),('George'),('Gerald'),('Gilbert'),('Glen'),('Gordon'),('Grant'),
  ('Gregory'),('Harold'),('Harvey'),('Howard'),('Hugh'),('Jesse'),('Joel'),('Jorge'),('Justin'),('Keith'),
  ('Kenneth'),('Kevin'),('Kirk'),('Kyle'),('Lance'),('Larry'),('Lawrence'),('Leonard'),('Leroy'),('Lewis'),
  ('Louis'),('Malcolm'),('Marcus'),('Mark'),('Martin'),('Maurice'),('Michael'),('Miguel'),('Mitchell'),('Neil'),
  ('Nelson'),('Patrick'),('Paul'),('Peter'),('Philip'),('Randy'),('Raymond'),('Richard'),('Robert'),('Roger'),
  ('Ronald'),('Ross'),('Ryan'),('Scott'),('Sean'),('Spencer'),('Stanley'),('Stephen'),('Steve'),('Timothy'),
  ('Todd'),('Travis'),('Trevor'),('Troy'),('Tyler'),('Victor'),('Vincent'),('Walter'),('Wayne'),('Wesley'),
  ('Zachary'),('Adam'),('Alan'),('Albert'),('Alfred'),('Allen'),('Alvin'),('Andre'),('Antonio'),('Arthur'),
  ('Barry'),('Bernard'),('Billy'),('Bobby'),('Brad'),('Bradley'),('Brett'),('Brock'),('Byron'),('Calvin'),
  ('Cedric'),('Chester'),('Clarence'),('Claude'),('Clinton'),('Corey'),('Dennis'),('Donnie'),('Duane'),('Duncan')
;

-- last names  (~400 entries)
INSERT INTO tmp_last_names (name) VALUES
  ('Smith'),('Johnson'),('Williams'),('Brown'),('Jones'),('Garcia'),('Miller'),('Davis'),('Rodriguez'),('Martinez'),
  ('Hernandez'),('Lopez'),('Gonzalez'),('Wilson'),('Anderson'),('Thomas'),('Taylor'),('Moore'),('Jackson'),('Martin'),
  ('Lee'),('Perez'),('Thompson'),('White'),('Harris'),('Sanchez'),('Clark'),('Ramirez'),('Lewis'),('Robinson'),
  ('Walker'),('Young'),('Allen'),('King'),('Wright'),('Scott'),('Torres'),('Nguyen'),('Hill'),('Flores'),
  ('Green'),('Adams'),('Nelson'),('Baker'),('Hall'),('Rivera'),('Campbell'),('Mitchell'),('Carter'),('Roberts'),
  ('Gomez'),('Phillips'),('Evans'),('Turner'),('Diaz'),('Parker'),('Cruz'),('Edwards'),('Collins'),('Reyes'),
  ('Stewart'),('Morris'),('Morales'),('Murphy'),('Cook'),('Rogers'),('Gutierrez'),('Ortiz'),('Morgan'),('Cooper'),
  ('Peterson'),('Bailey'),('Reed'),('Kelly'),('Howard'),('Ramos'),('Kim'),('Cox'),('Ward'),('Richardson'),
  ('Watson'),('Brooks'),('Chavez'),('Wood'),('James'),('Bennett'),('Gray'),('Mendoza'),('Ruiz'),('Hughes'),
  ('Price'),('Alvarez'),('Castillo'),('Sanders'),('Patel'),('Myers'),('Long'),('Ross'),('Foster'),('Jimenez'),
  ('Powell'),('Jenkins'),('Perry'),('Russell'),('Sullivan'),('Bell'),('Coleman'),('Butler'),('Henderson'),('Barnes'),
  ('Gonzales'),('Fisher'),('Vasquez'),('Simmons'),('Romero'),('Jordan'),('Patterson'),('Alexander'),('Hamilton'),('Graham'),
  ('Reynolds'),('Griffin'),('Wallace'),('Moreno'),('West'),('Cole'),('Hayes'),('Bryant'),('Herrera'),('Gibson'),
  ('Ellis'),('Tran'),('Medina'),('Aguilar'),('Stevens'),('Murray'),('Ford'),('Castro'),('Marshall'),('Owens'),
  ('Harrison'),('Fernandez'),('McDonald'),('Walsh'),('Freeman'),('Webb'),('Bradley'),('Burke'),('Morrison'),('Ryan'),
  ('Mendez'),('Warren'),('Dixon'),('Rice'),('Schmidt'),('Hunt'),('Tucker'),('Carroll'),('Armstrong'),('Douglas'),
  ('Fowler'),('Snyder'),('Cunningham'),('Wade'),('Salazar'),('Hicks'),('Garrett'),('Hudson'),('Burgess'),('Banks'),
  ('Horton'),('Meyer'),('Hawkins'),('Mills'),('Olson'),('Pierce'),('Bishop'),('Ferguson'),('Dunn'),('Gregory'),
  ('Shaw'),('Barker'),('Swanson'),('Little'),('Hammond'),('Lynch'),('Larson'),('Garza'),('Terry'),('Woods'),
  ('Spencer'),('Wagner'),('Carr'),('Holt'),('Maldonado'),('Singleton'),('Chambers'),('Newman'),('Rose'),('Davidson'),
  ('Hansen'),('Fischer'),('Weber'),('Schulz'),('Klein'),('Wolf'),('Schroeder'),('Neumann'),('Braun'),('Hoffmann'),
  ('Hartmann'),('Ludwig'),('Becker'),('Krause'),('Zimmermann'),('Kramer'),('Schneider'),('Vogel'),('Bauer'),('Werner'),
  ('Peters'),('Lang'),('Kohler'),('Blackwood'),('Whitfield'),('Ashford'),('Thornton'),('Caldwell'),('Crawford'),('Cummings'),
  ('Eaton'),('Fleming'),('Glover'),('Graves'),('Hampton'),('Harrington'),('Hart'),('Harvey'),('Hayden'),('Higgins'),
  ('Hodge'),('Holland'),('Hopkins'),('Horn'),('Howe'),('Howell'),('Huffman'),('Ingram'),('Jensen'),('Johnston'),
  ('Kemp'),('Kennedy'),('Kent'),('Lambert'),('Lawson'),('Lester'),('Lowe'),('Lucas'),('Marsh'),('Mason'),
  ('Matthews'),('Mccoy'),('Mckenzie'),('Mckinney'),('Miles'),('Monroe'),('Montgomery'),('Norton'),('Norris'),('Oliver'),
  ('Page'),('Palmer'),('Parks'),('Payne'),('Potter'),('Ramsey'),('Randolph'),('Reeves'),('Rhodes'),('Riley'),
  ('Robertson'),('Rojas'),('Rowe'),('Saunders'),('Sharp'),('Sherman'),('Simpson'),('Skinner'),('Solomon'),('Stanton'),
  ('Sutton'),('Sweeney'),('Todd'),('Underwood'),('Vargas'),('Vega'),('Vincent'),('Walton'),('Warner'),('Washington'),
  ('Watkins'),('Watts'),('Weaver'),('Welch'),('Wells'),('Wheeler'),('Williamson'),('Willis'),('Winters'),('Wise'),
  ('Fitzgerald'),('Gallagher'),('Hennessey'),('Kavanagh'),('Malone'),('Nolan'),('Rafferty'),('Sheridan'),('Tully'),('Byrne'),
  ('Oconnor'),('Mcdonnell'),('Flanagan'),('Donovan'),('Callahan'),('Brennan'),('Mccarthy'),('Foley'),('Quinn'),('Duffy'),
  ('Delgado'),('Navarro'),('Soto'),
  ('Nakamura'),('Yamamoto'),('Tanaka'),('Watanabe'),('Ito'),('Suzuki'),('Sato'),('Kobayashi'),('Kato'),('Abe'),
  ('Chen'),('Wang'),('Li'),('Zhang'),('Liu'),('Yang'),('Huang'),('Wu'),('Zhou'),('Xu')
;

-- adjectives  (~650 entries)
INSERT INTO tmp_adjectives (word) VALUES
  ('abandoned'),('absent'),('acoustic'),('aerial'),('ageless'),('alien'),('alive'),('amber'),('ancient'),('angular'),
  ('arctic'),('ardent'),('arid'),('ashen'),('astral'),('atomic'),('audacious'),('azure'),('bare'),('barren'),
  ('battered'),('blazing'),('bleak'),('blind'),('blissful'),('bold'),('booming'),('boundless'),('brave'),('breathless'),
  ('bright'),('broken'),('brooding'),('burning'),('calm'),('carved'),('celestial'),('chaotic'),('charged'),('chrome'),
  ('clandestine'),('classic'),('clear'),('cobalt'),('cold'),('colossal'),('cosmic'),('crashing'),('crimson'),('crumbling'),
  ('crystal'),('cursed'),('dark'),('daring'),('dazzling'),('dead'),('deadly'),('deep'),('defiant'),('desolate'),
  ('desperate'),('digital'),('dim'),('distant'),('divine'),('dormant'),('dramatic'),('dreaming'),('drifting'),('drowning'),
  ('dusky'),('dynamic'),('dying'),('earthen'),('ebony'),('echoing'),('electric'),('elegant'),('emerald'),('empty'),
  ('enchanted'),('endless'),('enduring'),('enigmatic'),('ephemeral'),('eternal'),('ethereal'),('euphoric'),('faded'),('fallen'),
  ('fast'),('fearless'),('fervent'),('fierce'),('final'),('finite'),('flaming'),('fleeting'),('flowing'),('fluid'),
  ('forgotten'),('fragile'),('frantic'),('free'),('frozen'),('furious'),('gentle'),('ghostly'),('gilded'),('glacial'),
  ('gleaming'),('glimmering'),('glorious'),('gloomy'),('glowing'),('golden'),('graceful'),('grand'),('grave'),('gritty'),
  ('hallowed'),('harsh'),('haunted'),('heavy'),('hidden'),('high'),('hollow'),('holy'),('howling'),('humble'),
  ('hypnotic'),('icy'),('immortal'),('incandescent'),('infinite'),('inner'),('iridescent'),('jagged'),('jubilant'),('keen'),
  ('kinetic'),('legendary'),('limitless'),('liquid'),('lone'),('lost'),('loud'),('low'),('loyal'),('luminous'),
  ('lunar'),('lurking'),('magnetic'),('majestic'),('massive'),('melancholic'),('merciful'),('midnight'),('mighty'),('misty'),
  ('modern'),('molten'),('moonlit'),('mortal'),('mournful'),('murky'),('muted'),('mystic'),('naked'),('narrow'),
  ('neon'),('noble'),('nocturnal'),('nomadic'),('numb'),('obsidian'),('oceanic'),('old'),('ominous'),('opaque'),
  ('original'),('pale'),('patient'),('peaceful'),('phantom'),('powerful'),('primal'),('proud'),('pure'),('quiet'),
  ('radiant'),('raging'),('raw'),('reckless'),('relentless'),('remote'),('resonant'),('restless'),('rising'),('roaming'),
  ('rough'),('royal'),('rugged'),('ruined'),('sacred'),('scattered'),('scorched'),('serene'),('shattered'),('sharp'),
  ('shining'),('silent'),('slow'),('smoky'),('soft'),('solar'),('solemn'),('somber'),('sonic'),('spectral'),
  ('spiritual'),('starlit'),('static'),('still'),('stormy'),('strange'),('strong'),('sublime'),('sunken'),('swift'),
  ('tattered'),('tender'),('timeless'),('tormented'),('towering'),('transcendent'),('translucent'),('trembling'),('twilight'),('twisted'),
  ('unbroken'),('uncharted'),('undying'),('unearthly'),('unforgiven'),('unknown'),('untamed'),('vast'),('velvet'),('vibrant'),
  ('violent'),('violet'),('vivid'),('volcanic'),('wandering'),('weathered'),('weary'),('weeping'),('whispering'),('wicked'),
  ('wild'),('windswept'),('worn'),('woven'),('wretched'),('young'),('zealous'),('abyssal'),('acidic'),('agile'),
  ('altered'),('anomalous'),('archaic'),('atmospheric'),('blinding'),('brittle'),('ceaseless'),('chosen'),('cloaked'),('concrete'),
  ('corrupted'),('covert'),('daunting'),('deathless'),('decaying'),('devout'),('dominant'),('elusive'),('emergent'),('exiled'),
  ('explosive'),('fearsome'),('fractured'),('galactic'),('ghostlike'),('glassy'),('grinding'),('hazy'),('heated'),('heroic'),
  ('indigo'),('infernal'),('lawless'),('lofty'),('mechanical'),('meditative'),('mercurial'),('mirrored'),('mythic'),('nuclear'),
  ('numbing'),('obsessive'),('orbital'),('painted'),('pulsing'),('ravenous'),('reformed'),('renegade'),('ruthless'),('savage'),
  ('shadowed'),('skeletal'),('soaring'),('steady'),('stellar'),('sunlit'),('swirling'),('tactical'),('thermal'),('thrashing'),
  ('tranquil'),('unstable'),('vanishing'),('vigilant'),('waning'),('warped'),('wavering'),('accelerating'),('alluring'),('aloof'),
  ('ambiguous'),('antique'),('arcane'),('asymmetric'),('binary'),('blurred'),('cascading'),('catastrophic'),('charged'),('ciphered'),
  ('collapsing'),('complex'),('consuming'),('converging'),('cyclical'),('decadent'),('defeated'),('deliberate'),('dense'),('determined'),
  ('deviant'),('diffuse'),('discordant'),('dispersed'),('dissolving'),('distorted'),('divergent'),('eclipsed'),('elastic'),('elemental'),
  ('emotive'),('enchanting'),('evanescent'),('evolving'),('expansive'),('ferocious'),('feverish'),('flickering'),('folded'),('forged'),
  ('fragmented'),('gravitational'),('guiding'),('halcyon'),('harmonic'),('hurtling'),('illuminated'),('impassioned'),('impending'),('incendiary'),
  ('incisive'),('infernal'),('inflamed'),('intricate'),('kaleidoscopic'),('labyrinthine'),('lashing'),('layered'),('leaping'),('lingering'),
  ('looming'),('marbled'),('measured'),('migratory'),('monolithic'),('moody'),('oblique'),('obscured'),('oscillating'),('otherworldly'),
  ('parting'),('penetrating'),('piercing'),('pivotal'),('polar'),('predatory'),('primordial'),('propagating'),('reverberant'),('rhythmic'),
  ('sapphire'),('searing'),('seething'),('shimmering'),('sinuous'),('slumbering'),('smoking'),('sovereign'),('splitting'),('spreading'),
  ('subterranean'),('surging'),('suspended'),('sweeping'),('throbbing'),('tidal'),('toppled'),('turbulent'),('unbound'),('undulating'),
  ('unfolding'),('unquiet'),('veiled'),('venomous'),('volatile'),('wailing'),('worn'),('yearning'),('zealous'),('zenith'),
  ('abrupt'),('afire'),('alight'),('angular'),('burnished'),('charged'),('clashing'),('cloaked'),('compound'),('contested'),
  ('cracked'),('crestfallen'),('daunted'),('defiled'),('derelict'),('desiccated'),('disfigured'),('displaced'),('dissolute'),('dormant'),
  ('dulled'),('encircled'),('encroaching'),('eroding'),('exalted'),('exquisite'),('extinguished'),('exultant'),('fermented'),('fevered'),
  ('ghosted'),('gilded'),('glistening'),('hallowed'),('impure'),('inclined'),('inert'),('inviolate'),('lamentable'),('languishing'),
  ('lecherous'),('lethargic'),('lightless'),('listless'),('long-lost'),('lurid'),('maddened'),('manifold'),('marred'),('melting')
;

-- nouns  (~650 entries)
INSERT INTO tmp_nouns (word) VALUES
  -- nature / elements
  ('river'),('mountain'),('storm'),('fire'),('night'),('sky'),('ocean'),('forest'),('desert'),('valley'),
  ('sunrise'),('sunset'),('moon'),('star'),('thunder'),('lightning'),('rain'),('wind'),('wave'),('tide'),
  ('flame'),('spark'),('ember'),('ash'),('stone'),('steel'),('iron'),('gold'),('silver'),('crystal'),
  ('diamond'),('pearl'),('rose'),('thorn'),('glacier'),('volcano'),('canyon'),('plateau'),('tundra'),('prairie'),
  ('lagoon'),('reef'),('delta'),('fjord'),('crater'),('geyser'),('aurora'),('nebula'),('comet'),('meteor'),
  ('asteroid'),('constellation'),('galaxy'),('supernova'),('cosmos'),('universe'),('cliff'),('shore'),('sand'),('dust'),
  ('smoke'),('fog'),('mist'),('cloud'),('peak'),('summit'),('abyss'),('chasm'),('gorge'),('ravine'),
  ('cavern'),('tidal'),('undertow'),('eddy'),('whirlpool'),('maelstrom'),('tornado'),('avalanche'),('tsunami'),('eruption'),
  ('torrent'),('deluge'),('inferno'),('wildfire'),('vapor'),('haze'),('blizzard'),('frost'),('flake'),('droplet'),
  ('ripple'),('splash'),('surge'),('swell'),('current'),('depth'),('horizon'),('frontier'),('wilderness'),('tundra'),
  -- music / sound
  ('melody'),('harmony'),('rhythm'),('beat'),('pulse'),('chord'),('note'),('tone'),('pitch'),('timbre'),
  ('resonance'),('frequency'),('wavelength'),('amplitude'),('oscillation'),('symphony'),('concerto'),('nocturne'),('prelude'),('interlude'),
  ('coda'),('overture'),('finale'),('movement'),('fugue'),('canon'),('waltz'),('etude'),('serenade'),('rhapsody'),
  ('sonata'),('aria'),('chorus'),('verse'),('bridge'),('hook'),('lyric'),('anthem'),('ballad'),('opus'),
  ('requiem'),('elegy'),('hymn'),('saga'),('epic'),('tempo'),('cadence'),('measure'),('string'),('drum'),
  ('horn'),('bell'),('signal'),('broadcast'),('transmission'),('echo'),('silence'),('whisper'),('scream'),('sigh'),
  -- emotion / abstract
  ('dream'),('heart'),('soul'),('spirit'),('shadow'),('light'),('illusion'),('truth'),('lie'),('promise'),
  ('oath'),('vow'),('bond'),('chain'),('memory'),('age'),('era'),('eternity'),('moment'),('instant'),
  ('legend'),('myth'),('tale'),('story'),('chapter'),('word'),('name'),('mark'),('sign'),('omen'),
  ('vision'),('nightmare'),('fantasy'),('reality'),('deception'),('chaos'),('order'),('balance'),('harmony'),('discord'),
  ('vengeance'),('wrath'),('fury'),('rage'),('sorrow'),('grief'),('joy'),('hope'),('despair'),('faith'),
  ('doubt'),('glory'),('shame'),('valor'),('honor'),('courage'),('grace'),('mercy'),('justice'),('prophecy'),
  ('destiny'),('fate'),('chance'),('truth'),('void'),('infinity'),('absence'),('presence'),('essence'),('force'),
  -- power / energy
  ('gravity'),('momentum'),('velocity'),('trajectory'),('orbit'),('revolution'),('evolution'),('mutation'),('transformation'),('transcendence'),
  ('blast'),('roar'),('rumble'),('crash'),('howl'),('cry'),('call'),('flash'),('burst'),('flare'),
  ('fractal'),('spiral'),('helix'),('prism'),('spectrum'),('corona'),('halo'),('nimbus'),('eclipse'),('singularity'),
  ('portal'),('vortex'),('dimension'),('matrix'),('grid'),('node'),('protocol'),('algorithm'),('code'),('data'),
  ('circuit'),('network'),('pulse'),('heartbeat'),('lifeblood'),('nerve'),('vein'),('artery'),('sinew'),('marrow'),
  -- creatures / animals
  ('wolf'),('eagle'),('falcon'),('raven'),('phoenix'),('dragon'),('serpent'),('tiger'),('lion'),('bear'),
  ('hawk'),('crow'),('owl'),('fox'),('deer'),('panther'),('cobra'),('condor'),('albatross'),('whale'),
  ('dolphin'),('shark'),('kraken'),('leviathan'),('phantom'),('specter'),('wraith'),('shade'),('revenant'),('ghost'),
  -- structures / symbols
  ('fortress'),('citadel'),('tower'),('obelisk'),('monument'),('temple'),('cathedral'),('shrine'),('altar'),('throne'),
  ('kingdom'),('empire'),('crown'),('blade'),('arrow'),('sword'),('shield'),('dagger'),('lance'),('torch'),
  ('lantern'),('candle'),('beacon'),('lighthouse'),('compass'),('anchor'),('sail'),('rudder'),('helm'),('sextant'),
  ('mirror'),('lens'),('kaleidoscope'),('talisman'),('amulet'),('relic'),('artifact'),('cipher'),('riddle'),('enigma'),
  ('threshold'),('crossroads'),('junction'),('passage'),('corridor'),('tunnel'),('gateway'),('veil'),('membrane'),('boundary'),
  ('skyline'),('pinnacle'),('spire'),('arch'),('dome'),('vault'),('nave'),('cloister'),('ridge'),('crest'),
  -- time / cycle
  ('dawn'),('dusk'),('twilight'),('midnight'),('noon'),('solstice'),('equinox'),('epoch'),('century'),('millennium'),
  ('zenith'),('nadir'),('apex'),('cycle'),('axis'),('pole'),('blink'),('flash'),('era'),('age'),
  -- additional vivid nouns
  ('tide'),('undertow'),('cascade'),('torrent'),('vortex'),('drift'),('current'),('eddy'),('rush'),('surge'),
  ('silence'),('echo'),('resonance'),('signal'),('frequency'),('chord'),('arc'),('path'),('road'),('bridge'),
  ('voyage'),('quest'),('journey'),('passage'),('drift'),('wandering'),('pilgrimage'),('odyssey'),('sojourn'),('exile'),
  ('testament'),('scripture'),('oracle'),('sage'),('knight'),('warrior'),('sentinel'),('guardian'),('nomad'),('exile'),
  ('ember'),('cinder'),('ash'),('smoke'),('torch'),('forge'),('anvil'),('hammer'),('iron'),('steel'),
  ('crater'),('rift'),('scar'),('fracture'),('wound'),('mark'),('trace'),('imprint'),('echo'),('remnant'),
  ('fragment'),('shard'),('splinter'),('spark'),('flicker'),('gleam'),('glimmer'),('shimmer'),('glow'),('blaze'),
  ('tempest'),('squall'),('gale'),('hurricane'),('typhoon'),('cyclone'),('deluge'),('flood'),('drought'),('famine'),
  ('tide'),('wave'),('ripple'),('splash'),('foam'),('mist'),('dew'),('frost'),('ice'),('snow')
;

-- 1. users.full_name + username
--    full_name → "First Last"
--    username  → "first_last_NNN"  (NNN is a unique 3-digit suffix 100–999)
--
--    CTEs containing random() are NOT guaranteed to be materialized by the
--    planner, so random() can be re-evaluated and produce different fn_id/ln_id
--    values for the window function vs. the outer UPDATE — causing collisions.
--    Solution: write assignments into a real temp table first so random() runs
--    exactly once per user, then apply the row_number suffix on that stable data.
--
--    Suffix uniqueness: gcd(137, 900) = 1, so the sequence
--    (rn-1)*137 mod 900 visits all 900 values before repeating → every user
--    in the same name group gets a distinct, non-sequential-looking number.
CREATE TEMP TABLE tmp_user_assignments AS
SELECT
  id,
  (1 + floor(random() * (SELECT count(*) FROM tmp_first_names)))::int AS fn_id,
  (1 + floor(random() * (SELECT count(*) FROM tmp_last_names)))::int  AS ln_id
FROM users;

UPDATE users u
SET
  full_name = initcap(fn.name) || ' ' || initcap(ln.name),
  username  = lower(fn.name) || '_' || lower(ln.name) || '_' ||
              (100 + ((sub.rn - 1) * 137 % 900))::text
FROM (
  SELECT id, fn_id, ln_id,
    row_number() OVER (PARTITION BY fn_id, ln_id ORDER BY id) AS rn
  FROM tmp_user_assignments
) sub
JOIN tmp_first_names fn ON fn.id = sub.fn_id
JOIN tmp_last_names  ln ON ln.id = sub.ln_id
WHERE u.id = sub.id;

DROP TABLE tmp_user_assignments;

-- 2. artists.display_name - 80% "<First> <Last>", 20% single Noun 
UPDATE artists a
SET display_name = CASE
  WHEN src.single_word THEN initcap(n.word)
  ELSE initcap(fn.name) || ' ' || initcap(ln.name)
END
FROM (
  SELECT id,
    (1 + floor(random() * (SELECT count(*) FROM tmp_first_names)))::int AS fn_id,
    (1 + floor(random() * (SELECT count(*) FROM tmp_last_names)))::int  AS ln_id,
    (1 + floor(random() * (SELECT count(*) FROM tmp_nouns)))::int       AS noun_id,
    random() < 0.2                                                       AS single_word
  FROM artists
) src
JOIN tmp_first_names fn ON fn.id = src.fn_id
JOIN tmp_last_names  ln ON ln.id = src.ln_id
JOIN tmp_nouns        n ON n.id  = src.noun_id
WHERE a.id = src.id;


-- 3. labels.name - format: "<Adjective> <Noun> Records"
UPDATE labels l
SET name = initcap(adj.word) || ' ' || initcap(n.word) || ' Records'
FROM (
  SELECT id,
    (1 + floor(random() * (SELECT count(*) FROM tmp_adjectives)))::int AS adj_id,
    (1 + floor(random() * (SELECT count(*) FROM tmp_nouns)))::int      AS noun_id
  FROM labels
) src
JOIN tmp_adjectives adj ON adj.id = src.adj_id
JOIN tmp_nouns        n ON n.id   = src.noun_id
WHERE l.id = src.id;

-- 4. albums.title  — 80% "<Adjective> <Noun>", 20% single Noun
UPDATE albums a
SET title = CASE
  WHEN src.single_word THEN initcap(n.word)
  ELSE initcap(adj.word) || ' ' || initcap(n.word)
END
FROM (
  SELECT id,
    (1 + floor(random() * (SELECT count(*) FROM tmp_adjectives)))::int AS adj_id,
    (1 + floor(random() * (SELECT count(*) FROM tmp_nouns)))::int      AS noun_id,
    random() < 0.2                                                      AS single_word
  FROM albums
) src
JOIN tmp_adjectives adj ON adj.id = src.adj_id
JOIN tmp_nouns        n ON n.id   = src.noun_id
WHERE a.id = src.id;


-- 5. songs.title  — 80% "<Adjective> <Noun>", 20% single Noun
UPDATE songs s
SET title = CASE
  WHEN src.single_word THEN initcap(n.word)
  ELSE initcap(adj.word) || ' ' || initcap(n.word)
END
FROM (
  SELECT id,
    (1 + floor(random() * (SELECT count(*) FROM tmp_adjectives)))::int AS adj_id,
    (1 + floor(random() * (SELECT count(*) FROM tmp_nouns)))::int      AS noun_id,
    random() < 0.2                                                      AS single_word
  FROM songs
) src
JOIN tmp_adjectives adj ON adj.id = src.adj_id
JOIN tmp_nouns        n ON n.id   = src.noun_id
WHERE s.id = src.id;

-- 6. playlists.playlist_name  — 80% "<Adjective> <Noun> Mix", 20% "<Noun> Mix"
UPDATE playlists p
SET playlist_name = CASE
  WHEN src.single_word THEN initcap(n.word) || ' Mix'
  ELSE initcap(adj.word) || ' ' || initcap(n.word) || ' Mix'
END
FROM (
  SELECT id,
    (1 + floor(random() * (SELECT count(*) FROM tmp_adjectives)))::int AS adj_id,
    (1 + floor(random() * (SELECT count(*) FROM tmp_nouns)))::int      AS noun_id,
    random() < 0.2                                                      AS single_word
  FROM playlists
) src
JOIN tmp_adjectives adj ON adj.id = src.adj_id
JOIN tmp_nouns        n ON n.id   = src.noun_id
WHERE p.id = src.id;

COMMIT;
