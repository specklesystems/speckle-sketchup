import Fs from 'fs'
import Path from 'path'
import Sqlite from 'sqlite3'

const { platform, homedir } = require('os')

export function getSpeckleFolder() {
  let dir = platform().startsWith('win')
    ? Path.join(homedir(), 'Speckle')
    : Path.join(homedir(), '.config', 'Speckle')

  if (!Fs.existsSync(dir)) Fs.mkdirSync(dir)

  return dir
}

function openSpeckleSettings() {
  let dbLocation = Path.join(getSpeckleFolder(), 'Accounts.db')

  let db = new Sqlite.Database(dbLocation, Sqlite.OPEN_READWRITE | Sqlite.OPEN_CREATE, (err) => {
    if (err) {
      console.log(err.message)
    }
  })

  db.serialize(() =>
    db.run(`CREATE TABLE IF NOT EXISTS objects (
      hash VARCHAR PRIMARY KEY NOT NULL,
      content VARCHAR
      )`)
  )

  return db
}

export default {
  state: {
    accounts: [],
    suuid: null,
    challenge: '',
    server: ''
  },

  getters: {
    getDefaultAccount(state) {
      return state.accounts.find((x) => x.isDefault)
    },

    getChallengeAndServer(state) {
      return { challenge: state.challenge, server: state.server }
    }
  },

  mutations: {
    CLEAR_ACCOUNTS(state) {
      state.accounts.splice(0, state.accounts.length)
    },

    SORT_ACCOUNTS(state) {
      state.accounts.sort((x, y) => (x.isDefault === y.isDefault ? 0 : x.isDefault ? -1 : 1))
    },

    ADD_ACCOUNT(state, { account }) {
      let duplicateAccountIndex = state.accounts.findIndex((a) => a.id === account.id)
      if (duplicateAccountIndex !== -1) state.accounts.splice(duplicateAccountIndex, 1)

      state.accounts.push(account)
    },

    SET_DEFAULT_ACCOUNT(state, { account }) {
      state.accounts.forEach((acc) => {
        if (acc.id === account.id) acc.isDefault = true
        else acc.isDefault = false
      })
    },

    SET_CHALLENGE_SERVER(state, { challenge, server }) {
      state.challenge = challenge
      state.server = server
    }
  },
  actions: {
    setChallengeAndServer(context, { challenge, server }) {
      context.commit('SET_CHALLENGE_SERVER', {
        challenge: challenge,
        server: server
      })
    },

    loadAccounts(context) {
      //no need to clear accounts as it will show the log in screen temporarily
      //can't find an easy way to wait for the db code below
      //context.commit("CLEAR_ACCOUNTS")

      let db = openSpeckleSettings()

      db.serialize(() => {
        db.each('SELECT * FROM Objects ORDER BY hash ASC', function (_, row) {
          context.commit('ADD_ACCOUNT', { account: JSON.parse(row.content) })
        })
      })

      db.close()
    }
  }
}
