// LIFE RPG — справочные данные: ранги, категории, тарифы XP, режимы, миры.

// Шкала рангов игрока (как на карточке профиля: A = 30 000–99 999).
export const RANKS = [
  { id: 'E',   name: 'Novice',        ru: 'Новичок',         min: 0,       icon: '🌱', color: '#c08a4a' },
  { id: 'D',   name: 'Explorer',      ru: 'Исследователь',   min: 1000,    icon: '🧭', color: '#9aa4b5' },
  { id: 'C',   name: 'Professional',  ru: 'Профессионал',    min: 5000,    icon: '🌐', color: '#e0b04a' },
  { id: 'B',   name: 'Elite',         ru: 'Элита',           min: 15000,   icon: '💎', color: '#a879ff' },
  { id: 'A',   name: 'Legend',        ru: 'Легенда',         min: 30000,   icon: '👑', color: '#ffc845' },
  { id: 'S',   name: 'World Builder', ru: 'Строитель мира',  min: 100000,  icon: '🌍', color: '#5aa8ff' },
  { id: 'SS',  name: 'Icon',          ru: 'Икона',           min: 250000,  icon: '⭐', color: '#d58bff' },
  { id: 'SSS', name: 'Legacy',        ru: 'Наследие',        min: 500000,  icon: '🏛', color: '#ffd76a' },
];

// Что означает каждый ранг (экран «Ранги»).
export const RANK_INFO = {
  E:   { goal: 'Построить фундамент.', needs: ['Закончить школу', 'Первые международные сертификаты', 'Английский C1', 'Создать первый стартап', 'Первые научные статьи', 'Первые стажировки', 'Первые 10 000 подписчиков'], motto: 'Ты начинаешь путь.' },
  D:   { goal: 'Стать сильным студентом и исследователем.', needs: ['Диплом IB', 'Поступить в топовый университет', '3 языка C1', '10 научных статей', 'Первый доход $10k+/мес', 'Первый успешный продукт', '100k подписчиков'], motto: 'Исследуй. Учись. Расти.' },
  C:   { goal: 'Выйти на мировой уровень.', needs: ['Учёба в Harvard / топ-вузе', 'Исследования международного уровня', 'Работа с NASA или похожими организациями', 'Доход около $100k+/мес', 'Несколько успешных компаний', '1 млн аудитории', 'Forbes 30 Under 30'], motto: 'Профессионал мирового уровня.' },
  B:   { goal: 'Построить империю и масштабировать влияние.', needs: ['20+ научных публикаций', '5 автоматизированных бизнесов', 'Доход десятки миллионов ₸ в месяц', '10 языков, минимум 5 подтверждены', '10 млн подписчиков', 'Международные выступления'], motto: 'Элита. Твой голос слышат.' },
  A:   { goal: 'Стать легендой в своей сфере.', needs: ['Изобретение мирового уровня', 'Работа, влияющая на отрасль', '50 научных публикаций', '10 успешных компаний', 'Крупный инвестиционный портфель', 'Известность во многих странах'], motto: 'Легенды меняют мир.' },
  S:   { goal: 'Создавать то, чем пользуется весь мир.', needs: ['Технологии, которыми пользуется мир', 'Сотни миллионов людей знают твой бренд', 'Благотворительные проекты мирового масштаба', 'Международное признание'], motto: 'Ты строишь будущее.' },
  SS:  { goal: 'Вдохновлять поколения.', needs: ['Один из самых известных предпринимателей поколения', 'Огромное влияние в технологиях и образовании', 'Международные награды', 'Личный бренд мирового масштаба'], motto: 'Иконы вдохновляют поколения.' },
  SSS: { goal: 'Оставить наследие, которое живёт без тебя.', needs: ['Компании, технологии и образовательные проекты, работающие десятилетиями', 'Научные открытия', 'Инвестиции в будущее'], motto: 'Наследие живёт вечно.' },
};

// Шкала компании: «Company Level: C — Growth · 18 450 / 30 000 XP · Next: B — Scale».
export const COMPANY_RANKS = [
  { id: 'E',   name: 'Idea',            min: 0 },
  { id: 'D',   name: 'MVP',             min: 2000 },
  { id: 'C',   name: 'Growth',          min: 8000 },
  { id: 'B',   name: 'Scale',           min: 30000 },
  { id: 'A',   name: 'Expansion',       min: 75000 },
  { id: 'S',   name: 'Market Leader',   min: 150000 },
  { id: 'SS',  name: 'Global Company',  min: 300000 },
  { id: 'SSS', name: 'Legacy',          min: 600000 },
];

export const COMPANY_STAGES = ['IDEA', 'VALIDATION', 'MVP', 'FIRST CUSTOMER', 'REVENUE', 'TEAM', 'PRODUCT-MARKET FIT', 'EXPANSION', 'INTERNATIONAL', 'SCALE', 'MARKET LEADER', 'GLOBAL COMPANY'];

// Детская шкала — карта приключения.
export const KIDS_RANKS = [
  { id: 'E',   name: 'Starter',  icon: '🌱', min: 0 },
  { id: 'D',   name: 'Explorer', icon: '🧭', min: 300 },
  { id: 'C',   name: 'Builder',  icon: '🛠', min: 1000 },
  { id: 'B',   name: 'Inventor', icon: '🚀', min: 2500 },
  { id: 'A',   name: 'Master',   icon: '🏆', min: 5000 },
  { id: 'S',   name: 'Legend',   icon: '🌟', min: 10000 },
  { id: 'SS',  name: 'Hero',     icon: '🦸', min: 20000 },
  { id: 'SSS', name: 'Champion', icon: '👑', min: 40000 },
];

// Ранг отдельного направления (Technology: S, Sales: C …).
export const CATEGORY_RANKS = [
  { id: 'E', min: 0 }, { id: 'D', min: 300 }, { id: 'C', min: 1000 }, { id: 'B', min: 2500 },
  { id: 'A', min: 5000 }, { id: 'S', min: 12000 }, { id: 'SS', min: 30000 }, { id: 'SSS', min: 60000 },
];

export const CATEGORIES = {
  education:     { label: 'Образование',              emoji: '🎓', color: '#5aa8ff' },
  science:       { label: 'Наука и исследования',     emoji: '🔬', color: '#4fd1a5' },
  tech:          { label: 'Программирование и технологии', emoji: '💻', color: '#7c8cff' },
  business:      { label: 'Проекты и бизнес',         emoji: '🚀', color: '#ff8a4c' },
  languages:     { label: 'Языки',                    emoji: '🌍', color: '#3fc1e0' },
  career:        { label: 'Карьера и опыт',           emoji: '💼', color: '#e0b04a' },
  media:         { label: 'Медиа и выступления',      emoji: '🎤', color: '#ff5d8f' },
  growth:        { label: 'Личное развитие',          emoji: '🧠', color: '#b07cff' },
  life:          { label: 'Личная жизнь',             emoji: '❤️', color: '#ff6b6b' },
  health:        { label: 'Здоровье и спорт',         emoji: '💪', color: '#5fd068' },
  // детские
  study:         { label: 'Учёба',                    emoji: '📘', color: '#5aa8ff' },
  reading:       { label: 'Чтение',                   emoji: '📚', color: '#4fd1a5' },
  sport:         { label: 'Спорт',                    emoji: '⚽', color: '#5fd068' },
  creativity:    { label: 'Творчество',               emoji: '🎨', color: '#ff8a4c' },
  projects:      { label: 'Проекты',                  emoji: '🛠', color: '#7c8cff' },
  independence:  { label: 'Самостоятельность',        emoji: '🧭', color: '#e0b04a' },
  // компания
  product:       { label: 'Product',                  emoji: '📦', color: '#7c8cff' },
  team:          { label: 'Team',                     emoji: '👥', color: '#4fd1a5' },
  finance:       { label: 'Finance',                  emoji: '💰', color: '#e0b04a' },
  sales:         { label: 'Sales',                    emoji: '📈', color: '#ff8a4c' },
  technology:    { label: 'Technology',               emoji: '⚙️', color: '#5aa8ff' },
  rnd:           { label: 'R&D',                      emoji: '🧪', color: '#b07cff' },
  brand:         { label: 'Brand',                    emoji: '✨', color: '#ff5d8f' },
  international: { label: 'International Expansion',  emoji: '🌐', color: '#3fc1e0' },
  impact:        { label: 'Impact',                   emoji: '🌱', color: '#5fd068' },
};

// Типы миров и их «деревья» направлений.
export const WORLD_TYPES = {
  personal:  { label: 'Personal World',  emoji: '👤', scale: 'person',  cats: ['education', 'science', 'tech', 'business', 'languages', 'career', 'media', 'growth', 'life', 'health'] },
  academic:  { label: 'Academic World',  emoji: '🎓', scale: 'person',  cats: ['education', 'science', 'languages', 'media'] },
  developer: { label: 'Developer World', emoji: '💻', scale: 'person',  cats: ['tech', 'career', 'business', 'education'] },
  career:    { label: 'Career World',    emoji: '💼', scale: 'person',  cats: ['career', 'tech', 'education', 'media', 'growth'] },
  research:  { label: 'Research World',  emoji: '🔬', scale: 'person',  cats: ['science', 'education', 'media', 'tech'] },
  company:   { label: 'Company World',   emoji: '🏢', scale: 'company', cats: ['product', 'team', 'finance', 'sales', 'technology', 'rnd', 'brand', 'international', 'impact'] },
  kids:      { label: 'Kids World',      emoji: '🧒', scale: 'kids',    cats: ['study', 'reading', 'sport', 'creativity', 'projects', 'independence'] },
};

// Режимы при старте.
export const MODES = {
  life:     { label: 'LIFE MODE',     emoji: '🧍', desc: 'Образование, карьера, здоровье, языки, финансы, отношения, путешествия, проекты.', world: 'personal' },
  kids:     { label: 'KIDS MODE',     emoji: '🧒', desc: 'Учёба, чтение, спорт, творчество. Не «ты должен», а Level Up! Родитель подтверждает достижения.', world: 'kids' },
  sen:      { label: 'SEN MODE',      emoji: '🧩', desc: 'Для детей и взрослых с РАС и ООП: визуальные маленькие шаги, свой темп, предсказуемые награды, спокойный экран.', world: 'kids' },
  academic: { label: 'ACADEMIC MODE', emoji: '🎓', desc: 'Олимпиады → университет → исследования → публикации → PhD → лаборатория.', world: 'academic' },
  career:   { label: 'CAREER MODE',   emoji: '💼', desc: 'Выбираешь профессию — система строит дерево от Junior до CTO.', world: 'developer' },
  company:  { label: 'COMPANY MODE',  emoji: '🚀', desc: 'Компания — RPG-персонаж: IDEA → MVP → REVENUE → INTERNATIONAL → GLOBAL COMPANY.', world: 'company' },
};

// Стандартизированная система XP (Verified XP считается только по ней).
export const XP_TIERS = [
  { id: 'task',        label: 'Небольшая задача / новый навык',     min: 50,   max: 100,   def: 80 },
  { id: 'cert',        label: 'Сертификат / небольшой проект',      min: 200,  max: 500,   def: 300 },
  { id: 'project',     label: 'Завершённый серьёзный проект',       min: 500,  max: 1500,  def: 800 },
  { id: 'internship',  label: 'Стажировка',                         min: 1000, max: 3000,  def: 1500 },
  { id: 'publication', label: 'Научная публикация',                 min: 1000, max: 3000,  def: 1500 },
  { id: 'intl',        label: 'Международное достижение',           min: 2000, max: 5000,  def: 2500 },
  { id: 'university',  label: 'Поступление в сильный университет',  min: 5000, max: 10000, def: 7000 },
  { id: 'startup',     label: 'Запуск успешного продукта/стартапа', min: 5000, max: 20000, def: 8000 },
];

// Детские тарифы — маленькие и предсказуемые.
export const KIDS_TIERS = [
  { id: 'kid_small', label: 'Маленький квест',  min: 20,  max: 50,  def: 30 },
  { id: 'kid_mid',   label: 'Квест побольше',   min: 50,  max: 150, def: 100 },
  { id: 'kid_big',   label: 'Большое достижение', min: 150, max: 500, def: 300 },
];

export const ALL_TIERS = [...XP_TIERS, ...KIDS_TIERS];

export const PROOF_TYPES = ['Сертификат', 'GitHub', 'Публикация', 'Диплом', 'Ссылка', 'Портфолио', 'Фото/видео', 'Подтверждение родителя'];
