<template>
  <v-container fluid class="px-5 btn-container">
    <v-autocomplete
        label="Mapper Method"
        :items="['Direct Shape']"
        density="compact"
    ></v-autocomplete>

    <v-autocomplete
        :items="availableCategories"
        label="Category"
        density="compact"
    ></v-autocomplete>

    <v-text-field v-model="name" label="Name"></v-text-field>

    <v-btn
        class="ma-2 pa-3"
    >
      <v-icon dark left>
        mdi-checkbox-marked-circle
      </v-icon>Apply Mappings
    </v-btn>
  </v-container>
</template>

<script>

import {bus} from "@/main";

global.entitySelected = function (mapperProperties) {
  bus.$emit('entities-selected', mapperProperties)
}

global.entitiesDeselected = function () {
  bus.$emit('entities-deselected')
}

export default {
  name: "Mapper",
  data() {
    return {
      entitySelected: false,
      selectedMethod: null,
      selectedCategory: null,
      selectedObjects: [],
      selectedObjectCount: null,
      name: "",
      enabledMethods: [],
      availableCategories: ["Floors", "Walls", "Windows"],
    }
  },
  methods:{
    clearInputs(){
      this.enabledMethods = []
      this.selectedObjects = []
      this.name = ""
    }
  },
  mounted() {
    bus.$on('entities-selected', async (mapperProperties) => {
      this.entitySelected = true
      const mapperProps = JSON.parse(mapperProperties)
      this.enabledMethods = mapperProps.enabledMethods
      this.selectedObjects = mapperProps.selectedObjects
      this.selectedObjectCount = this.selectedObjects.length
    })
    bus.$on('entities-deselected', async () => {
      this.entitySelected = false
      this.clearInputs()
    })
  }
}
</script>

<style scoped>
.btn-container{
  justify-content: center;
  display: flex;
  flex-wrap: wrap;
}
</style>