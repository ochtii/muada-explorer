// Austrian Dialect (Wienerisch) Übersetzungen für MUADA Explorer

export const austrianDialect = {
  // Greetings
  greetings: {
    hello: 'Seas',
    hi: 'Dere',
    welcome: 'Griaß di',
    bye: 'Baba',
    goodMorning: 'Servas'
  },

  // Success messages
  success: {
    saved: 'Fix Oida!',
    perfect: 'Passt!',
    awesome: 'Leiwand!',
    cool: 'Geil Oida!',
    done: 'Erledigt, Oida!'
  },

  // Error messages
  errors: {
    generic: 'Gschissn',
    bad: 'Schaß',
    shit: 'Heisl',
    damn: 'Orsch',
    crap: 'Blunzn'
  },

  // Loading states
  loading: {
    wait: 'Wart kurz, Oida...',
    chill: 'Chill amal...',
    loading: 'Lädt...',
    fetching: 'Hol ma des...'
  },

  // Buttons
  buttons: {
    save: 'Speichern, Oida',
    cancel: 'Na, lass liegn',
    delete: 'Löschen, fix',
    edit: 'Bearbeiten',
    login: 'Eineloggen',
    logout: 'Schleich di',
    signup: 'Registrieren',
    submit: 'Abschicken',
    back: 'Zruck',
    next: 'Weiter',
    close: 'Zumachen'
  },

  // Insults (for errors/permission denied)
  insults: {
    fool: 'Du Wappla',
    idiot: 'Sacklpicka',
    dummy: 'Trottel',
    sausage: 'Blunzn',
    weakling: 'Lappen'
  },

  // Location categories
  categories: {
    industrial: 'Tschick-Fabrik',
    manor: 'Oides Schloss',
    hospital: 'Krankenhaus',
    military: 'Kasern',
    residential: 'Oides Heisl',
    bunker: 'Bunker-Loch',
    other: 'Sonstiges Zeig'
  },

  // Role names
  roles: {
    user: 'User',
    mitglied: 'Mitglied',
    mod: 'Moderator',
    admin: 'Admin',
    webmaster: 'Webmaster'
  },

  // Level badges
  levels: {
    newbie: 'Urbex Newbie',
    temu: 'Temu Urbexer',
    hobby: 'Hobby Urbexer',
    advanced: 'Advanced Urbexer',
    profi: 'Profi Urbexer',
    god: 'Urbex Gott',
    muada: 'Muada aller Urbexer'
  },

  // Common phrases
  phrases: {
    noAccess: 'Na geh, des darfst net sehen!',
    becomeMember: 'Werd erst Mitglied, du Wappla!',
    needPermission: 'Du host ka Berechtigung, Oida!',
    noData: 'Nix do, Oida...',
    comingSoon: 'Kommt boid!',
    fillAllFields: 'Füll ois aus, du Trottel!',
    tooShort: 'Zu kurz, Oida!',
    tooLong: 'Zu lang, des geht net!',
    invalidFormat: 'Des Format is gschissn!',
    alreadyExists: 'Des homs scho!',
    notFound: 'Nix gfunden...',
    tryAgain: 'Probiers nu amoi!'
  },

  // Map related
  map: {
    title: 'Kinetten-Karte',
    yourLocation: 'Du bist do',
    addMarker: 'Marker setzen',
    visited: 'Scho gwesen',
    notVisited: 'Nu net gwesen',
    approved: 'Freigegeben',
    pending: 'Wartet auf Freigabe'
  },

  // Stats
  stats: {
    points: 'Punkte',
    visits: 'Besucht',
    added: 'Hinzugfügt',
    reviews: 'Reviews',
    level: 'Level'
  }
}

// Helper function to get category translation
export const getCategoryName = (category) => {
  return austrianDialect.categories[category] || category
}

// Helper function to get role translation
export const getRoleName = (role) => {
  return austrianDialect.roles[role] || role
}

// Helper function to get random success message
export const getRandomSuccess = () => {
  const messages = Object.values(austrianDialect.success)
  return messages[Math.floor(Math.random() * messages.length)]
}

// Helper function to get random error message
export const getRandomError = () => {
  const messages = Object.values(austrianDialect.errors)
  return messages[Math.floor(Math.random() * messages.length)]
}

// Helper function to get random insult
export const getRandomInsult = () => {
  const messages = Object.values(austrianDialect.insults)
  return messages[Math.floor(Math.random() * messages.length)]
}

export default austrianDialect
