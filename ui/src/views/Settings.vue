<template>
  <v-container>
    <streams-list />

    <!-- testing sketchup bindings -->
    <v-container>
      <v-card>
        <v-card-title>Testing Sketchup Bindings</v-card-title>
        <v-card-text>
          <div class="d-flex align-center">
            Name:
            <v-text-field v-model="name" hint="Name" class="ml-3" />
          </div>
          <div class="d-flex align-center">
            Pokes:
            <v-text-field v-model.number="num_pokes" class="ml-3" />
          </div>
          <v-btn @click="poke">Poke {{ name }}!</v-btn>
        </v-card-text>
      </v-card>
    </v-container>
  </v-container>
</template>

<script>
/*global sketchup*/
import { bus } from '../main'
import userQuery from '../graphql/user.gql'

global.clickFromSettings = function (args) {
  bus.$emit('click-from-settings', args)
}

export default {
  name: 'Streams',
  computed: {},
  apollo: {
    user: {
      query: userQuery
    }
  },
  mounted() {
    bus.$on('click-from-main', (args) => console.log('triggered from main', args))
    bus.$on('click-from-settings', (args) => console.log('triggered from settings', args))
  },
  data() {
    return {
      name: 'Dim',
      num_pokes: 3
    }
  },
  methods: {
    poke() {
      sketchup.poke(this.name, this.num_pokes)
    }
  },
  components: {
    StreamsList: () => import('@/components/StreamsList')
  }
}
</script>
