<template>
  <div style="display: inline-block">
    <v-menu v-if="loggedIn" offset-y open-on-hover>
      <template #activator="{ on, attrs }">
        <v-avatar
          v-if="userById"
          class="ma-1"
          color="grey lighten-3"
          :size="size"
          v-bind="attrs"
          v-on="on"
        >
          <v-img v-if="avatar" :src="avatar" />
          <v-img v-else :src="`https://robohash.org/` + id + `.png?size=40x40`" />
        </v-avatar>
        <v-avatar v-else class="ma-1" :size="size" v-bind="attrs" v-on="on">
          <v-img contain src="/logo.svg" />
        </v-avatar>
      </template>
      <v-card v-if="userById" style="width: 200px" :to="isSelf ? '/profile' : '/profile/' + id">
        <v-card-text v-if="!$apollo.loading" class="text-center">
          <v-avatar class="my-4" color="grey lighten-3" :size="40">
            <v-img v-if="avatar" :src="avatar" />
            <v-img v-else :src="`https://robohash.org/` + id + `.png?size=40x40`" />
          </v-avatar>
          <div>
            <b>{{ userById.name }}</b>
          </div>
          <div class="caption">
            {{ userById.company }}
            <br />
            {{ userById.bio ? 'Bio: ' + userById.bio : '' }}
          </div>
        </v-card-text>
      </v-card>
      <v-card v-else>
        <v-card-text class="text-xs">
          <b>Speckle Ghost</b>
          <br />
          This user no longer exists.
        </v-card-text>
      </v-card>
    </v-menu>
    <v-avatar v-else class="ma-1" color="grey lighten-3" :size="size">
      <v-img v-if="avatar" :src="avatar" />
      <v-img v-else :src="`https://robohash.org/` + id + `.png?size=40x40`" />
    </v-avatar>
  </div>
</template>
<script>
import userByIdQuery from '../graphql/userById.gql'

export default {
  props: {
    avatar: { type: String, default: null },
    name: { type: String, default: null },
    size: {
      type: Number,
      default: 42
    },
    id: {
      type: String,
      default: null
    }
  },
  computed: {
    isSelf() {
      return this.id === localStorage.getItem('uuid')
    },
    loggedIn() {
      return localStorage.getItem('SpeckleSketchup.AuthToken') !== null
    }
  },
  apollo: {
    userById: {
      query: userByIdQuery,
      variables() {
        return {
          id: this.id
        }
      },
      skip() {
        return !this.loggedIn
      },

      update: (data) => {
        return data.user
      }
    }
  }
}
</script>
