// ─────────────────────────────────────────────────────────────────────────────
// Mirrored from the RoamSwitch app source tree — RoamSwitch 1.10.1 (build 119).
// The RoamSwitch app is the source of truth. Do NOT edit this copy: changes here
// are not compiled into the shipping app and are overwritten on the next sync.
// Regenerate with ./scripts/sync-from-roamswitch.sh — see SYNC.md.
// ─────────────────────────────────────────────────────────────────────────────
import CryptoKit
import Foundation

/// Cryptocurrency secret detection: BIP39 mnemonic seed phrases and
/// Bitcoin-style private keys (WIF, BIP32 extended private keys).
///
/// Added after a 2026-06 Microsoft writeup on "Crypto Clipper" malware, which
/// watches the clipboard for wallet seed phrases and private keys.
/// RoamSwitch's existing secret-leak auditor only covered developer API keys
/// (OpenAI, AWS, GitHub, ...) — nothing that could unlock a cryptocurrency
/// wallet.
///
/// Unlike API keys, a leaked seed phrase or private key can never be
/// "revoked" — the only remedy is moving funds to a brand-new wallet. And
/// unlike API keys (which have a distinctive, low-collision prefix like
/// `sk-` or `ghp_`), a seed phrase is just ordinary English words, and a raw
/// private key is just random bytes. Naive detection is unusable:
///
/// - A BIP39 mnemonic word list is common English vocabulary ("abandon",
///   "eager", "zone", ...) — matching "N words from the list in a row" alone
///   would flag ordinary prose. So every match is additionally required to
///   pass the real BIP39 checksum (the last word(s) encode a SHA-256-derived
///   checksum of the preceding entropy) before being reported. An arbitrary
///   sequence of valid-but-unrelated BIP39 words is checksum-valid only by
///   chance (1-in-16 for a 12-word phrase, ..., 1-in-256 for 24 words) —
///   nowhere near as reliable as an API key's fixed prefix, but combined
///   with ordinary prose almost never running 12+ consecutive words that are
///   *all* individually in the 2048-word list (common function words like
///   "the", "a", "is", "of", "and" are not on it), this keeps real-world
///   noise low.
/// - A raw hex private key (e.g. Ethereum's `0x` + 64 hex chars) has *no*
///   structural redundancy at all — it is bit-for-bit indistinguishable from
///   an Ethereum transaction hash or block hash of the same length, so no
///   format-only check can tell them apart. Rather than ship a detector that
///   would fire on every tx hash a user pastes, raw hex private keys are
///   deliberately NOT detected here — matches this codebase's existing
///   "only add a detector with a real verification algorithm" bar (see the
///   Linux edition's `crypto_secrets.rs`, and the DLP content-classifier
///   design in the `roamswitch-os` project).
/// - Bitcoin's WIF (Wallet Import Format) and BIP32 extended private keys
///   (`xprv`/`yprv`/`zprv`/`tprv`) *do* carry a real Base58Check checksum
///   (a double-SHA-256 digest), so those are detected and verified exactly
///   like the mnemonic case: candidates that fail the checksum are silently
///   ignored rather than reported.
///
/// Zero network access; entirely local, in-memory computation, same as the
/// rest of `SecretLeakScanning`. Ported line-for-line in spirit from the
/// Linux edition's `crypto_secrets.rs` so both editions detect (and reject)
/// exactly the same inputs; the two implementations are tested against the
/// same independently-verified checksum test vectors.
public enum CryptoSecretDetection {

    /// The official BIP39 English word list, in canonical order (word *N*'s
    /// position is its 11-bit index). Order matters for checksum
    /// computation — do not re-sort. Source: `bitcoin/bips`
    /// `bip-0039/english.txt`, fetched and independently verified against
    /// the well-known reference checksum test vectors (see
    /// `CryptoSecretDetectionTests`) on 2026-09-14.
    public static let bip39EnglishWords: [String] = [
        "abandon", "ability", "able", "about", "above", "absent", "absorb", "abstract",
        "absurd", "abuse", "access", "accident", "account", "accuse", "achieve", "acid",
        "acoustic", "acquire", "across", "act", "action", "actor", "actress", "actual",
        "adapt", "add", "addict", "address", "adjust", "admit", "adult", "advance",
        "advice", "aerobic", "affair", "afford", "afraid", "again", "age", "agent",
        "agree", "ahead", "aim", "air", "airport", "aisle", "alarm", "album",
        "alcohol", "alert", "alien", "all", "alley", "allow", "almost", "alone",
        "alpha", "already", "also", "alter", "always", "amateur", "amazing", "among",
        "amount", "amused", "analyst", "anchor", "ancient", "anger", "angle", "angry",
        "animal", "ankle", "announce", "annual", "another", "answer", "antenna", "antique",
        "anxiety", "any", "apart", "apology", "appear", "apple", "approve", "april",
        "arch", "arctic", "area", "arena", "argue", "arm", "armed", "armor",
        "army", "around", "arrange", "arrest", "arrive", "arrow", "art", "artefact",
        "artist", "artwork", "ask", "aspect", "assault", "asset", "assist", "assume",
        "asthma", "athlete", "atom", "attack", "attend", "attitude", "attract", "auction",
        "audit", "august", "aunt", "author", "auto", "autumn", "average", "avocado",
        "avoid", "awake", "aware", "away", "awesome", "awful", "awkward", "axis",
        "baby", "bachelor", "bacon", "badge", "bag", "balance", "balcony", "ball",
        "bamboo", "banana", "banner", "bar", "barely", "bargain", "barrel", "base",
        "basic", "basket", "battle", "beach", "bean", "beauty", "because", "become",
        "beef", "before", "begin", "behave", "behind", "believe", "below", "belt",
        "bench", "benefit", "best", "betray", "better", "between", "beyond", "bicycle",
        "bid", "bike", "bind", "biology", "bird", "birth", "bitter", "black",
        "blade", "blame", "blanket", "blast", "bleak", "bless", "blind", "blood",
        "blossom", "blouse", "blue", "blur", "blush", "board", "boat", "body",
        "boil", "bomb", "bone", "bonus", "book", "boost", "border", "boring",
        "borrow", "boss", "bottom", "bounce", "box", "boy", "bracket", "brain",
        "brand", "brass", "brave", "bread", "breeze", "brick", "bridge", "brief",
        "bright", "bring", "brisk", "broccoli", "broken", "bronze", "broom", "brother",
        "brown", "brush", "bubble", "buddy", "budget", "buffalo", "build", "bulb",
        "bulk", "bullet", "bundle", "bunker", "burden", "burger", "burst", "bus",
        "business", "busy", "butter", "buyer", "buzz", "cabbage", "cabin", "cable",
        "cactus", "cage", "cake", "call", "calm", "camera", "camp", "can",
        "canal", "cancel", "candy", "cannon", "canoe", "canvas", "canyon", "capable",
        "capital", "captain", "car", "carbon", "card", "cargo", "carpet", "carry",
        "cart", "case", "cash", "casino", "castle", "casual", "cat", "catalog",
        "catch", "category", "cattle", "caught", "cause", "caution", "cave", "ceiling",
        "celery", "cement", "census", "century", "cereal", "certain", "chair", "chalk",
        "champion", "change", "chaos", "chapter", "charge", "chase", "chat", "cheap",
        "check", "cheese", "chef", "cherry", "chest", "chicken", "chief", "child",
        "chimney", "choice", "choose", "chronic", "chuckle", "chunk", "churn", "cigar",
        "cinnamon", "circle", "citizen", "city", "civil", "claim", "clap", "clarify",
        "claw", "clay", "clean", "clerk", "clever", "click", "client", "cliff",
        "climb", "clinic", "clip", "clock", "clog", "close", "cloth", "cloud",
        "clown", "club", "clump", "cluster", "clutch", "coach", "coast", "coconut",
        "code", "coffee", "coil", "coin", "collect", "color", "column", "combine",
        "come", "comfort", "comic", "common", "company", "concert", "conduct", "confirm",
        "congress", "connect", "consider", "control", "convince", "cook", "cool", "copper",
        "copy", "coral", "core", "corn", "correct", "cost", "cotton", "couch",
        "country", "couple", "course", "cousin", "cover", "coyote", "crack", "cradle",
        "craft", "cram", "crane", "crash", "crater", "crawl", "crazy", "cream",
        "credit", "creek", "crew", "cricket", "crime", "crisp", "critic", "crop",
        "cross", "crouch", "crowd", "crucial", "cruel", "cruise", "crumble", "crunch",
        "crush", "cry", "crystal", "cube", "culture", "cup", "cupboard", "curious",
        "current", "curtain", "curve", "cushion", "custom", "cute", "cycle", "dad",
        "damage", "damp", "dance", "danger", "daring", "dash", "daughter", "dawn",
        "day", "deal", "debate", "debris", "decade", "december", "decide", "decline",
        "decorate", "decrease", "deer", "defense", "define", "defy", "degree", "delay",
        "deliver", "demand", "demise", "denial", "dentist", "deny", "depart", "depend",
        "deposit", "depth", "deputy", "derive", "describe", "desert", "design", "desk",
        "despair", "destroy", "detail", "detect", "develop", "device", "devote", "diagram",
        "dial", "diamond", "diary", "dice", "diesel", "diet", "differ", "digital",
        "dignity", "dilemma", "dinner", "dinosaur", "direct", "dirt", "disagree", "discover",
        "disease", "dish", "dismiss", "disorder", "display", "distance", "divert", "divide",
        "divorce", "dizzy", "doctor", "document", "dog", "doll", "dolphin", "domain",
        "donate", "donkey", "donor", "door", "dose", "double", "dove", "draft",
        "dragon", "drama", "drastic", "draw", "dream", "dress", "drift", "drill",
        "drink", "drip", "drive", "drop", "drum", "dry", "duck", "dumb",
        "dune", "during", "dust", "dutch", "duty", "dwarf", "dynamic", "eager",
        "eagle", "early", "earn", "earth", "easily", "east", "easy", "echo",
        "ecology", "economy", "edge", "edit", "educate", "effort", "egg", "eight",
        "either", "elbow", "elder", "electric", "elegant", "element", "elephant", "elevator",
        "elite", "else", "embark", "embody", "embrace", "emerge", "emotion", "employ",
        "empower", "empty", "enable", "enact", "end", "endless", "endorse", "enemy",
        "energy", "enforce", "engage", "engine", "enhance", "enjoy", "enlist", "enough",
        "enrich", "enroll", "ensure", "enter", "entire", "entry", "envelope", "episode",
        "equal", "equip", "era", "erase", "erode", "erosion", "error", "erupt",
        "escape", "essay", "essence", "estate", "eternal", "ethics", "evidence", "evil",
        "evoke", "evolve", "exact", "example", "excess", "exchange", "excite", "exclude",
        "excuse", "execute", "exercise", "exhaust", "exhibit", "exile", "exist", "exit",
        "exotic", "expand", "expect", "expire", "explain", "expose", "express", "extend",
        "extra", "eye", "eyebrow", "fabric", "face", "faculty", "fade", "faint",
        "faith", "fall", "false", "fame", "family", "famous", "fan", "fancy",
        "fantasy", "farm", "fashion", "fat", "fatal", "father", "fatigue", "fault",
        "favorite", "feature", "february", "federal", "fee", "feed", "feel", "female",
        "fence", "festival", "fetch", "fever", "few", "fiber", "fiction", "field",
        "figure", "file", "film", "filter", "final", "find", "fine", "finger",
        "finish", "fire", "firm", "first", "fiscal", "fish", "fit", "fitness",
        "fix", "flag", "flame", "flash", "flat", "flavor", "flee", "flight",
        "flip", "float", "flock", "floor", "flower", "fluid", "flush", "fly",
        "foam", "focus", "fog", "foil", "fold", "follow", "food", "foot",
        "force", "forest", "forget", "fork", "fortune", "forum", "forward", "fossil",
        "foster", "found", "fox", "fragile", "frame", "frequent", "fresh", "friend",
        "fringe", "frog", "front", "frost", "frown", "frozen", "fruit", "fuel",
        "fun", "funny", "furnace", "fury", "future", "gadget", "gain", "galaxy",
        "gallery", "game", "gap", "garage", "garbage", "garden", "garlic", "garment",
        "gas", "gasp", "gate", "gather", "gauge", "gaze", "general", "genius",
        "genre", "gentle", "genuine", "gesture", "ghost", "giant", "gift", "giggle",
        "ginger", "giraffe", "girl", "give", "glad", "glance", "glare", "glass",
        "glide", "glimpse", "globe", "gloom", "glory", "glove", "glow", "glue",
        "goat", "goddess", "gold", "good", "goose", "gorilla", "gospel", "gossip",
        "govern", "gown", "grab", "grace", "grain", "grant", "grape", "grass",
        "gravity", "great", "green", "grid", "grief", "grit", "grocery", "group",
        "grow", "grunt", "guard", "guess", "guide", "guilt", "guitar", "gun",
        "gym", "habit", "hair", "half", "hammer", "hamster", "hand", "happy",
        "harbor", "hard", "harsh", "harvest", "hat", "have", "hawk", "hazard",
        "head", "health", "heart", "heavy", "hedgehog", "height", "hello", "helmet",
        "help", "hen", "hero", "hidden", "high", "hill", "hint", "hip",
        "hire", "history", "hobby", "hockey", "hold", "hole", "holiday", "hollow",
        "home", "honey", "hood", "hope", "horn", "horror", "horse", "hospital",
        "host", "hotel", "hour", "hover", "hub", "huge", "human", "humble",
        "humor", "hundred", "hungry", "hunt", "hurdle", "hurry", "hurt", "husband",
        "hybrid", "ice", "icon", "idea", "identify", "idle", "ignore", "ill",
        "illegal", "illness", "image", "imitate", "immense", "immune", "impact", "impose",
        "improve", "impulse", "inch", "include", "income", "increase", "index", "indicate",
        "indoor", "industry", "infant", "inflict", "inform", "inhale", "inherit", "initial",
        "inject", "injury", "inmate", "inner", "innocent", "input", "inquiry", "insane",
        "insect", "inside", "inspire", "install", "intact", "interest", "into", "invest",
        "invite", "involve", "iron", "island", "isolate", "issue", "item", "ivory",
        "jacket", "jaguar", "jar", "jazz", "jealous", "jeans", "jelly", "jewel",
        "job", "join", "joke", "journey", "joy", "judge", "juice", "jump",
        "jungle", "junior", "junk", "just", "kangaroo", "keen", "keep", "ketchup",
        "key", "kick", "kid", "kidney", "kind", "kingdom", "kiss", "kit",
        "kitchen", "kite", "kitten", "kiwi", "knee", "knife", "knock", "know",
        "lab", "label", "labor", "ladder", "lady", "lake", "lamp", "language",
        "laptop", "large", "later", "latin", "laugh", "laundry", "lava", "law",
        "lawn", "lawsuit", "layer", "lazy", "leader", "leaf", "learn", "leave",
        "lecture", "left", "leg", "legal", "legend", "leisure", "lemon", "lend",
        "length", "lens", "leopard", "lesson", "letter", "level", "liar", "liberty",
        "library", "license", "life", "lift", "light", "like", "limb", "limit",
        "link", "lion", "liquid", "list", "little", "live", "lizard", "load",
        "loan", "lobster", "local", "lock", "logic", "lonely", "long", "loop",
        "lottery", "loud", "lounge", "love", "loyal", "lucky", "luggage", "lumber",
        "lunar", "lunch", "luxury", "lyrics", "machine", "mad", "magic", "magnet",
        "maid", "mail", "main", "major", "make", "mammal", "man", "manage",
        "mandate", "mango", "mansion", "manual", "maple", "marble", "march", "margin",
        "marine", "market", "marriage", "mask", "mass", "master", "match", "material",
        "math", "matrix", "matter", "maximum", "maze", "meadow", "mean", "measure",
        "meat", "mechanic", "medal", "media", "melody", "melt", "member", "memory",
        "mention", "menu", "mercy", "merge", "merit", "merry", "mesh", "message",
        "metal", "method", "middle", "midnight", "milk", "million", "mimic", "mind",
        "minimum", "minor", "minute", "miracle", "mirror", "misery", "miss", "mistake",
        "mix", "mixed", "mixture", "mobile", "model", "modify", "mom", "moment",
        "monitor", "monkey", "monster", "month", "moon", "moral", "more", "morning",
        "mosquito", "mother", "motion", "motor", "mountain", "mouse", "move", "movie",
        "much", "muffin", "mule", "multiply", "muscle", "museum", "mushroom", "music",
        "must", "mutual", "myself", "mystery", "myth", "naive", "name", "napkin",
        "narrow", "nasty", "nation", "nature", "near", "neck", "need", "negative",
        "neglect", "neither", "nephew", "nerve", "nest", "net", "network", "neutral",
        "never", "news", "next", "nice", "night", "noble", "noise", "nominee",
        "noodle", "normal", "north", "nose", "notable", "note", "nothing", "notice",
        "novel", "now", "nuclear", "number", "nurse", "nut", "oak", "obey",
        "object", "oblige", "obscure", "observe", "obtain", "obvious", "occur", "ocean",
        "october", "odor", "off", "offer", "office", "often", "oil", "okay",
        "old", "olive", "olympic", "omit", "once", "one", "onion", "online",
        "only", "open", "opera", "opinion", "oppose", "option", "orange", "orbit",
        "orchard", "order", "ordinary", "organ", "orient", "original", "orphan", "ostrich",
        "other", "outdoor", "outer", "output", "outside", "oval", "oven", "over",
        "own", "owner", "oxygen", "oyster", "ozone", "pact", "paddle", "page",
        "pair", "palace", "palm", "panda", "panel", "panic", "panther", "paper",
        "parade", "parent", "park", "parrot", "party", "pass", "patch", "path",
        "patient", "patrol", "pattern", "pause", "pave", "payment", "peace", "peanut",
        "pear", "peasant", "pelican", "pen", "penalty", "pencil", "people", "pepper",
        "perfect", "permit", "person", "pet", "phone", "photo", "phrase", "physical",
        "piano", "picnic", "picture", "piece", "pig", "pigeon", "pill", "pilot",
        "pink", "pioneer", "pipe", "pistol", "pitch", "pizza", "place", "planet",
        "plastic", "plate", "play", "please", "pledge", "pluck", "plug", "plunge",
        "poem", "poet", "point", "polar", "pole", "police", "pond", "pony",
        "pool", "popular", "portion", "position", "possible", "post", "potato", "pottery",
        "poverty", "powder", "power", "practice", "praise", "predict", "prefer", "prepare",
        "present", "pretty", "prevent", "price", "pride", "primary", "print", "priority",
        "prison", "private", "prize", "problem", "process", "produce", "profit", "program",
        "project", "promote", "proof", "property", "prosper", "protect", "proud", "provide",
        "public", "pudding", "pull", "pulp", "pulse", "pumpkin", "punch", "pupil",
        "puppy", "purchase", "purity", "purpose", "purse", "push", "put", "puzzle",
        "pyramid", "quality", "quantum", "quarter", "question", "quick", "quit", "quiz",
        "quote", "rabbit", "raccoon", "race", "rack", "radar", "radio", "rail",
        "rain", "raise", "rally", "ramp", "ranch", "random", "range", "rapid",
        "rare", "rate", "rather", "raven", "raw", "razor", "ready", "real",
        "reason", "rebel", "rebuild", "recall", "receive", "recipe", "record", "recycle",
        "reduce", "reflect", "reform", "refuse", "region", "regret", "regular", "reject",
        "relax", "release", "relief", "rely", "remain", "remember", "remind", "remove",
        "render", "renew", "rent", "reopen", "repair", "repeat", "replace", "report",
        "require", "rescue", "resemble", "resist", "resource", "response", "result", "retire",
        "retreat", "return", "reunion", "reveal", "review", "reward", "rhythm", "rib",
        "ribbon", "rice", "rich", "ride", "ridge", "rifle", "right", "rigid",
        "ring", "riot", "ripple", "risk", "ritual", "rival", "river", "road",
        "roast", "robot", "robust", "rocket", "romance", "roof", "rookie", "room",
        "rose", "rotate", "rough", "round", "route", "royal", "rubber", "rude",
        "rug", "rule", "run", "runway", "rural", "sad", "saddle", "sadness",
        "safe", "sail", "salad", "salmon", "salon", "salt", "salute", "same",
        "sample", "sand", "satisfy", "satoshi", "sauce", "sausage", "save", "say",
        "scale", "scan", "scare", "scatter", "scene", "scheme", "school", "science",
        "scissors", "scorpion", "scout", "scrap", "screen", "script", "scrub", "sea",
        "search", "season", "seat", "second", "secret", "section", "security", "seed",
        "seek", "segment", "select", "sell", "seminar", "senior", "sense", "sentence",
        "series", "service", "session", "settle", "setup", "seven", "shadow", "shaft",
        "shallow", "share", "shed", "shell", "sheriff", "shield", "shift", "shine",
        "ship", "shiver", "shock", "shoe", "shoot", "shop", "short", "shoulder",
        "shove", "shrimp", "shrug", "shuffle", "shy", "sibling", "sick", "side",
        "siege", "sight", "sign", "silent", "silk", "silly", "silver", "similar",
        "simple", "since", "sing", "siren", "sister", "situate", "six", "size",
        "skate", "sketch", "ski", "skill", "skin", "skirt", "skull", "slab",
        "slam", "sleep", "slender", "slice", "slide", "slight", "slim", "slogan",
        "slot", "slow", "slush", "small", "smart", "smile", "smoke", "smooth",
        "snack", "snake", "snap", "sniff", "snow", "soap", "soccer", "social",
        "sock", "soda", "soft", "solar", "soldier", "solid", "solution", "solve",
        "someone", "song", "soon", "sorry", "sort", "soul", "sound", "soup",
        "source", "south", "space", "spare", "spatial", "spawn", "speak", "special",
        "speed", "spell", "spend", "sphere", "spice", "spider", "spike", "spin",
        "spirit", "split", "spoil", "sponsor", "spoon", "sport", "spot", "spray",
        "spread", "spring", "spy", "square", "squeeze", "squirrel", "stable", "stadium",
        "staff", "stage", "stairs", "stamp", "stand", "start", "state", "stay",
        "steak", "steel", "stem", "step", "stereo", "stick", "still", "sting",
        "stock", "stomach", "stone", "stool", "story", "stove", "strategy", "street",
        "strike", "strong", "struggle", "student", "stuff", "stumble", "style", "subject",
        "submit", "subway", "success", "such", "sudden", "suffer", "sugar", "suggest",
        "suit", "summer", "sun", "sunny", "sunset", "super", "supply", "supreme",
        "sure", "surface", "surge", "surprise", "surround", "survey", "suspect", "sustain",
        "swallow", "swamp", "swap", "swarm", "swear", "sweet", "swift", "swim",
        "swing", "switch", "sword", "symbol", "symptom", "syrup", "system", "table",
        "tackle", "tag", "tail", "talent", "talk", "tank", "tape", "target",
        "task", "taste", "tattoo", "taxi", "teach", "team", "tell", "ten",
        "tenant", "tennis", "tent", "term", "test", "text", "thank", "that",
        "theme", "then", "theory", "there", "they", "thing", "this", "thought",
        "three", "thrive", "throw", "thumb", "thunder", "ticket", "tide", "tiger",
        "tilt", "timber", "time", "tiny", "tip", "tired", "tissue", "title",
        "toast", "tobacco", "today", "toddler", "toe", "together", "toilet", "token",
        "tomato", "tomorrow", "tone", "tongue", "tonight", "tool", "tooth", "top",
        "topic", "topple", "torch", "tornado", "tortoise", "toss", "total", "tourist",
        "toward", "tower", "town", "toy", "track", "trade", "traffic", "tragic",
        "train", "transfer", "trap", "trash", "travel", "tray", "treat", "tree",
        "trend", "trial", "tribe", "trick", "trigger", "trim", "trip", "trophy",
        "trouble", "truck", "true", "truly", "trumpet", "trust", "truth", "try",
        "tube", "tuition", "tumble", "tuna", "tunnel", "turkey", "turn", "turtle",
        "twelve", "twenty", "twice", "twin", "twist", "two", "type", "typical",
        "ugly", "umbrella", "unable", "unaware", "uncle", "uncover", "under", "undo",
        "unfair", "unfold", "unhappy", "uniform", "unique", "unit", "universe", "unknown",
        "unlock", "until", "unusual", "unveil", "update", "upgrade", "uphold", "upon",
        "upper", "upset", "urban", "urge", "usage", "use", "used", "useful",
        "useless", "usual", "utility", "vacant", "vacuum", "vague", "valid", "valley",
        "valve", "van", "vanish", "vapor", "various", "vast", "vault", "vehicle",
        "velvet", "vendor", "venture", "venue", "verb", "verify", "version", "very",
        "vessel", "veteran", "viable", "vibrant", "vicious", "victory", "video", "view",
        "village", "vintage", "violin", "virtual", "virus", "visa", "visit", "visual",
        "vital", "vivid", "vocal", "voice", "void", "volcano", "volume", "vote",
        "voyage", "wage", "wagon", "wait", "walk", "wall", "walnut", "want",
        "warfare", "warm", "warrior", "wash", "wasp", "waste", "water", "wave",
        "way", "wealth", "weapon", "wear", "weasel", "weather", "web", "wedding",
        "weekend", "weird", "welcome", "west", "wet", "whale", "what", "wheat",
        "wheel", "when", "where", "whip", "whisper", "wide", "width", "wife",
        "wild", "will", "win", "window", "wine", "wing", "wink", "winner",
        "winter", "wire", "wisdom", "wise", "wish", "witness", "wolf", "woman",
        "wonder", "wood", "wool", "word", "work", "world", "worry", "worth",
        "wrap", "wreck", "wrestle", "wrist", "write", "wrong", "yard", "year",
        "yellow", "you", "young", "youth", "zebra", "zero", "zone", "zoo",
    ]

    /// Word counts BIP39 defines a checksum scheme for (128/160/192/224/256
    /// bits of entropy + a 4/5/6/7/8-bit checksum, packed 11 bits/word).
    private static let validMnemonicLengths: Set<Int> = [12, 15, 18, 21, 24]

    private static let wordIndex: [String: Int] = {
        var m: [String: Int] = [:]
        m.reserveCapacity(bip39EnglishWords.count)
        for (i, w) in bip39EnglishWords.enumerated() { m[w] = i }
        return m
    }()

    /// True if `indices` (11-bit BIP39 word indices, in order) has a length
    /// that is one of the 5 valid mnemonic lengths *and* its trailing
    /// checksum bits match a real SHA-256 checksum of the leading entropy
    /// bits.
    private static func mnemonicChecksumValid(_ indices: [Int]) -> Bool {
        let n = indices.count
        guard validMnemonicLengths.contains(n) else { return false }
        let totalBits = n * 11
        let csBits = totalBits / 33
        let entBits = totalBits - csBits

        let bitstream = packBitsMSBFirst(indices)
        let entropy = Data(bitstream[0..<(entBits / 8)])
        // The checksum bits sit immediately after the entropy bits, still
        // within the following byte for every valid mnemonic length
        // (entBits is always a multiple of 8, and csBits <= 8).
        let checksumByte = bitstream[entBits / 8]
        let actualChecksum = checksumByte >> (8 - csBits)

        let hash = SHA256.hash(data: entropy)
        let expectedChecksum = hash.withUnsafeBytes { $0[0] } >> (8 - csBits)
        return actualChecksum == expectedChecksum
    }

    /// Packs `indices` (each an 11-bit value) into a big-endian byte buffer,
    /// MSB-first, zero-padding the final partial byte.
    private static func packBitsMSBFirst(_ indices: [Int]) -> [UInt8] {
        var out: [UInt8] = []
        out.reserveCapacity(indices.count * 11 / 8 + 1)
        var acc: UInt32 = 0
        var accBits: UInt32 = 0
        for idx in indices {
            acc = (acc << 11) | UInt32(idx)
            accBits += 11
            while accBits >= 8 {
                accBits -= 8
                out.append(UInt8((acc >> accBits) & 0xFF))
            }
        }
        if accBits > 0 {
            out.append(UInt8((acc << (8 - accBits)) & 0xFF))
        }
        return out
    }

    /// Scans already-lowercased `tokens` for maximal runs of consecutive
    /// BIP39 words, and returns `(start, end)` (end-exclusive, indices into
    /// `tokens`) for every checksum-valid mnemonic found. A run longer than
    /// the longest valid length is tried at each valid length
    /// (12/15/18/21/24), longest first, matching how a user would paste a
    /// phrase together with a little surrounding prose.
    public static func findMnemonicSpans(_ tokens: [String]) -> [(start: Int, end: Int)] {
        var spans: [(start: Int, end: Int)] = []
        var i = 0
        while i < tokens.count {
            guard wordIndex[tokens[i]] != nil else {
                i += 1
                continue
            }
            let runStart = i
            while i < tokens.count, wordIndex[tokens[i]] != nil {
                i += 1
            }
            let runEnd = i
            let runLen = runEnd - runStart

            var reportedEnd = runStart
            for wantLen in [24, 21, 18, 15, 12] where wantLen <= runLen {
                var start = max(runStart, reportedEnd)
                while start + wantLen <= runEnd {
                    let indices = (start..<(start + wantLen)).map { wordIndex[tokens[$0]]! }
                    if mnemonicChecksumValid(indices) {
                        spans.append((start, start + wantLen))
                        reportedEnd = start + wantLen
                        start = reportedEnd
                    } else {
                        start += 1
                    }
                }
            }
        }
        return spans
    }

    private static let base58Alphabet: [UInt8] = Array("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz".utf8)

    /// Decodes a Base58 string into bytes (no checksum handling here — see
    /// `base58CheckDecode`). Returns `nil` for any character outside the
    /// Base58 alphabet.
    private static func base58Decode(_ s: String) -> [UInt8]? {
        var bytes: [UInt8] = []
        for ch in s.utf8 {
            guard let digit = base58Alphabet.firstIndex(of: ch) else { return nil }
            var carry = UInt32(digit)
            for i in stride(from: bytes.count - 1, through: 0, by: -1) {
                let x = UInt32(bytes[i]) * 58 + carry
                bytes[i] = UInt8(x & 0xFF)
                carry = x >> 8
            }
            while carry > 0 {
                bytes.insert(UInt8(carry & 0xFF), at: 0)
                carry >>= 8
            }
        }
        let leadingOnes = s.utf8.prefix(while: { $0 == UInt8(ascii: "1") }).count
        return Array(repeating: 0, count: leadingOnes) + bytes
    }

    /// Decodes a Base58Check string (base58 payload + 4-byte double-SHA-256
    /// checksum), verifying the checksum. Returns the payload (version +
    /// data, checksum stripped) on success.
    private static func base58CheckDecode(_ s: String) -> [UInt8]? {
        guard !s.isEmpty, s.count <= 200, let full = base58Decode(s), full.count >= 4 else { return nil }
        let data = Array(full[0..<(full.count - 4)])
        let checksum = Array(full[(full.count - 4)...])
        let firstHash = SHA256.hash(data: Data(data))
        let calc = SHA256.hash(data: Data(firstHash))
        guard Array(calc.prefix(4)) == checksum else { return nil }
        return data
    }

    /// A checksum-verified Bitcoin-style private key candidate.
    public enum CryptoKeyKind {
        /// Wallet Import Format (mainnet or testnet, compressed or not).
        case wif
        /// BIP32 extended private key (`xprv`/`yprv`/`zprv`/`tprv`).
        case extendedPrivateKey
    }

    /// Returns the kind of checksum-verified private key `candidate` decodes
    /// to, or `nil` if it isn't valid Base58Check, has the wrong length for
    /// any known key format, or (for WIF/extended keys) has a
    /// public-key/other version byte.
    public static func classifyCryptoKeyCandidate(_ candidate: String) -> CryptoKeyKind? {
        guard let data = base58CheckDecode(candidate) else { return nil }
        switch data.count {
        case 33, 34:
            // WIF: 1-byte version + 32-byte key (+ optional 0x01 compression flag).
            let version = data[0]
            guard version == 0x80 || version == 0xEF else { return nil }
            if data.count == 34, data[33] != 0x01 { return nil }
            return .wif
        case 78:
            // BIP32 extended key: 4-byte version + 1 depth + 4 fingerprint +
            // 4 child number + 32 chain code + 33 key material = 78 bytes.
            let version = UInt32(data[0]) << 24 | UInt32(data[1]) << 16 | UInt32(data[2]) << 8 | UInt32(data[3])
            let xprv: UInt32 = 0x0488ADE4
            let yprv: UInt32 = 0x049D7878
            let zprv: UInt32 = 0x04B2430C
            let tprv: UInt32 = 0x04358394
            guard [xprv, yprv, zprv, tprv].contains(version) else { return nil }
            // Byte at offset 45 (4 version + 1 depth + 4 fingerprint + 4
            // child number + 32 chain code) must be 0x00, marking a private
            // key (a public key would carry a 33-byte compressed point
            // starting with 0x02/0x03 there instead).
            return data[45] == 0x00 ? .extendedPrivateKey : nil
        default:
            return nil
        }
    }

    /// Coarse regex pre-filters for `classifyCryptoKeyCandidate` to check —
    /// cheap to run over every line before the Base58Check decode. Real
    /// Base58 excludes `0`, `O`, `I`, `l` to avoid visual ambiguity.
    public static let wifCandidatePattern = #"\b[5KL9c][1-9A-HJ-NP-Za-km-z]{45,52}\b"#
    public static let extendedKeyCandidatePattern = #"\b[xyzt]prv[1-9A-HJ-NP-Za-km-z]{95,116}\b"#

    /// Splits `line` into lowercased word tokens for the BIP39 mnemonic
    /// scan, trimming leading/trailing punctuation (e.g. a trailing comma or
    /// period) so `"abandon, abandon,"` still tokenizes to two matchable
    /// words.
    public static func tokenizeWords(_ line: String) -> [String] {
        line.split(whereSeparator: { $0.isWhitespace })
            .map { token -> String in
                var s = Substring(token)
                while let f = s.first, !f.isLetter, !f.isNumber { s = s.dropFirst() }
                while let l = s.last, !l.isLetter, !l.isNumber { s = s.dropLast() }
                return s.lowercased()
            }
            .filter { !$0.isEmpty }
    }
}
