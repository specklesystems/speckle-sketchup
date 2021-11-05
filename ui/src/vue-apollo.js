import Vue from 'vue'
import VueApollo from 'vue-apollo'
import { setContext } from 'apollo-link-context'
import { createApolloClient, restartWebsockets } from 'vue-cli-plugin-apollo/graphql-client'

// Install the vue plugin
Vue.use(VueApollo)

const AUTH_TOKEN = `SpeckleSketchup.AuthToken`

if (process.env.NODE_ENV === 'development') {
  localStorage.setItem(AUTH_TOKEN, process.env.VUE_APP_DEV_TOKEN)
  localStorage.setItem('serverUrl', process.env.VUE_APP_DEFAULT_SERVER)
}

const authLink = setContext((_, { headers }) => {
  // get the authentication token from local storage if it exists
  const token = localStorage.getItem(AUTH_TOKEN)
  // Return the headers to the context so httpLink can read them
  return {
    headers: {
      ...headers,
      Authorization: token ? `Bearer ${token}` : ''
    }
  }
})

// Config
const defaultOptions = {
  // You can use `https` for secure connection (recommended in production)
  httpEndpoint: () => {
    return (
      (localStorage.getItem('serverUrl').includes('http')
        ? localStorage.getItem('serverUrl')
        : 'https://speckle.xyz') + '/graphql'
    )
  },

  // You can use `wss` for secure connection (recommended in production)
  // Use `null` to disable subscriptions
  wsEndpoint: (
    (localStorage.getItem('serverUrl').includes('http')
      ? localStorage.getItem('serverUrl')
      : 'https://speckle.xyz') + '/graphql'
  ).replace('http', 'ws'),

  // LocalStorage token
  tokenName: AUTH_TOKEN,
  // Enable Automatic Query persisting with Apollo Engine
  persisting: false,
  // Use websockets for everything (no HTTP)
  // You need to pass a `wsEndpoint` for this to work
  websocketsOnly: false,
  // Is being rendered on the server?
  ssr: false,

  // Override default apollo link
  // note: don't override httpLink here, specify httpLink options in the
  // httpLinkOptions property of defaultOptions.
  link: authLink

  // Override default cache
  // cache: new InMemoryCache(),

  // Override the way the Authorization header is set
  // getAuth: (tokenName) => ...

  // Additional ApolloClient options
  // apollo: { ... }

  // Client local data (see apollo-link-state)
  // clientState: { resolvers: { ... }, defaults: { ... } }
}

// Call this in the Vue app file
export function createProvider(options = {}) {
  // Create apollo client
  const { apolloClient, wsClient } = createApolloClient({
    ...defaultOptions,
    ...options
  })

  // Override connection params
  wsClient.connectionParams = () => {
    const token = localStorage.getItem(AUTH_TOKEN)
    return {
      headers: {
        Authorization: token ? `Bearer ${token}` : ''
      }
    }
  }

  apolloClient.wsClient = wsClient

  // Create vue apollo provider
  const apolloProvider = new VueApollo({
    defaultClient: apolloClient,
    defaultOptions: {
      $query: {
        // fetchPolicy: 'cache-and-network',
      }
    },
    errorHandler(error) {
      // eslint-disable-next-line no-console
      console.log(
        '%cError',
        'background: red; color: white; padding: 2px 4px; border-radius: 3px; font-weight: bold;',
        error.message
      )
    }
  })

  return apolloProvider
}

// Manually call this when user log in
export async function onLogin(apolloClient) {
  if (apolloClient.wsClient) restartWebsockets(apolloClient.wsClient)
}

// Manually call this when user log out
export async function onLogout(apolloClient) {
  if (typeof localStorage !== 'undefined') {
    localStorage.removeItem(AUTH_TOKEN)
  }

  if (apolloClient.wsClient) restartWebsockets(apolloClient.wsClient)
}
